import Foundation

public protocol KeyValueStore {
    func set(_ value: String, forKey key: String)
    func get(_ key: String) -> String?
}
public final class DefaultsStore: KeyValueStore {
    public init() {}
    public func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    public func get(_ key: String) -> String? { UserDefaults.standard.string(forKey: key) }
}
