import Foundation

public extension Timer {
    /// Stores the timer. A non-repeating timer (`timeInterval == 0`) leaves the bag
    /// when it is no longer valid, which is after it fires on a run loop or after
    /// `invalidate`. A repeating timer stays until `cancel()`, `reset()`, or `remove`.
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        nonisolated(unsafe) let timer = self
        let watch = TimerValidityWatch()
        guard let id = bag.insert({
            watch.stop()
            timer.invalidate()
        }) else {
            return nil
        }

        guard timer.timeInterval == 0 else { return id }

        watch.task = Task { [weak bag] in
            while !Task.isCancelled {
                if !timer.isValid {
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
    var task: Task<Void, Never>?

    func stop() {
        task?.cancel()
        task = nil
    }
}
