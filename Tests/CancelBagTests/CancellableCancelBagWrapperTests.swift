import Testing
@testable import CancelBag

struct CancellableCancelBagWrapperTests {
    @Test("Storing new work on a CancellableCancelBag cancels the previous entry")
    func storeReplacesPreviousWork() {
        let storedBag = CancellableCancelBag()
        let bag = storedBag.wrappedValue
        let firstTask = makeLongRunningTask()
        let secondTask = makeLongRunningTask()

        firstTask.store(bag)
        secondTask.store(bag)

        #expect(firstTask.isCancelled)
        #expect(!secondTask.isCancelled)
        #expect(bag.count == 1)
    }

    @Test("Assigning a different CancelBag adopts it and cancels the previous one")
    func assignmentAdoptsTheNewBag() {
        var storedBag = CancellableCancelBag()
        let previousBag = storedBag.wrappedValue
        let previousTask = makeLongRunningTask()
        previousTask.store(previousBag)

        let adoptedBag = CancelBag(replacesOnStore: true)
        let adoptedTask = makeLongRunningTask()
        adoptedTask.store(adoptedBag)

        storedBag.wrappedValue = adoptedBag

        #expect(previousTask.isCancelled)
        #expect(!adoptedTask.isCancelled)
        #expect(storedBag.wrappedValue === adoptedBag)
        #expect(adoptedBag.count == 1)
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
