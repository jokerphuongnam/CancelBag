/// Holds one `store` / `insert` ID (`Int` or `Int?`) on a `CancelBag`.
/// Reassigning removes and cancels the previous ID. `nil` clears the slot
/// without calling `bag.cancel()`.
@propertyWrapper
public struct CancelBagStored {
    private let bag: CancelBag
    private var storedID: Int?

    public var wrappedValue: Int? {
        get { storedID }
        set {
            guard storedID != newValue else { return }
            if let previousID = storedID {
                bag.remove(previousID)
            }
            storedID = newValue
        }
    }

    public init(bag: CancelBag) {
        self.bag = bag
    }

    public init(wrappedValue: Int?, bag: CancelBag) {
        self.bag = bag
        storedID = wrappedValue
    }
}
