// Services/Profile/UI/ProfileReferralsViewController.swift

import UIKit
import HonistDesignSystem
 import HonistModels
import HonistUIComponents
import HonistKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext

/// Screen showing user's referrals list and summary metrics.
public final class ProfileReferralsViewController: HonistBaseViewController {
    
    private var referrals: [ReferralDTO]
    private let rootView = ProfileReferralsView()
    
    // MARK: - Init
    
    /// - Parameter referrals: optional initial list of referrals to display.
    public init(context: AccountContext, referrals: [ReferralDTO] = []) {
        self.referrals = referrals
         super.init(
             context: context,
             title: "My Referrals",
             hidesBackButton: false
         )
     }

     required init(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    
    // MARK: - DisplayNode
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode(viewBlock: { [weak self] in
            let view = UIView()
            view.backgroundColor = self?.presentationData.theme.list.plainBackgroundColor ?? .systemBackground
            return view
        })
        
        self.displayNodeDidLoad()
    }
    
    // MARK: - Lifecycle
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        attachRootView(rootView)
        bindActions()
        configureInitialData()
    }
    
    // MARK: - Bind
    
    private func bindActions() {
        rootView.onInviteTapped = { [weak self] in
            self?.presentInviteShare()
        }
        
        rootView.onCopyCodeTapped = { [weak self] in
            self?.copyReferralCodeToClipboard()
        }
    }
    
    // MARK: - Configure
    
    private func configureInitialData() {
        // User & referral code
        let user = AuthAppServices.shared.authLogic.currentUser
        let code = user?.referralCode ?? ""
        rootView.configureReferralCode(code)
        
        // Metrics
        let friendsCount = referrals.count
        let totalRewards = referrals.reduce(0) { $0 + $1.rewardGem }
        rootView.configureMetrics(
            friendsCount: friendsCount,
            totalRewards: totalRewards
        )
        
        // List
        rootView.configureReferrals(referrals)
    }
    
    // MARK: - Actions
    
    /// Presents iOS native share sheet with referral message.
    private func presentInviteShare() {
        let user = AuthAppServices.shared.authLogic.currentUser
        let code = user?.referralCode ?? ""
        
        let message: String
        if code.isEmpty {
            message = "Join me on Honist Ai and get extra rewards!"
        } else {
            message = """
            I'm using Honist Ai for smart AI chats and tools.
            Use my referral code \(code) when you join to get bonus gems!
            """
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        // iPad / large screens popover
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
            pop.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    /// Copies referral code to clipboard.
    private func copyReferralCodeToClipboard() {
        let user = AuthAppServices.shared.authLogic.currentUser
        guard let code = user?.referralCode, !code.isEmpty else {
            showSimpleAlert(title: "No Code", message: "Referral code is not available yet.")
            return
        }
        
        UIPasteboard.general.string = code
        showSimpleAlert(title: "Copied", message: "Your referral code has been copied.")
    }
    
    public func updateReferrals(_ newReferrals: [ReferralDTO]) {
        self.referrals = newReferrals
        // Reconfigure metrics and list
        let friendsCount = newReferrals.count
        let totalRewards = newReferrals.reduce(0) { $0 + $1.rewardGem }
        rootView.configureMetrics(friendsCount: friendsCount, totalRewards: totalRewards)
        rootView.configureReferrals(newReferrals)
    }
    
    // MARK: - Helpers
    
    private func showSimpleAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

