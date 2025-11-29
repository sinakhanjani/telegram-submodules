import UIKit
import HonistKit
import HonistDesignSystem
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

open class HonistBaseViewController: ViewController {
    
    public let context: AccountContext
    public private(set) var presentationData: PresentationData
    
    private var presentationDataDisposable: Disposable?
    private var rootTopConstraint: NSLayoutConstraint?
    
    // Horizontal constraints for rootView
    private var rootLeadingConstraint: NSLayoutConstraint?
    private var rootTrailingConstraint: NSLayoutConstraint?
    
    // Instead of UILabel/UIView, we use a custom Node
    private var gemNode: HonistGemBadgeNode?
    
    // MARK: - Init
    
    public init(
        context: AccountContext,
        title: String,
        hidesBackButton: Bool = false
    ) {
        self.context = context
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.presentationData = presentationData
        
        let navBarData = NavigationBarPresentationData(
            presentationData: presentationData
        )
        
        super.init(navigationBarPresentationData: navBarData)
        
        // Setup Honist navigation (title + gems)
        self.setupHonistNavigation(title: title)
        self.navigationItem.hidesBackButton = hidesBackButton
        
        // Status bar style
        self.statusBar.statusBarStyle = presentationData
            .theme.rootController.statusBarStyle.style
        
        // Listen for theme / language changes
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] newData in
            guard let self else { return }
            let oldTheme = self.presentationData.theme
            let oldStrings = self.presentationData.strings
            self.presentationData = newData
            
            if oldTheme !== newData.theme || oldStrings !== newData.strings {
                self.updateThemeAndStrings()
            }
        }).strict()
    }
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    // MARK: - DisplayNode setup
    
    open override func loadDisplayNode() {
        self.displayNode = ASDisplayNode(viewBlock: { [weak self] in
            let view = UIView()
            if let theme = self?.presentationData.theme {
                view.backgroundColor = theme.rootController.navigationBar.blurredBackgroundColor
            }
            return view
        })
        
        self.displayNodeDidLoad()
    }
     
    public func updateBaseUI() {
        if let user = AuthAppServices.shared.authLogic.currentUser {
            self.updateGemCount(user.currentGemBalance)
        }
    }
    
    // MARK: - Root view helper
    
    /// Child view controllers use this to attach their rootView.
    /// It adds the view to container, sets constraints, and keeps top & horizontal constraints.
    public func attachRootView(_ view: UIView) {
        let containerView = self.displayNode.view
        
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        
        let top = view.topAnchor.constraint(equalTo: containerView.topAnchor)
        self.rootTopConstraint = top
        
        let leading = view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0)
        let trailing = view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
        self.rootLeadingConstraint = leading
        self.rootTrailingConstraint = trailing
        
        NSLayoutConstraint.activate([
            top,
            leading,
            trailing,
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Layout (sync with navigation bar height & horizontal insets)
    
    open override func containerLayoutUpdated(
        _ layout: ContainerViewLayout,
        transition: ContainedViewLayoutTransition
    ) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        // Vertical: push rootView below Telegram navigation bar
        let navBarHeight: CGFloat = self.cleanNavigationHeight
        self.rootTopConstraint?.constant = navBarHeight
        
        // Horizontal: in landscape add 64pt inset on each side, in portrait 0
        let isLandscape = layout.size.width > layout.size.height
        let horizontalInset: CGFloat = isLandscape ? 128.0 : 0.0
        
        self.rootLeadingConstraint?.constant = horizontalInset
        self.rootTrailingConstraint?.constant = -horizontalInset
    }
    
    // MARK: - Honist Navigation (title + gems)
    
    /// Sets up the navigation bar with title and gem badge
    public func setupHonistNavigation(title: String) {
        self.title = title
        
        let textColor = DS.Color.text
        let bgColor = UIColor.systemGray4.withAlphaComponent(1.0)
        
        let gemNode = HonistGemBadgeNode(
            textColor: textColor,
            backgroundColor: bgColor
        )
        gemNode.style.height = ASDimension(unit: .points, value: 30.0)
        
        self.gemNode = gemNode
        
        // Default behavior: show only gem badge as right bar button
        self.setRightBarButtonsToGemOnly()
    }
    
    /// Builds a UIBarButtonItem for the gem badge using customDisplayNode
    public func makeGemBarButtonItem() -> UIBarButtonItem? {
        guard let gemNode = self.gemNode else { return nil }
        guard let item = UIBarButtonItem(customDisplayNode: gemNode) else {
            return nil
        }
        item.target = self
        item.action = #selector(didTapRightBarButton)
        return item
    }
    
    /// Sets navigation right bar button to show only the gem badge.
    public func setRightBarButtonsToGemOnly() {
        guard let item = makeGemBarButtonItem() else { return }
        self.navigationItem.rightBarButtonItems = [item]
    }
    
    /// Sets navigation right bar button to two items: [compose, gem].
    /// Both items are backed by ASDisplayNode to work with Telegram's custom nav bar.
    /// - Parameters:
    ///   - composeTarget: Target for compose button.
    ///   - composeAction: Selector called when compose button is tapped.
    public func setRightBarButtonsToGemAndCompose(
        composeTarget: Any?,
        composeAction: Selector
    ) {
        guard let gemItem = makeGemBarButtonItem() else { return }
        
        // Compose node wrapping a UIButton
        let composeNode = ASDisplayNode {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
            button.tintColor = DS.Color.text

            if let target = composeTarget {
                button.addTarget(target, action: composeAction, for: .touchUpInside)
            }

            return button
        }
        composeNode.style.preferredSize = CGSize(width: 30.0, height: 30.0)
        
        guard let composeItem = UIBarButtonItem(customDisplayNode: composeNode) else {
            // Fallback: keep only gem if compose cannot be created
            self.navigationItem.rightBarButtonItems = [gemItem]
            return
        }
        
        // Order: [compose, gem] → compose rightmost, gem سمت چپش
        self.navigationItem.rightBarButtonItems = [composeItem, gemItem]
    }
    
    /// Updates the gem count displayed in the navigation bar
    public func updateGemCount(_ value: Int) {
        self.gemNode?.setGems(value)
    }
    
    // MARK: - Theme updating
    
    /// Syncs theme and string updates for navigation elements and gem badge
    open func updateThemeAndStrings() {
        self.statusBar.statusBarStyle = self.presentationData
            .theme.rootController.statusBarStyle.style
        
        self.navigationBar?.updatePresentationData(
            NavigationBarPresentationData(presentationData: self.presentationData)
        )
        
        let textColor = DS.Color.text
        let bgColor = UIColor.systemGray4.withAlphaComponent(1.0)
        
        self.gemNode?.updateColors(
            textColor: textColor,
            backgroundColor: bgColor
        )
    }
    
    // MARK: - Actions
    
    /// Called when the right navigation bar item is tapped.
    /// Subclasses can override this to provide custom behavior.
    @objc open func didTapRightBarButton() {
        // Default implementation: open payments paywall
        PaymentsPaywallFeature.present(
            over: self,
            onConfirmSelection: { [weak self] _ in
                if let user = AuthAppServices.shared.authLogic.currentUser {
                    self?.updateGemCount(user.currentGemBalance)
                }
            }
        )
    }
}
