# Changelog

`1.0.0` is the stable release. Tags `0.x.x-beta` mark earlier commits that can be checked out. They are not the stable release.

The first public `v1.0.0` tag pointed at the initial commit, then at the fix commit. It now points at this stable tree. If a resolved checkout still has an older `v1.0.0`, delete the tag locally and fetch it again.

## 1.0.0 — 2026-10-16

Stable release. MIT license, this changelog, an iOS Simulator build on CI, and a README section for each system extension: `Task`, Combine `Cancellable`, `DispatchWorkItem`, `Timer`, `URLSessionWebSocketTask`, and `NotificationCenter`.

## 0.3.0-beta — 2026-10-15

- `forget(id)` drops an entry and leaves the work running. `remove(id)` drops it and cancels it.
- A finished `Task` or `DispatchWorkItem` leaves the bag without being cancelled.
- A non-repeating timer leaves after its fire date. A repeating timer stays until the bag cancels it.
- A WebSocket task leaves when it completes or is cancelled.
- Cancellation closures are `@Sendable`.

## 0.2.0-beta — 2026-10-14

Split from the fix that used to sit in one commit.

- `store` on a closed bag returns `nil`.
- Entry ids increase instead of being random.
- Child-bag cancellation runs after the hierarchy lock.
- Assigning `@CancellableCancelBag` adopts the new bag.
- Notification observers are registered through `NotificationCenter` so the token stays inside the bag.
- Swift 6, MIT license, and `swift test` on CI.

## 0.1.0-beta — 2026-10-13

First commit. A bag of cancellables with Swift Testing.
