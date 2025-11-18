import UIKit
import StoreKit
import HonistModels
import HonistDesignSystem
import HonistService_Auth
import HonistFoundation

// MARK: - View controller

/// Controller that owns ProAccessPaywallView and handles selection + purchase logic.
/// 
@available(iOS 15.0, *)
public final class ProAccessPaywallViewController: UIViewController {
    
    // MARK: - Public API
    
    /// Optional callback when user confirms a product selection.
    public var onConfirmSelection: ((ProductDTO) -> Void)?
    
    // MARK: - Dependencies
    
    private let logic: PaymentsLogic
    private let storeKitClient = StoreKitClient()
    
    // MARK: - UI
    
    private let rootView = ProAccessPaywallView()
    
    // MARK: - State
    
    private var products: [ProductDTO] = []
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
            print("🔹 Pro paywall selected product:", product.id, product.title)
        }
        
        rootView.onPrimaryButtonTapped = { [weak self] product in
            guard let self else { return }
            
            // Use tapped product if provided, otherwise current selection.
            let chosen = product ?? self.selectedProduct
            guard let finalProduct = chosen else { return }
            
            // Require logged-in user.
            guard let _ = AuthAppServices.shared.authLogic.currentUser else {
                self.showInfoAlert(
                    title: "Login Required",
                    message: "You need to be logged in to continue with the purchase."
                )
                return
            }

            // Run async purchase flow (create-order → StoreKit purchase → verify → finish).
            Task { @MainActor in
                await self.handlePurchaseFlow(for: finalProduct)
            }
        }
        
        rootView.onCloseTapped = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Main purchase flow for Pro Access
    
    @MainActor
    private func resetPurchaseLoadingState() {
        isProcessingPurchase = false
        rootView.setPrimaryButtonLoading(false)
    }
        
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
    
    // MARK: - Data
    
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
                
                // We only care about unlimited subscription products for Pro paywall.
                let allUnlimitedProducts = payload.items.filter { $0.type == "subscription_unlimited" }
                
                await MainActor.run {
                    self.products = allUnlimitedProducts
                    self.selectedProduct = allUnlimitedProducts.first
                    
                    self.rootView.configure(
                        products: allUnlimitedProducts,
                        selectedProductId: self.selectedProduct?.id
                    )
                }
            } catch {
                print("❌ Pro paywall products fetch failed: \(error.localizedDescription)")
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
