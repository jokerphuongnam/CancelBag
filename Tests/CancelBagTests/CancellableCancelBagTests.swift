import Combine
import Testing
@testable import CancelBag

struct CancellableCancelBagTests {
    @Test("A Combine cancellable is cancelled with its bag")
    func cancellableIsCancelled() {
        let bag = CancelBag()
        var isCancelled = false
        let cancellable = AnyCancellable {
            isCancelled = true
        }

        cancellable.store(bag)
        bag.reset()

        #expect(isCancelled)
    }

    @Test("Storing a new cancellable accumulates with the previous one")
    func storeAccumulatesCancellables() {
        let bag = CancelBag()
        var firstIsCancelled = false
        var secondIsCancelled = false
        let firstCancellable = AnyCancellable {
            firstIsCancelled = true
        }
        let secondCancellable = AnyCancellable {
            secondIsCancelled = true
        }

        firstCancellable.store(bag)
        secondCancellable.store(bag)

        #expect(!firstIsCancelled)
        #expect(!secondIsCancelled)
        #expect(bag.count == 2)
    }
}
