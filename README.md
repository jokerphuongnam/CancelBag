# CancelBag

A small bag of cancellables for Apple platforms. `store` keeps work until `cancel()`, `reset()`, or the bag is released. `@CancellableCancelBag` keeps one slot: a new `store` cancels the previous entry.

```swift
.package(url: "https://github.com/jokerphuongnam/CancelBag", from: "1.0.0")
```

```swift
import CancelBag

let bag = CancelBag()
task.store(bag)
socket.store(bag)
bag.cancel()
```

Extensions cover `Cancellable`, `Task`, `DispatchWorkItem`, `Timer`, `NotificationCenter` observers, `URLSessionWebSocketTask`, and nesting one bag inside another.

Tests use Swift Testing. Run them with `swift test`.
