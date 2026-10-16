import Combine
import Foundation

/// Holds cancellables. By default `store` / `insert` accumulate.
/// With `replacesOnStore: true` (used by `@CancellableCancelBag`), each new
/// `store` cancels current entries first, then keeps the new one.
/// `reset()` cancels without closing; `cancel()` closes so later `store` is rejected.
public final class CancelBag: Cancellable, @unchecked Sendable {
    private struct Entry {
        let hook: CancellationHook
        let childBag: CancelBag?
    }

    private static let hierarchyLock = NSLock()

    private let lock = NSLock()
    /// When true, each `store` / `insert` cancels current entries first.
    public let replacesOnStore: Bool
    private var entries: [Int: Entry] = [:]
    private var nextID = 0
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

    /// `CancelBag { stop() }` runs `onCancel` when the bag is cancelled or released.
    public convenience init(_ onCancel: @escaping @Sendable () -> Void) {
        self.init()
        insert(onCancel)
    }

    /// `nil` when the bag is already closed. The closure is cancelled and not stored.
    @discardableResult
    func insert(_ cancellation: @escaping @Sendable () -> Void) -> Int? {
        let hook = CancellationHook(cancellation)
        var previous: [CancellationHook] = []
        let id = lock.withLock { () -> Int? in
            guard !isCancelled else { return nil }
            let id = makeUniqueID()
            if replacesOnStore {
                previous = entries.values.map(\.hook)
                entries.removeAll()
            }
            entries[id] = Entry(hook: hook, childBag: nil)
            return id
        }

        previous.forEach { $0.cancel() }
        guard let id else {
            hook.cancel()
            return nil
        }
        return id
    }

    /// Drops the entry and runs its cancellation.
    @discardableResult
    public func remove(_ id: Int) -> Bool {
        let hook = lock.withLock {
            entries.removeValue(forKey: id)?.hook
        }

        hook?.cancel()
        return hook != nil
    }

    /// Drops the entry and leaves the work running.
    @discardableResult
    public func forget(_ id: Int) -> Bool {
        let hook = lock.withLock {
            entries.removeValue(forKey: id)?.hook
        }

        hook?.disarm()
        return hook != nil
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
        let outcome = Self.hierarchyLock.withLock { () -> ChildInsert in
            guard childBag !== self else { return .rejected }
            guard !childBag.containsDescendant(self) else { return .rejected }

            let hook = CancellationHook {
                childBag.cancel()
            }
            var previous: [CancellationHook] = []
            let id = lock.withLock { () -> Int? in
                guard !isCancelled else { return nil }
                let id = makeUniqueID()
                if replacesOnStore {
                    previous = entries.values.map(\.hook)
                    entries.removeAll()
                }
                entries[id] = Entry(hook: hook, childBag: childBag)
                return id
            }
            guard let id else {
                return .closed(orphan: hook, previous: previous)
            }
            return .stored(id: id, previous: previous)
        }

        switch outcome {
        case .rejected:
            return nil
        case .stored(let id, let previous):
            previous.forEach { $0.cancel() }
            return id
        case .closed(let orphan, let previous):
            previous.forEach { $0.cancel() }
            orphan.cancel()
            return nil
        }
    }

    private func cancelEntries(shouldClose: Bool) {
        let storedCancellables = lock.withLock {
            if shouldClose {
                isCancelled = true
            }
            let storedCancellables = entries.values.map(\.hook)
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
        nextID += 1
        return nextID
    }
}

private enum ChildInsert {
    case rejected
    case stored(id: Int, previous: [CancellationHook])
    case closed(orphan: CancellationHook, previous: [CancellationHook])
}

/// Runs its action at most once. `disarm` drops the action without running it.
private final class CancellationHook: @unchecked Sendable {
    private let lock = NSLock()
    private var action: (@Sendable () -> Void)?

    init(_ action: @escaping @Sendable () -> Void) {
        self.action = action
    }

    func cancel() {
        let action = lock.withLock { () -> (@Sendable () -> Void)? in
            let action = self.action
            self.action = nil
            return action
        }
        action?()
    }

    func disarm() {
        lock.withLock {
            action = nil
        }
    }
}
