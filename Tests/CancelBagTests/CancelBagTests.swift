import Testing
@testable import CancelBag

struct CancelBagTests {
    @Test("Releasing a ViewModel automatically cancels its stored work")
    func viewModelLifecycleCancelsStoredTask() {
        var viewModel: CancelBagViewModelStub? = CancelBagViewModelStub()
        weak let releasedViewModel = viewModel
        let task = makeLongRunningTask()

        viewModel?.store(task)
        viewModel = nil

        #expect(releasedViewModel == nil)
        #expect(task.isCancelled)
    }

    @Test("A stored task can be removed and cancelled by its random ID")
    func taskCanBeRemovedByID() {
        let bag = CancelBag()
        let task = makeLongRunningTask()

        let id = task.store(bag)

        #expect(id != nil)
        #expect((id ?? 0) > 0)
        #expect(bag.count == 1)
        #expect(bag.remove(id!))
        #expect(task.isCancelled)
        #expect(bag.isEmpty)
    }

    @Test("Cancelling a parent bag cascades through multiple child bags")
    func nestedBagsCancelTheirTasks() {
        let parentBag = CancelBag()
        let firstChildBag = CancelBag()
        let secondChildBag = CancelBag()
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(firstChildBag)
        secondTask.store(secondChildBag)
        firstChildBag.store(parentBag)
        secondChildBag.store(parentBag)

        #expect(parentBag.count == 2)
        #expect(!firstTask.isCancelled)
        #expect(!secondTask.isCancelled)

        parentBag.cancel()

        #expect(parentBag.isEmpty)
        #expect(firstChildBag.isEmpty)
        #expect(secondChildBag.isEmpty)
        #expect(firstTask.isCancelled)
        #expect(secondTask.isCancelled)
    }

    @Test("A parent can remove one child bag without cancelling other children")
    func childBagCanBeRemovedByID() {
        let parentBag = CancelBag()
        let removedChildBag = CancelBag()
        let remainingChildBag = CancelBag()
        let removedTask = makeLongRunningTask()
        let remainingTask = makeLongRunningTask()

        removedTask.store(removedChildBag)
        remainingTask.store(remainingChildBag)
        let removedChildID = removedChildBag.store(parentBag)
        remainingChildBag.store(parentBag)

        guard let removedChildID else {
            Issue.record("The child bag should be stored")
            return
        }
        #expect(parentBag.remove(removedChildID))
        #expect(removedTask.isCancelled)
        #expect(!remainingTask.isCancelled)
        #expect(parentBag.count == 1)
    }

    @Test("Storing new work accumulates without cancelling previous work")
    func storeAccumulatesWork() {
        let bag = CancelBag()
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(bag)
        secondTask.store(bag)

        #expect(!firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 2)
    }

    @Test("Storing new work on a parent keeps a nested child bag")
    func storeOnParentKeepsNestedChild() {
        let parentBag = CancelBag()
        let childBag = CancelBag()
        let childTask = makeLongRunningTask()
        let parentTask = makeLongRunningTask()

        childTask.store(childBag)
        childBag.store(parentBag)
        parentTask.store(parentBag)

        #expect(!childTask.isCancelled)
        #expect(!parentTask.isCancelled)
        #expect(parentBag.count == 2)
    }

    @Test("A completed task removes itself from the bag")
    func completedTaskIsRemoved() async {
        let bag = CancelBag()
        let task = Task { 42 }

        task.store(bag)
        #expect(await task.value == 42)

        let deadline = ContinuousClock().now.advanced(by: .seconds(2))
        while !bag.isEmpty, ContinuousClock().now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(bag.isEmpty)
    }

    @Test("A child bag cannot create an indirect retain cycle")
    func nestedBagCycleIsRejected() {
        let firstBag = CancelBag()
        let secondBag = CancelBag()

        #expect(firstBag.store(secondBag) != nil)
        #expect(secondBag.store(firstBag) == nil)
        #expect(firstBag.store(firstBag) == nil)
    }

    @Test("reset cancels stored work while keeping the bag reusable")
    func resetKeepsBagReusable() {
        let bag = CancelBag()
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(bag)
        bag.reset()
        secondTask.store(bag)

        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 1)
    }

    @Test("A terminally cancelled bag immediately cancels new work")
    func cancelledBagRejectsNewWork() {
        let bag = CancelBag()
        let task = makeLongRunningTask()

        bag.cancel()
        let id = task.store(bag)

        #expect(id == nil)
        #expect(task.isCancelled)
        #expect(bag.isEmpty)
    }

    @Test("forget drops an entry and leaves the task running")
    func forgetLeavesWorkRunning() {
        let bag = CancelBag()
        let task = makeLongRunningTask()
        let id = task.store(bag)

        #expect(bag.forget(id!))
        #expect(!task.isCancelled)
        #expect(bag.isEmpty)
    }
}

private final class CancelBagViewModelStub {
    let cancelBag = CancelBag()

    func store(_ task: Task<Void, Never>) {
        task.store(cancelBag)
    }
}

private func makeLongRunningTask() -> Task<Void, Never> {
    Task {
        try? await Task.sleep(for: .seconds(60))
    }
}
