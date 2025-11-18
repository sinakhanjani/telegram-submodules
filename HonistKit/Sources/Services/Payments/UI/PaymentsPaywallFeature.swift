import UIKit
import HonistRouting
import HonistModels

/// Feature entry point for the Payments Paywall modal.
public enum PaymentsPaywallFeature: HonistRoutable {

    // MARK: - Default empty constructor (protocol requirement)

    /// Required by HonistRoutable — creates a paywall with a default PaymentsLogic.
    public static func makeRoot() -> UIViewController {
        return makeRoot(selectedProductId: nil)
    }

    // MARK: - Custom factory with injected initial selected product id

    /// Creates and returns the paywall modal.
    /// - Parameters:
    ///   - selectedProductId: Optional preselected product to highlight when UI loads.
    ///   - logic: Optional custom PaymentsLogic instance (default shared/new).
    public static func makeRoot(
        selectedProductId: String?,
        logic: PaymentsLogic = PaymentsLogic()
    ) -> UIViewController {

        if #available(iOS 15.0, *) {
            let vc = PaymentsPaywallViewController(logic: logic)
            // Setting preselected product is done after fetching products inside ViewController.
            return vc
        } else {
            // Fallback for iOS versions earlier than 15.0
            let fallback = UIViewController()
            fallback.view.backgroundColor = .systemBackground
            return fallback
        }
    }

    // MARK: - Present helper (recommended for modals)

    /// Presents the paywall as modal from any controller.
    /// - Parameters:
    ///   - presenter: The controller that will present the modal.
    ///   - selectedProductId: Optional preselected product.
    ///   - animated: Whether to animate the modal.
    ///   - completion: Completion callback.
    ///   - onConfirmSelection: Called when user taps confirm button with selected product.
    public static func present(
        over presenter: UIViewController,
        selectedProductId: String? = nil,
        logic: PaymentsLogic = PaymentsLogic(),
        animated: Bool = true,
        completion: (() -> Void)? = nil,
        onConfirmSelection: ((ProductDTO) -> Void)? = nil
    ) {
        if #available(iOS 15.0, *) {
            let vc = PaymentsPaywallViewController(logic: logic)

            // Pass selection callback
            vc.onConfirmSelection = onConfirmSelection

            // Presentation style: your paywall looks like a fullscreen fade modal
            vc.modalPresentationStyle = .automatic
            vc.modalTransitionStyle = .coverVertical

            presenter.present(vc, animated: animated, completion: completion)
        } else {
            // Fallback presentation for iOS versions earlier than 15.0
            let fallback = UIViewController()
            fallback.view.backgroundColor = .systemBackground
            presenter.present(fallback, animated: animated, completion: completion)
        }
    }
}
