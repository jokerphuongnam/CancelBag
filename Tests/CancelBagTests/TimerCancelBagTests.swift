import Foundation
import Testing
@testable import CancelBag

struct TimerCancelBagTests {
    @Test("A timer is invalidated with its bag")
    func timerIsInvalidated() {
        let bag = CancelBag()
        let timer = Timer(timeInterval: 60, repeats: false) { _ in }

        timer.store(bag)
        bag.reset()

        #expect(!timer.isValid)
    }

    @Test("Storing a new timer accumulates with the previous one")
    func storeAccumulatesTimers() {
        let bag = CancelBag()
        let firstTimer = Timer(timeInterval: 60, repeats: false) { _ in }
        let secondTimer = Timer(timeInterval: 60, repeats: false) { _ in }

        firstTimer.store(bag)
        secondTimer.store(bag)

        #expect(firstTimer.isValid)
        #expect(secondTimer.isValid)
        #expect(bag.count == 2)
    }
}
