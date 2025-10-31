import Foundation

/// Actor to serialize refresh attempts and share the result among concurrent callers.
actor RefreshCoordinator {
    private var isRefreshing = false
    private var waitingContinuations: [CheckedContinuation<Bool, Error>] = []

    /// Ensures only one refresh runs; other callers await the result.
    func run(_ block: @escaping () async throws -> Bool) async throws -> Bool {
        if isRefreshing {
            return try await withCheckedThrowingContinuation { cont in
                waitingContinuations.append(cont)
            }
        }
        isRefreshing = true
        do {
            let result = try await block()
            completeAll(result: .success(result))
            return result
        } catch {
            completeAll(result: .failure(error))
            throw error
        }
    }

    private func completeAll(result: Result<Bool, Error>) {
        isRefreshing = false
        let continuations = waitingContinuations
        waitingContinuations.removeAll()
        for cont in continuations {
            switch result {
            case .success(let ok): cont.resume(returning: ok)
            case .failure(let err): cont.resume(throwing: err)
            }
        }
    }
}
