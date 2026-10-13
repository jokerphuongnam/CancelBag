import Testing
@testable import CancelBag

struct CancelBagStoredTests {
    @Test("Reassigning a stored Int cancels the previous ID")
    func reassignmentCancelsPreviousIntID() {
        let bag = CancelBag()
        var storedID = CancelBagStored(bag: bag)
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        storedID.wrappedValue = firstTask.store(bag)
        storedID.wrappedValue = secondTask.store(bag)

        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 1)
        #expect(storedID.wrappedValue != nil)
    }

    @Test("Reassigning a stored Int? cancels the previous nested bag")
    func reassignmentCancelsPreviousOptionalID() {
        let parentBag = CancelBag()
        var storedID = CancelBagStored(bag: parentBag)
        let firstChildBag = CancelBag()
        let secondChildBag = CancelBag()
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(firstChildBag)
        secondTask.store(secondChildBag)
        storedID.wrappedValue = firstChildBag.store(parentBag)
        storedID.wrappedValue = secondChildBag.store(parentBag)

        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(parentBag.count == 1)
        #expect(storedID.wrappedValue != nil)
    }

    @Test("Setting nil clears the slot without cancelling the bag")
    func nilClearsSlotWithoutCancellingBag() {
        let bag = CancelBag()
        var storedID = CancelBagStored(bag: bag)
        let firstTask = makeLongRunningTask()
        let siblingTask = makeLongRunningTask()
        let replacementTask = makeLongRunningTask()

        siblingTask.store(bag)
        storedID.wrappedValue = firstTask.store(bag)
        storedID.wrappedValue = nil

        #expect(firstTask.isCancelled)
        #expect(!siblingTask.isCancelled)
        #expect(storedID.wrappedValue == nil)
        #expect(bag.count == 1)

        storedID.wrappedValue = replacementTask.store(bag)

        #expect(!replacementTask.isCancelled)
        #expect(!siblingTask.isCancelled)
        #expect(bag.count == 2)
    }

    @Test("Reassigning one slot leaves other bag entries in place")
    func wrapperReplaceDoesNotResetBag() {
        let bag = CancelBag()
        var storedID = CancelBagStored(bag: bag)
        let siblingTask = makeLongRunningTask()
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        siblingTask.store(bag)
        storedID.wrappedValue = firstTask.store(bag)
        storedID.wrappedValue = secondTask.store(bag)

        #expect(!siblingTask.isCancelled)
        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 2)
    }
}

private func makeLongRunningTask() -> Task<Void, Never> {
    Task {
        try? await Task.sleep(for: .seconds(60))
    }
}
