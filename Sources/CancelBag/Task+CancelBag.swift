public extension Task {
    @discardableResult
    func store(_ bag: CancelBag) -> Int? {
        guard let id = bag.insert({
            self.cancel()
        }) else {
            return nil
        }

        Task<Void, Never> { [weak bag] in
            _ = await self.result
            bag?.remove(id)
        }
        return id
    }
}
