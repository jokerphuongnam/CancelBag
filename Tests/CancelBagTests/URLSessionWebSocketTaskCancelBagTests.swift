import Foundation
import Testing
@testable import CancelBag

struct URLSessionWebSocketTaskCancelBagTests {
    @Test("A WebSocket task is cancelled with its bag")
    func webSocketTaskIsCancelled() async throws {
        let bag = CancelBag()
        let url = try #require(URL(string: "wss://example.invalid"))
        let task = URLSession.shared.webSocketTask(
            with: url
        )

        task.store(bag)
        bag.reset()

        #expect(bag.isEmpty)

        for _ in 0..<20 {
            guard task.state != .canceling && task.state != .completed else { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(task.state == .canceling || task.state == .completed)
    }

    @Test("Storing a new WebSocket task accumulates with the previous one")
    func storeAccumulatesWebSocketTasks() async throws {
        let bag = CancelBag()
        let url = try #require(URL(string: "wss://example.invalid"))
        let firstTask = URLSession.shared.webSocketTask(with: url)
        let secondTask = URLSession.shared.webSocketTask(with: url)

        firstTask.store(bag)
        secondTask.store(bag)

        #expect(bag.count == 2)
        #expect(firstTask.state != .canceling && firstTask.state != .completed)
        #expect(secondTask.state != .canceling && secondTask.state != .completed)
    }
}
