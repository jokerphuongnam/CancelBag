import Foundation

public extension URLSessionWebSocketTask {
    /// Stores the socket and removes it when the task completes or is cancelled.
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        nonisolated(unsafe) let task = self
        let watch = WebSocketStateWatch()
        guard let id = bag.insert({
            watch.invalidate()
            task.cancel(with: .goingAway, reason: nil)
        }) else {
            return nil
        }

        watch.observation = task.observe(\.state, options: [.new]) { [weak bag] task, _ in
            guard task.state == .completed || task.state == .canceling else { return }
            watch.invalidate()
            bag?.forget(id)
        }
        return id
    }
}

private final class WebSocketStateWatch: @unchecked Sendable {
    var observation: NSKeyValueObservation?

    func invalidate() {
        observation?.invalidate()
        observation = nil
    }
}
