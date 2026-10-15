import Combine

public extension Cancellable {
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        nonisolated(unsafe) let cancellable = self
        return bag.insert {
            cancellable.cancel()
        }
    }
}

public extension CancelBag {
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        bag.insert(self)
    }
}
