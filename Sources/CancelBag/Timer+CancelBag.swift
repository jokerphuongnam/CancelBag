import Foundation

public extension Timer {
    /// Stores the timer. A non-repeating timer (`timeInterval == 0`) leaves the bag
    /// after its fire date. A repeating timer stays until `cancel()`, `reset()`, or `remove`.
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        nonisolated(unsafe) let timer = self
        guard let id = bag.insert({
            timer.invalidate()
        }) else {
            return nil
        }

        if timer.timeInterval == 0 {
            let delay = max(timer.fireDate.timeIntervalSinceNow, 0)
            Task { [weak bag] in
                try? await Task.sleep(for: .seconds(delay))
                bag?.forget(id)
            }
        }
        return id
    }
}
