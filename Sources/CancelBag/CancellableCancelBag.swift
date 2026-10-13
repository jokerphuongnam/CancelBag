/// One-slot `CancelBag` (Element `CancellableTask`-style for bags).
/// Each `store` / `insert` cancels current work, then keeps the new entry.
///
/// Leak / lifetime:
/// - `CancelBag` is a class → `===` / `!==` is exact instance identity.
/// - Owned bag is released with the wrapper; `CancelBag.deinit` always `cancel()`s.
/// - Assigning a different bag renews **in place** via `reset()` (no second alloc
///   for the kept slot) and **`cancel()`s the discarded value** so it cannot keep
///   running work after we refuse to adopt it.
/// - Prefer `wrappedValue.reset()` when clearing without an assignment.
@propertyWrapper
public struct CancellableCancelBag {
    private var bag: CancelBag

    public var wrappedValue: CancelBag {
        get { bag }
        set {
            // Same instance: nothing to do (avoids reset on no-op assign).
            guard bag !== newValue else { return }
            // Keep the existing slot alive and reusable.
            bag.reset()
            // Not adopting `newValue` — tear it down so discarded work cannot leak.
            newValue.cancel()
        }
    }

    public init(wrappedValue: CancelBag = CancelBag(replacesOnStore: true)) {
        // Reuse caller bag when it is already one-slot; otherwise replace.
        bag = wrappedValue.replacesOnStore ? wrappedValue : CancelBag(replacesOnStore: true)
        if bag !== wrappedValue {
            wrappedValue.cancel()
        }
    }
}
