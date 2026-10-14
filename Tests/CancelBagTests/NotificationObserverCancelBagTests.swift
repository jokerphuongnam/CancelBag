import Foundation
import Testing
@testable import CancelBag

struct NotificationObserverCancelBagTests {
    @Test("A notification observer is removed with its bag")
    func observerIsRemoved() {
        let center = NotificationCenter()
        let name = Notification.Name("CancelBagTests.notification")
        let bag = CancelBag()
        let received = Count()
        center.addObserver(forName: name, object: nil, queue: nil, bag: bag) { _ in
            received.value += 1
        }
        center.post(name: name, object: nil)
        bag.reset()
        center.post(name: name, object: nil)

        #expect(received.value == 1)
    }

    @Test("Storing a new observer accumulates with the previous one")
    func storeAccumulatesObservers() {
        let center = NotificationCenter()
        let name = Notification.Name("CancelBagTests.notification.accumulate")
        let bag = CancelBag()
        let first = Count()
        let second = Count()
        center.addObserver(forName: name, object: nil, queue: nil, bag: bag) { _ in
            first.value += 1
        }
        center.addObserver(forName: name, object: nil, queue: nil, bag: bag) { _ in
            second.value += 1
        }
        center.post(name: name, object: nil)

        #expect(first.value == 1)
        #expect(second.value == 1)
        #expect(bag.count == 2)
    }
}

private final class Count: @unchecked Sendable {
    var value = 0
}
