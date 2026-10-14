import Foundation

public extension NotificationCenter {
    /// Registers a block observer and removes that token when the bag cancels it.
    /// The token never leaves this method, so a view controller cannot be passed
    /// to `removeObserver` by mistake.
    @discardableResult
    func addObserver(
        forName name: Notification.Name?,
        object obj: Any? = nil,
        queue: OperationQueue? = nil,
        bag: CancelBag,
        using block: @escaping @Sendable (Notification) -> Void
    ) -> Int? {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return bag.insert {
            self.removeObserver(token)
        }
    }
}
