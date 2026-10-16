import Foundation

public extension Timer {
    /// Stores the timer. A non-repeating timer (`timeInterval == 0`) leaves the bag
    /// when it is no longer valid, which is after it fires on a run loop or after
    /// `invalidate`. A repeating timer stays until `cancel()`, `reset()`, or `remove`.
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        let watch = TimerValidityWatch(self)
        guard let id = bag.insert({
            watch.invalidate()
        }) else {
            return nil
        }

        guard watch.firesOnce else { return id }

        watch.task = Task { [weak bag] in
            while !Task.isCancelled {
                if !watch.isValid {
                    bag?.forget(id)
                    return
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
        return id
    }
}

private final class TimerValidityWatch: @unchecked Sendable {
    private let lock = NSLock()
    private var timer: Timer?
    var task: Task<Void, Never>?

    init(_ timer: Timer) {
        self.timer = timer
    }

    var firesOnce: Bool {
        lock.withLock { timer?.timeInterval == 0 }
    }

    var isValid: Bool {
        lock.withLock { timer?.isValid ?? false }
    }

    func invalidate() {
        let timer = lock.withLock { () -> Timer? in
            task?.cancel()
            task = nil
            let timer = self.timer
            self.timer = nil
            return timer
        }
        timer?.invalidate()
    }
}
