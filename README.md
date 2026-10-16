# CancelBag

A small bag of cancellables for Apple platforms. One `CancelBag` keeps tasks, timers, sockets, notifications, and Combine subscriptions until you cancel them or the bag is released.

License: [MIT](LICENSE).

`1.0.0` is the stable release. There is no newer stable tag. Earlier milestones are `0.x.x-beta`. See [CHANGELOG.md](CHANGELOG.md).

```swift
.package(url: "https://github.com/jokerphuongnam/CancelBag", from: "1.0.0")
```

```swift
import CancelBag
```

Requires iOS 17, macOS 14, watchOS 10, tvOS 17, or visionOS 1.

## Bag

`store` keeps work. It returns an `Int` id, or `nil` when the bag is already closed. A closed bag also cancels the work you just tried to store.

| Call | Effect |
| --- | --- |
| `cancel()` | Cancel everything. Later `store` returns `nil`. |
| `reset()` | Cancel everything. The bag still accepts `store`. |
| `remove(id)` | Drop that entry and cancel it. |
| `forget(id)` | Drop that entry and leave the work running. |
| Release the bag | Same as `cancel()`. |

`count` and `isEmpty` report how many entries are stored. `@CancellableCancelBag` is a one-slot bag: each new `store` cancels the previous entry.

```swift
let bag = CancelBag()
let task = Task {
    try await Task.sleep(for: .seconds(30))
}
let id = task.store(bag)
bag.remove(id!)   // cancels the task
bag.forget(id!)   // would have left it running
```

Assigning another bag to `@CancellableCancelBag` adopts that instance and cancels the previous one. Assigning the same instance does nothing. `reset()` clears the current bag without replacing it.

```swift
struct ScreenModel {
    @CancellableCancelBag var bag
}
```

`@CancelBagStored` remembers one id. Setting a new id calls `remove` on the old one, which cancels that entry. Setting `nil` clears the slot and does not cancel the rest of the bag.

```swift
let bag = CancelBag()
@CancelBagStored(bag: bag) var slot: Int?
slot = task.store(bag)
slot = nil
```

A child bag can be stored in a parent. Cancelling the parent cancels the child. A bag cannot store itself or one of its ancestors.

## Extensions

Each `store` below returns `Int?`. `nil` means the bag was already closed.

### Task

```swift
let task = Task { await load() }
task.store(bag)
```

When the task finishes, it leaves the bag and is not cancelled again. `Task` is `Sendable`, so the cancellation closure is `@Sendable`.

### Combine `Cancellable`

```swift
import Combine

let cancellable = AnyCancellable { /* stop */ }
cancellable.store(bag)
```

`AnyCancellable`, a publisher's `AnyCancellable`, or another `CancelBag` used as a `Cancellable` all cancel through this method. To nest bags and share cancellation, call `child.store(parent)` instead. That path rejects a cycle.

### DispatchWorkItem

```swift
let work = DispatchWorkItem { refresh() }
queue.async(execute: work)
work.store(bag)
```

`notify` removes the item after it runs or after it is cancelled. A finished item is not cancelled a second time. `DispatchWorkItem` is not `Sendable`. The closure captures it as `nonisolated(unsafe)`.

### Timer

```swift
let once = Timer(fire: Date().addingTimeInterval(1), interval: 0, repeats: false) { _ in }
once.store(bag)

let repeating = Timer(timeInterval: 5, repeats: true) { _ in }
RunLoop.main.add(repeating, forMode: .common)
repeating.store(bag)
```

A non-repeating timer has `timeInterval == 0`. It leaves the bag after its fire date, without a second `invalidate` from `forget`. A repeating timer stays until `cancel()`, `reset()`, or `remove`. `Timer` is not `Sendable`. The closure captures it as `nonisolated(unsafe)`.

### URLSessionWebSocketTask

```swift
let socket = URLSession.shared.webSocketTask(with: url)
socket.store(bag)
socket.resume()
```

The bag cancels the socket with `URLSessionWebSocketTask.CloseCode.goingAway`. When the task reaches `.completed` or `.canceling`, it leaves the bag. The task is not `Sendable`. State is observed with KVO, and the token is kept inside the stored entry.

### NotificationCenter

```swift
NotificationCenter.default.addObserver(
    forName: .NSCalendarDayChanged,
    object: nil,
    queue: nil,
    bag: bag
) { note in
    handle(note)
}
```

This is the only notification API. The observer token never leaves the method, so `removeObserver` cannot be pointed at a view controller by mistake. The block is `@Sendable`. The center and the token are captured as `nonisolated(unsafe)`.

## What is not included

There is no `URLSessionDataTask` or `AsyncStream` helper. Store those by cancelling them inside `bag.insert` from your own code, or wrap the work in a `Task` and `store` that task.
