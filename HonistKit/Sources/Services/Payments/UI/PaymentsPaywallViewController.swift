import UIKit
import StoreKit
import HonistModels
import HonistDesignSystem
import HonistService_Auth
import HonistFoundation

/// Modal view controller that hosts the payments paywall.
/// - It owns `PaymentsLogic` to fetch products.
/// - It keeps track of the currently selected product.
/// - It will call backend (create-order + verify) when user confirms.
@available(iOS 15.0, *)
public final class PaymentsPaywallViewController: UIViewController {
    
    // MARK: - Public API
    
    /// Called when user taps the primary button with a selected product.
    /// (Optional) You can still use this from outside if you want.
    public var onConfirmSelection: ((ProductDTO) -> Void)?
    
    // MARK: - Dependencies
    
    private let logic: PaymentsLogic
    private let storeKitClient = StoreKitClient()
    
    // MARK: - UI
    
    private let rootView = PaymentsPaywallView()
    
    // MARK: - State
    
    private var subscriptionProducts: [ProductDTO] = []
    private var oneTimeProducts: [ProductDTO] = []
    
    /// Currently selected product from either list.
    public private(set) var selectedProduct: ProductDTO?
    
    private var isProcessingPurchase = false
    
    // MARK: - Init
    
    public init(logic: PaymentsLogic = PaymentsLogic()) {
        self.logic = logic
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func loadView() {
        view = rootView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCallbacks()
        fetchAndDisplayProducts()
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        rootView.onProductSelected = { [weak self] product in
            self?.selectedProduct = product
            print("Selected product:", product.id, product.title)
        }
        
        rootView.onPrimaryButtonTapped = { [weak self] product in
            guard let self else { return }
            
            // Use tapped product if provided, otherwise current selection.
            guard let selected = product ?? self.selectedProduct else {
                return
            }
                        
            // Require logged-in user.
            guard let _ = AuthAppServices.shared.authLogic.currentUser else {
                self.showInfoAlert(
                    title: "Login Required",
                    message: "You need to be logged in to continue with the purchase."
                )
                return
            }
            
            guard !self.isProcessingPurchase else { return }
            
            self.isProcessingPurchase = true
            self.rootView.setPrimaryButtonLoading(true)
            
            // Run async flow (create-order → StoreKit purchase → verify → finish).
            Task { @MainActor in
                await self.handlePurchaseFlow(for: selected)
            }
        }
        
        rootView.onCloseTapped = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    @MainActor
    private func resetPurchaseLoadingState() {
        isProcessingPurchase = false
        rootView.setPrimaryButtonLoading(false)
    }
    
    // MARK: - Main purchase flow (step 1 + step 2)
    
    @available(iOS 15.0, *)
    @MainActor
    private func handlePurchaseFlow(for product: ProductDTO) async {
        do {
            guard let user = AuthAppServices.shared.authLogic.currentUser else {
                resetPurchaseLoadingState()
                return
            }
            guard let appAccountUUID = UUID(uuidString: user.id) else {
                resetPurchaseLoadingState()
                return
            }
            
            let alreadyActive = await storeKitClient.hasActiveStoreKitSubscription(for: product.appleProductId)
            if alreadyActive && product.type != "one_time_pack" {
                showInfoAlert(
                    title: "Subscription Active",
                    message: "You already have an active subscription for this plan."
                )
                resetPurchaseLoadingState()
                return
            }
            
            let orderResponse = try await logic.createOrder(appleProductId: product.appleProductId)
            let orderId = orderResponse.id
            
            let skProducts = try await storeKitClient.fetchProducts(identifiers: [product.appleProductId])
            guard let skProduct = skProducts.first else {
                showInfoAlert(
                    title: "Product Not Found",
                    message: "Unable to find this product in App Store."
                )
                resetPurchaseLoadingState()
                return
            }
            
            let purchaseResult = try await storeKitClient.purchase(skProduct, appAccountToken: appAccountUUID)
            let transaction   = purchaseResult.transaction
            let jws           = purchaseResult.jwsRepresentation
            
            let productId     = transaction.productID
            let transactionId = String(transaction.id)
            let originalTxnId = String(transaction.originalID)
            let purchaseDate  = transaction.purchaseDate
            let expiresDate   = transaction.expirationDate
            
            let environmentString: String
            if #available(iOS 16.0, *) {
                switch transaction.environment {
                case .sandbox:
                    environmentString = "Sandbox"
                case .production:
                    environmentString = "Production"
                default:
                    environmentString = "Sandbox"
                }
            } else {
                environmentString = "Sandbox"
            }
            
            let verifyReqBody = AppleVerifyRequest(
                orderId: orderId,
                productId: productId,
                transactionId: transactionId,
                originalTxnId: originalTxnId,
                purchaseDate: purchaseDate,
                expiresDate: expiresDate,
                signedTransactionJws: jws,
                signedRenewalJws: nil,
                receiptData: nil,
                environment: environmentString
            )
            
            try await logic.verifyAppleOrder(verifyReqBody)
            
            _ = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
            
            await transaction.finish()
            print("AppleVerifyRequest: ", verifyReqBody)
            
            dismiss(animated: true) {
                self.isProcessingPurchase = false
                self.onConfirmSelection?(product)
            }
            
        } catch StoreKitClientError.purchaseCancelled {
            print("Purchase cancelled by user.")
            resetPurchaseLoadingState()
        } catch {
            let msg = (error as? HonistError)?.errorDescription ?? error.localizedDescription
            showInfoAlert(
                title: "Payment Failed",
                message: msg
            )
            resetPurchaseLoadingState()
        }
    }
    
    // MARK: - Data loading
    
    private func fetchAndDisplayProducts() {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                let payload = try await logic.fetchProducts(
                    status: "active",
                    search: nil,
                    type: nil,
                    period: nil,
                    page: 1,
                    limit: 100
                )
                
                let all = payload.items
                
                let subs = all.filter { $0.type == "subscription_quota" }
                let packs = all.filter { $0.type == "one_time_pack" }
                
                await MainActor.run {
                    self.subscriptionProducts = subs
                    self.oneTimeProducts = packs
                    
                    // Default selection: first subscription, or first pack if no subscription.
                    if let first = subs.first ?? packs.first {
                        self.selectedProduct = first
                    }
                    
                    self.rootView.configure(
                        subscriptionProducts: self.subscriptionProducts,
                        oneTimeProducts: self.oneTimeProducts,
                        selectedProductId: self.selectedProduct?.id
                    )
                }
            } catch {
                print("❌ Failed to fetch products: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil)
        )
        present(alert, animated: true, completion: nil)
    }
}
