import Testing
@testable import CancelBag

struct CancellableCancelBagWrapperTests {
    @Test("Storing new work on a CancellableCancelBag cancels the previous entry")
    func storeReplacesPreviousWork() {
        var storedBag = CancellableCancelBag()
        let bag = storedBag.wrappedValue
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(bag)
        secondTask.store(bag)

        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 1)
    }

    @Test("Assigning a different CancelBag resets the kept bag and cancels the discarded one")
    func assignmentResetsInPlaceAndCancelsDiscarded() {
        var storedBag = CancellableCancelBag()
        let keptBag = storedBag.wrappedValue
        let keptTask = makeLongRunningTask()
        keptTask.store(keptBag)

        let discardedBag = CancelBag(replacesOnStore: true)
        let discardedTask = makeLongRunningTask()
        discardedTask.store(discardedBag)

        storedBag.wrappedValue = discardedBag

        #expect(keptTask.isCancelled)
        #expect(discardedTask.isCancelled)
        #expect(storedBag.wrappedValue === keptBag)
        #expect(keptBag.isEmpty)
    }

    @Test("Assigning the same CancelBag instance is a no-op")
    func sameInstanceIsIgnored() {
        var storedBag = CancellableCancelBag()
        let bag = storedBag.wrappedValue
        let task = makeLongRunningTask()
        task.store(bag)

        storedBag.wrappedValue = bag

        #expect(!task.isCancelled)
        #expect(bag.count == 1)
    }

    @Test("Dropping the wrapper cancels stored work")
    func releasingWrapperCancelsStoredWork() {
        var storedBag: CancellableCancelBag? = CancellableCancelBag()
        let task = makeLongRunningTask()
        task.store(storedBag!.wrappedValue)

        storedBag = nil

        #expect(task.isCancelled)
    }
}

private func makeLongRunningTask() -> Task<Void, Never> {
    Task {
        try? await Task.sleep(for: .seconds(60))
    }
}
