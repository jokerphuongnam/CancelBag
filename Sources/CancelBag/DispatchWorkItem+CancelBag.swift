import Foundation

public extension DispatchWorkItem {
    @discardableResult
    func store(_ bag: CancelBag) -> Int {
        bag.insert {
            self.cancel()
        }
    }
}
