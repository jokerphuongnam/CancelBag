import Foundation
import Testing
@testable import CancelBag

struct DispatchWorkItemCancelBagTests {
    @Test("A dispatch work item is cancelled with its bag")
    func workItemIsCancelled() {
        let bag = CancelBag()
        let workItem = DispatchWorkItem {}

        workItem.store(bag)
        bag.reset()

        #expect(workItem.isCancelled)
    }

    @Test("Storing a new work item accumulates with the previous one")
    func storeAccumulatesWorkItems() {
        let bag = CancelBag()
        let firstWorkItem = DispatchWorkItem {}
        let secondWorkItem = DispatchWorkItem {}

        firstWorkItem.store(bag)
        secondWorkItem.store(bag)

        #expect(!firstWorkItem.isCancelled)
        #expect(!secondWorkItem.isCancelled)
        #expect(bag.count == 2)
    }
}
