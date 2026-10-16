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

    @Test("A non-repeating timer leaves the bag when it becomes invalid")
    func nonRepeatingTimerLeavesTheBag() async {
        let bag = CancelBag()
        let timer = Timer(fire: Date().addingTimeInterval(60), interval: 0, repeats: false) { _ in }

        timer.store(bag)
        #expect(bag.count == 1)

        timer.invalidate()

        let deadline = ContinuousClock().now.advanced(by: .seconds(2))
        while !bag.isEmpty, ContinuousClock().now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(bag.isEmpty)
        #expect(!timer.isValid)
    }
}
