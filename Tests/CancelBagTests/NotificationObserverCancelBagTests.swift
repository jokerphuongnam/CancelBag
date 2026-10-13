import Foundation
import Testing
@testable import CancelBag

struct NotificationObserverCancelBagTests {
    @Test("A notification observer is removed with its bag")
    func observerIsRemoved() {
        let center = NotificationCenter()
        let name = Notification.Name("CancelBagTests.notification")
        let bag = CancelBag()
        var receivedNotificationCount = 0
        let observer = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            receivedNotificationCount += 1
        }

        observer.store(bag, center: center)
        center.post(name: name, object: nil)
        bag.reset()
        center.post(name: name, object: nil)

        #expect(receivedNotificationCount == 1)
    }

    @Test("Storing a new observer accumulates with the previous one")
    func storeAccumulatesObservers() {
        let center = NotificationCenter()
        let name = Notification.Name("CancelBagTests.notification.accumulate")
        let bag = CancelBag()
        var firstReceivedCount = 0
        var secondReceivedCount = 0
        let firstObserver = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            firstReceivedCount += 1
        }
        let secondObserver = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            secondReceivedCount += 1
        }

        firstObserver.store(bag, center: center)
        secondObserver.store(bag, center: center)
        center.post(name: name, object: nil)

        #expect(firstReceivedCount == 1)
        #expect(secondReceivedCount == 1)
        #expect(bag.count == 2)
    }
}
