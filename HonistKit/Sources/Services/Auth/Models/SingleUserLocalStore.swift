import Foundation

// MARK: - Errors
public enum SingleUserStoreError: Error, LocalizedError {
    case userNotFound
    case failedToLoad
    case failedToSave
    case failedToDelete
    case failedToEncode
    case failedToDecode

    public var errorDescription: String? {
        switch self {
        case .userNotFound: return "User not found."
        case .failedToLoad: return "Failed to load user from disk."
        case .failedToSave: return "Failed to save user to disk."
        case .failedToDelete: return "Failed to delete user from disk."
        case .failedToEncode: return "Failed to encode user JSON."
        case .failedToDecode: return "Failed to decode user JSON."
        }
    }
}

// MARK: - JSON Encoder/Decoder (ISO8601 Dates)
private let singleUserJSONEncoder: JSONEncoder = {
    let enc = JSONEncoder()
    if #available(iOS 15.0, macOS 12.0, *) {
        enc.dateEncodingStrategy = .iso8601
    } else {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        enc.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
    }
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    return enc
}()

private let singleUserJSONDecoder: JSONDecoder = {
    let dec = JSONDecoder()
    if #available(iOS 15.0, macOS 12.0, *) {
        dec.dateDecodingStrategy = .iso8601
    } else {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) {
                return date
            }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid ISO8601 date: \(str)"))
        }
    }
    return dec
}()

// MARK: - SingleUserLocalStore
/// A lightweight local store that persists exactly one UserDTO to disk.
/// - Persistence: JSON file in the app's Documents directory.
/// - Threading: Serialized via a private queue.
/// - API: CRUD for a single user (save, get, update, delete) in sync and async flavors.
public final class SingleUserLocalStore {
    public static let shared = SingleUserLocalStore()

    private let queue = DispatchQueue(label: "SingleUserLocalStore.queue", qos: .userInitiated)
    private let fileURL: URL

    /// Initialize with a custom directory/filename if needed.
    public init(directory: FileManager.SearchPathDirectory = .documentDirectory,
                fileName: String = "single_user.json") {
        let urls = FileManager.default.urls(for: directory, in: .userDomainMask)
        let base = urls.first ?? FileManager.default.temporaryDirectory
        self.fileURL = base.appendingPathComponent(fileName)
    }

    // MARK: - Internal helpers
    private func loadFromDisk() throws -> UserDTO {
        do {
            let data = try Data(contentsOf: fileURL)
            let user = try singleUserJSONDecoder.decode(UserDTO.self, from: data)
            return user
        } catch let err as DecodingError {
            print("DecodingError: \(err)")
            throw SingleUserStoreError.failedToDecode
        } catch {
            throw SingleUserStoreError.failedToLoad
        }
    }

    private func saveToDisk(_ user: UserDTO) throws {
        do {
            let data = try singleUserJSONEncoder.encode(user)
            try data.write(to: fileURL, options: [.atomic])
        } catch let err as EncodingError {
            print("EncodingError: \(err)")
            throw SingleUserStoreError.failedToEncode
        } catch {
            throw SingleUserStoreError.failedToSave
        }
    }

    private func deleteFromDisk() throws {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            } else {
                throw SingleUserStoreError.userNotFound
            }
        } catch {
            throw SingleUserStoreError.failedToDelete
        }
    }

    // MARK: - Synchronous CRUD
    /// Create/Replace: Save the single user to disk.
    public func save(user: UserDTO) throws {
        try queue.sync {
            try saveToDisk(user)
        }
    }

    /// Read: Load the single user from disk.
    public func get() throws -> UserDTO {
        try queue.sync {
            // If the file doesn't exist, surface userNotFound for clarity.
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw SingleUserStoreError.userNotFound
            }
            return try loadFromDisk()
        }
    }

    /// Update: Read, mutate, and re-save the user.
    public func update(mutate: (UserDTO) -> UserDTO) throws -> UserDTO {
        try queue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw SingleUserStoreError.userNotFound
            }
            let current = try loadFromDisk()
            let updated = mutate(current)
            try saveToDisk(updated)
            return updated
        }
    }

    /// Delete: Remove the persisted user from disk.
    public func delete() throws {
        try queue.sync {
            try deleteFromDisk()
        }
    }

    // MARK: - Async/Await CRUD
    public func saveAsync(user: UserDTO) async throws {
        // Encode outside the @Sendable closure to avoid capturing non-Sendable `UserDTO`.
        let data: Data
        do {
            data = try singleUserJSONEncoder.encode(user)
        } catch {
            throw SingleUserStoreError.failedToEncode
        }

        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    try data.write(to: self.fileURL, options: [.atomic])
                    cont.resume()
                } catch {
                    cont.resume(throwing: SingleUserStoreError.failedToSave)
                }
            }
        }
    }

    public func getAsync() async throws -> UserDTO {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
                        throw SingleUserStoreError.userNotFound
                    }
                    let user = try self.loadFromDisk()
                    cont.resume(returning: user)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    public func updateAsync(mutate: @escaping (UserDTO) -> UserDTO) async throws -> UserDTO {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
                        throw SingleUserStoreError.userNotFound
                    }
                    let current = try self.loadFromDisk()
                    let updated = mutate(current)
                    do {
                        let data = try singleUserJSONEncoder.encode(updated)
                        try data.write(to: self.fileURL, options: [.atomic])
                        cont.resume(returning: updated)
                    } catch let err as EncodingError {
                        print("EncodingError: \(err)")
                        cont.resume(throwing: SingleUserStoreError.failedToEncode)
                    } catch {
                        cont.resume(throwing: SingleUserStoreError.failedToSave)
                    }
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    public func deleteAsync() async throws {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    try self.deleteFromDisk()
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}


extension SingleUserLocalStore: @unchecked Sendable {}

