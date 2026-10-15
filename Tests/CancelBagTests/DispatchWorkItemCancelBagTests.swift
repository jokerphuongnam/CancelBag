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

    @Test("A finished work item leaves the bag without being cancelled")
    func finishedWorkItemLeavesTheBag() async {
        let bag = CancelBag()
        let workItem = DispatchWorkItem {}

        workItem.store(bag)
        workItem.perform()

        let deadline = ContinuousClock().now.advanced(by: .seconds(2))
        while !bag.isEmpty, ContinuousClock().now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(bag.isEmpty)
        #expect(!workItem.isCancelled)
    }
}
