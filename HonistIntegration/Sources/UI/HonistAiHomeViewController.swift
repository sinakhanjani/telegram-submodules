import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext
import HonistKit
import TelegramCore
import Postbox
import SwiftSignalKit

public final class HonistAiHomeViewController: HonistBaseViewController {
    
    private let rootView = HonistAiHomeView()
    
    // For avatar selection
    private let imagePicker = UIImagePickerController()
    private let profileLogic = ProfileLogic()
        
    private var refList: [ReferralDTO]?
    
    // MARK: - Init
    
    public init(context: AccountContext) {
        // We only pass these to the base class
        super.init(
            context: context,
            title: "Honist Ai",
            hidesBackButton: true    // This is the root tab, we don't want a back button
        )
        
        // Tab bar is configured only here (not in the base)
        self.tabBarItem.title = "HonistAi"
        let icon = UIImage.init(named: "tab_honistai_icon")!
        self.tabBarItem.image = icon
        self.tabBarItem.selectedImage = icon
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle / UI setup
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.attachRootView(rootView)
        
        bindActions()
        reloadUser()
        reloadAiHomeSections()
        imagePicker.delegate = self
    }
    
    // MARK: - Setup
    
    private func bindActions() {
        rootView.onUpgradeTapped = { [weak self] in
            // TODO: navigate to premium screen
            self?.showInfoAlert(title: "Premium", message: "Upgrade flow will be implemented later.")
        }
        
        rootView.onProfileMenuTapped = { [weak self] in
            guard let self = self else { return }
            let user = AuthAppServices.shared.authLogic.currentUser
            
            ProfileNameEditFeature.present(
                over: self,
                firstName: user?.firstName,
                lastName: user?.lastName,
                onUpdated: { [weak self] updatedUser in
                    guard let self = self else { return }
                    self.rootView.configure(with: updatedUser)
                    self.updateGemCount(updatedUser.currentGemBalance)
                }
            )
        }
        rootView.onAvatarTapped = { [weak self] in
            self?.presentAvatarSourcePicker()
        }
        
        rootView.onProfileMenuTapped = { [weak self] in
            guard let self = self else { return }
            let user = AuthAppServices.shared.authLogic.currentUser
            
            ProfileNameEditFeature.present(
                over: self,
                firstName: user?.firstName,
                lastName: user?.lastName,
                onUpdated: { [weak self] updatedUser in
                    guard let self = self else { return }
                    self.rootView.configure(with: updatedUser)
                    self.updateGemCount(updatedUser.currentGemBalance)
                }
            )
        }
        
        rootView.onGemsCardTapped = { [weak self] in
            // TODO: navigate to gems / wallet screen
            guard let self = self else { return }
            let vc = ProfileGemsViewController.init(context: self.context)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        rootView.onFriendsCardTapped = { [weak self] in
            guard let self = self else { return }
            let vc = ProfileReferralsViewController.init(context: self.context, referrals: self.refList ?? [])
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        rootView.onAssistantItemTapped = { [weak self] index in
            // TODO: navigate to specific featured bot
            self?.showInfoAlert(title: "Assistant", message: "Tapped item at index \(index).")
        }
        
        rootView.onAiChatTapped = { [weak self] in
            // TODO: navigate to AI chat screen
            self?.showInfoAlert(title: "AI Chat", message: "AI Chat screen will be implemented later.")
        }
        
        rootView.onFeaturedItemTapped = { [weak self] index in
            // TODO: navigate to specific featured bot
            self?.showInfoAlert(title: "Featured", message: "Tapped item at index \(index).")
        }
        
        rootView.onLoginTapped = { [weak self] in
            self?.confirmLogin()
        }
        
        rootView.onLogoutTapped = { [weak self] in
            self?.confirmLogout()
        }
    }
    
    // MARK: - User
    
    private func reloadUser() {
        let user = AuthAppServices.shared.authLogic.currentUser
        
        rootView.configure(with: user)
        
        if let user = user {
            updateGemCount(user.currentGemBalance)
            rootView.setAuthButtonMode(.logout)
        } else {
            updateGemCount(0)
            rootView.setAuthButtonMode(.login)
        }
    }
    
    // MARK: - Public API for configuring sections
    
    private func reloadAiHomeSections() {
        
        Task { @MainActor in
            do {
                let result = try? await profileLogic.fetchReferrals(page: 1, limit: 1000)
                let refList = result?.items
                let currentGemBalance = AuthAppServices.shared.authLogic.currentUser?.currentGemBalance ?? 0
                let sectionsData = HomeSectionsData(
                    assistants: [
                        .init(name: "General", imageName: "ic_assistant_general"),
                        .init(name: "Coding Expert", imageName: "ic_assistant_coding"),
                        .init(name: "Teacher", imageName: "ic_assistant_teacher"),
                        .init(name: "Tech Expert", imageName: "ic_assistant_tech"),
                        .init(name: "Fitness", imageName: "ic_assistant_fitness")
                    ],
                    metrics: (gems: "\(currentGemBalance)", friends: "\(refList?.count ?? 0)"),
                    featured: [
                        .init(title: "AlirezaGram",
                              subtitle: "Are you ready to give change upside of the town hall building my necessary do..."),
                        .init(title: "Face Swap Ai Bot",
                              subtitle: "Search stories by hashtag. Tapping hashtags in story captions lets you bro..."),
                        .init(title: "+5K People Have Won Bitcoin for...",
                              subtitle: "1 BTC for 555$? 1ETH for 7543$? 1 Sol for 333? Who are you?"),
                        .init(title: "Hyperlancer Ai",
                              subtitle: "Complete tasks, upload a video and share it to get reward of us my into the d...")
                    ]
                )
                
                self.refList = refList
                self.configureSections(with: sectionsData)
            } catch {
                print("ERR:", error)
            }
        }
    }
    
    public func configureSections(with data: HomeSectionsData) {
        rootView.assistantsSection.configure(assistants: data.assistants)
        rootView.metricsSection.configure(
            gemsValue: data.metrics.gems,
            friendsValue: data.metrics.friends
        )
        rootView.featuredSection.configure(items: data.featured)
    }
    
    // MARK: - Login flow
    
    private func confirmLogin() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to log in to your HonistAi profile?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Login", style: .default, handler: { [weak self] _ in
            guard let self = self else {return }
            let account = context.account
            let _ = (account.postbox.loadedPeerWithId(account.peerId)
             |> deliverOnMainQueue).start(next: { peer in
                if let user = peer as? TelegramUser {
                    self.performLogin(user)
                }
            })
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Logout flow
    
    private func confirmLogout() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout from Ai features?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] _ in
            self?.performLogout()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func performLogout() {
        Task { @MainActor in
            do {
                try await AuthAppServices.shared.authLogic.logoutCurrentSession()
                
                // Check user state again as requested
                let current = AuthAppServices.shared.authLogic.currentUser
                if current == nil {
                    self.reloadUser() // hides profile section
                }
            } catch {
                self.showInfoAlert(
                    title: "Error",
                    message: error.localizedDescription
                )
            }
        }
    }
    
    public func performLogin(_ user: TelegramUser) {
        // Adapt to HonistKit LoginRequest expected types
        let telegramIdString = String(user.id.id._internalGetInt64Value())
    //    let accessHashString: String? = user.accessHash.map { String($0.value) }
        let usernameString: String? = user.username
        // Prefer initializer with String parameters if available; otherwise fall back at compile time
        #if canImport(HonistKit)
            // Try the most common initializer signature: (telegramId: String, accessHash: String?, username: String?)
        let loginReqModel = LoginRequest(telegramId: telegramIdString, username: usernameString, isBot: user.botInfo != nil ? true : false)
        #else
        let loginReqModel = LoginRequest(telegramId: telegramIdString, username: usernameString, isBot: user.botInfo != nil ? true : false)
        #endif
        Task {
            do {
                _ = try await AuthAppServices.shared.authLogic.login(request: loginReqModel)
                // Call meWithAutoRefresh after a successful login
                _ = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
                self.reloadUser()
                
                #if DEBUG
                print("[Auth] Honist login + meWithAutoRefresh succeeded for telegramId=\(user.id.id)")
                #endif
            } catch {
                #if DEBUG
                print("[Auth] Honist login failed: \(error)")
                #endif
            }
        }
        
    #if DEBUG
        let fullName: String = {
            let first = user.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let last = user.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
            return combined.isEmpty ? "—" : combined
        }()
        
        let username = user.username ?? "—"
        let phone = user.phone ?? "—"
        let isBot = (user.botInfo != nil)
        let isVerified = user.flags.contains(.isVerified)
        let isPremium = user.flags.contains(.isPremium)
        
        print(
            """
            [Auth] User logged in
            ├─ id: \(user.id.id)
            ├─ phone: \(phone)
            ├─ username: @\(username)
            ├─ name: \(fullName)
            ├─ verified: \(isVerified)
            ├─ premium: \(isPremium)
            └─ bot: \(isBot)
            """
        )
    #endif
    }
    
    // MARK: - Avatar picking
    
    private func presentAvatarSourcePicker() {
        let alert = UIAlertController(
            title: "Profile Photo",
            message: "Choose a source",
            preferredStyle: .actionSheet
        )
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(source: .camera)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(source: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad / large screens
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
            pop.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        imagePicker.sourceType = source
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func uploadSelectedAvatar(_ image: UIImage) {
        // Convert to JPEG data
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            showInfoAlert(title: "Error", message: "Could not process selected image.")
            return
        }
        
        Task { @MainActor in
            do {
                let updatedUser = try await profileLogic.uploadPhoto(imageData: data)
                
                // Update AuthAppServices cache (if you want them in sync)
                // NOTE: if AuthLogic has a method to refresh / me, you can use that instead.
                // For now, we just refresh UI and rely on backend token logic as-is.
                self.rootView.configure(with: updatedUser)
            } catch {
                self.showInfoAlert(title: "Upload Failed", message: error.localizedDescription)
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
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


// MARK: - UIImagePickerControllerDelegate

extension HonistAiHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true, completion: nil)
        
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let image = image {
            self.rootView.setLocalAvatar(image)
            
            uploadSelectedAvatar(image)
        }
    }
}
