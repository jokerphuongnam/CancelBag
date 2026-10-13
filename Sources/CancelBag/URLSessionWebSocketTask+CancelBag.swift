import Foundation

public extension URLSessionWebSocketTask {
    @discardableResult
    func store(_ bag: CancelBag) -> Int {
        bag.insert {
            self.cancel(with: .goingAway, reason: nil)
        }
    }
}
