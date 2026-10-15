import Foundation

public extension DispatchWorkItem {
    /// Stores the item and removes it after `notify` runs, including when the item is cancelled.
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        nonisolated(unsafe) let workItem = self
        guard let id = bag.insert({
            workItem.cancel()
        }) else {
            return nil
        }

        workItem.notify(queue: .global(qos: .utility)) { [weak bag] in
            bag?.forget(id)
        }
        return id
    }
}
