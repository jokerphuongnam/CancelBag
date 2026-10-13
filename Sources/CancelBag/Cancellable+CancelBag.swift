import Combine

public extension Cancellable {
    @discardableResult
    func store(_ bag: CancelBag) -> Int {
        return bag.insert {
            self.cancel()
        }
    }
}

public extension CancelBag {
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        bag.insert(self)
    }
}
