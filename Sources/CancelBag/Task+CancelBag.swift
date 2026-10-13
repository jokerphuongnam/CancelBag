public extension Task {
    @discardableResult
    func store(_ bag: CancelBag) -> Int {
        let id = bag.insert {
            self.cancel()
        }

        Task<Void, Never> { [weak bag] in
            _ = await self.result
            bag?.remove(id)
        }
        return id
    }
}
