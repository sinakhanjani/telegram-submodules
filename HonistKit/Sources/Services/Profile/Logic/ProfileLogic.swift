import HonistStorage

public final class ProfileLogic {
    let store: KeyValueStore
    public init(store: KeyValueStore = DefaultsStore()) { self.store = store }
    public func cache(username: String) { store.set(username, forKey: "me.username") }
}