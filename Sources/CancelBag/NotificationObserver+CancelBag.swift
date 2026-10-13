import Foundation

public extension NSObjectProtocol {
    @discardableResult
    func store(
        _ bag: CancelBag,
        center: NotificationCenter = .default
    ) -> Int {
        bag.insert {
            center.removeObserver(self)
        }
    }
}
