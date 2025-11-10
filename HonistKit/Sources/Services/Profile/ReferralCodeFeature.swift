import UIKit
import HonistRouting

public enum ReferralCodeFeature: HonistRoutable {
    /// Factory method to get the popup controller
    public static func makeRoot() -> UIViewController {
        // Return the popup VC directly (no navigation controller wrapper)
        // because it already configures .overFullScreen & crossDissolve.
        let vc = ReferralCodeViewController()
        return vc
    }

    /// Helper to present from any controller (e.g., Telegram root)
    /// - Parameter presenter: current visible view controller
    public static func present(over presenter: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        // Present as an over-fullscreen popup with blur behind
        let modal = makeRoot()
        presenter.present(modal, animated: animated, completion: completion)
    }
}
