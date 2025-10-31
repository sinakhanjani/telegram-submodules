import Foundation
import UIKit

/// Observes app lifecycle to refresh tokens when the app comes to foreground
/// or when significant time changes occur.
final class AuthLifecycleObserver {
    private weak var authLogic: AuthLogic?

    init(authLogic: AuthLogic) {
        self.authLogic = authLogic
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(onTimeChange), name: UIApplication.significantTimeChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onForeground() {
        Task { [weak self] in
            try? await self?.authLogic?.ensureValidAccessTokenIfNeeded()
        }
    }

    @objc private func onTimeChange() {
        Task { [weak self] in
            try? await self?.authLogic?.ensureValidAccessTokenIfNeeded()
        }
    }
}
