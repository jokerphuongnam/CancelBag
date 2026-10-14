/// One-slot `CancelBag` (Element `CancellableTask`-style for bags).
/// Each `store` / `insert` cancels current work, then keeps the new entry.
///
/// Leak / lifetime:
/// - `CancelBag` is a class → `===` / `!==` is exact instance identity.
/// - Owned bag is released with the wrapper; `CancelBag.deinit` always `cancel()`s.
/// - Assigning a different bag adopts that instance and `cancel()`s the previous one.
/// - Assigning the same instance does nothing.
/// - Prefer `wrappedValue.reset()` when clearing the current bag without replacing it.
@propertyWrapper
public struct CancellableCancelBag {
    private var bag: CancelBag

    public var wrappedValue: CancelBag {
        get { bag }
        set {
            guard bag !== newValue else { return }
            let previous = bag
            bag = newValue
            previous.cancel()
        }
    }

    public init(wrappedValue: CancelBag = CancelBag(replacesOnStore: true)) {
        bag = wrappedValue
    }
}
