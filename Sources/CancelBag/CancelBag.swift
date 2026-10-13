import Combine
import Foundation

/// Holds cancellables. By default `store` / `insert` accumulate.
/// With `replacesOnStore: true` (used by `@CancellableCancelBag`), each new
/// `store` cancels current entries first, then keeps the new one.
/// `reset()` cancels without closing; `cancel()` closes so later `store` is rejected.
public final class CancelBag: Cancellable {
    private struct Entry {
        let cancellable: AnyCancellable
        let childBag: CancelBag?
    }

    private static let hierarchyLock = NSLock()

    private let lock = NSLock()
    /// When true, each `store` / `insert` cancels current entries first.
    public let replacesOnStore: Bool
    private var entries: [Int: Entry] = [:]
    private var isCancelled = false

    public var count: Int {
        lock.withLock {
            entries.count
        }
    }

    public var isEmpty: Bool {
        lock.withLock {
            entries.isEmpty
        }
    }

    public init(replacesOnStore: Bool = false) {
        self.replacesOnStore = replacesOnStore
    }

    @discardableResult
    func insert(_ cancellation: @escaping () -> Void) -> Int {
        let cancellable = AnyCancellable(cancellation)
        var previous: [AnyCancellable] = []
        let result = lock.withLock { () -> (id: Int, stored: Bool) in
            let id = makeUniqueID()
            guard !isCancelled else { return (id, false) }
            if replacesOnStore {
                previous = entries.values.map(\.cancellable)
                entries.removeAll()
            }
            entries[id] = Entry(cancellable: cancellable, childBag: nil)
            return (id, true)
        }

        previous.forEach { $0.cancel() }
        if !result.stored {
            cancellable.cancel()
        }
        return result.id
    }

    @discardableResult
    public func remove(_ id: Int) -> Bool {
        let cancellable = lock.withLock {
            entries.removeValue(forKey: id)?.cancellable
        }

        cancellable?.cancel()
        return cancellable != nil
    }

    public func reset() {
        cancelEntries(shouldClose: false)
    }

    public func cancel() {
        cancelEntries(shouldClose: true)
    }

    deinit {
        cancel()
    }

    @discardableResult
    func insert(_ childBag: CancelBag) -> Int? {
        Self.hierarchyLock.withLock {
            guard childBag !== self else { return nil }
            guard !childBag.containsDescendant(self) else { return nil }

            let cancellable = AnyCancellable {
                childBag.cancel()
            }
            var previous: [AnyCancellable] = []
            let result = lock.withLock { () -> (id: Int, stored: Bool) in
                guard !isCancelled else { return (0, false) }
                let id = makeUniqueID()
                if replacesOnStore {
                    previous = entries.values.map(\.cancellable)
                    entries.removeAll()
                }
                entries[id] = Entry(cancellable: cancellable, childBag: childBag)
                return (id, true)
            }

            previous.forEach { $0.cancel() }
            if !result.stored {
                cancellable.cancel()
                return nil
            }
            return result.id
        }
    }

    private func cancelEntries(shouldClose: Bool) {
        let storedCancellables = lock.withLock {
            if shouldClose {
                isCancelled = true
            }
            let storedCancellables = entries.values.map(\.cancellable)
            entries.removeAll()
            return storedCancellables
        }

        storedCancellables.forEach { $0.cancel() }
    }

    private func containsDescendant(_ target: CancelBag) -> Bool {
        var bagsToInspect = [self]
        var inspectedBags = Set<ObjectIdentifier>()

        while let bag = bagsToInspect.popLast() {
            if bag === target {
                return true
            }

            let identifier = ObjectIdentifier(bag)
            guard inspectedBags.insert(identifier).inserted else { continue }
            let childBags = bag.lock.withLock {
                bag.entries.values.compactMap(\.childBag)
            }
            bagsToInspect.append(contentsOf: childBags)
        }

        return false
    }

    private func makeUniqueID() -> Int {
        var id: Int

        repeat {
            id = Int.random(in: 1...Int.max)
        } while entries[id] != nil

        return id
    }
}
