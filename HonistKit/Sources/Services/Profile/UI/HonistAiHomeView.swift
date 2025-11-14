import UIKit
import HonistDesignSystem
import HonistFoundation
import HonistModels
import HonistUIComponents
import HonistService_Auth

public struct AssistantItem {
    let name: String
    let imageName: String
    
    public init(name: String, imageName: String) {
        self.name = name
        self.imageName = imageName
    }
}

public struct FeaturedItem {
    let title: String
    let subtitle: String
    
    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

public enum AuthButtonMode {
    case login
    case logout
}

/// Main root view for Honist Ai home screen.
public class HonistAiHomeView: UIView {
    
    // MARK: - Public action callbacks
    
    /// Called when AI Chat button is tapped.
    public var onAiChatTapped: (() -> Void)?
    
    /// Called when "Upgrade to premium" button is tapped.
    public var onUpgradeTapped: (() -> Void)?
    
    /// Called when user name area is tapped.
    public var onProfileNameTapped: (() -> Void)?
    
    /// Called when avatar image is tapped.
    public var onAvatarTapped: (() -> Void)?
    
    /// Called when vertical "..." menu in profile card is tapped.
    public var onProfileMenuTapped: (() -> Void)?
    
    /// Called when Gems metric card is tapped.
    public var onGemsCardTapped: (() -> Void)?
    
    /// Called when Friends metric card is tapped.
    public var onFriendsCardTapped: (() -> Void)?
    
    /// Called when an assistant item is tapped.
    public var onAssistantItemTapped: ((Int) -> Void)?
    
    /// Called when a featured item row is tapped.
    public var onFeaturedItemTapped: ((Int) -> Void)?
    
    /// Called when login button is tapped.
    public var onLoginTapped: (() -> Void)?
    
    /// Called when logout button is tapped.
    public var onLogoutTapped: (() -> Void)?
    
    // MARK: - Subviews
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Section: User Profile
    private let userProfileContainer = UIView()
    private let userProfileCard = UserProfileCardView()
    
    // Section: Assistants
    public private(set) var assistantsSection = AssistantsSectionView()
    
    // Section: Metrics (Gems / Friends)
    public private(set) var metricsSection = MetricsSectionView()
    
    // Section: AI Chat button
    private let aiChatButton = AiChatButtonView()
    
    // Section: Featured
    public private(set) var featuredSection = FeaturedSectionView()
    
    // Section: Auth (Login/Logout)
    private let authButton = UIButton(type: .system)
    private var authButtonMode: AuthButtonMode = .logout
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
        setupLayout()
        setupActions()
        setAuthButtonMode(.logout)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
        setupLayout()
        setupActions()
        setAuthButtonMode(.logout)
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = DS.Color.background
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        
        contentStack.axis = .vertical
        contentStack.spacing = DS.Spacing.md * 1.5
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // User profile container
        userProfileContainer.backgroundColor = .clear
        userProfileCard.translatesAutoresizingMaskIntoConstraints = false
        userProfileContainer.addSubview(userProfileCard)
        
        // Assistants
        assistantsSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Metrics
        metricsSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Featured
        featuredSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Auth button (login/logout) styling مشترک
        authButton.setTitleColor(.white, for: .normal)
        authButton.layer.cornerRadius = 14
        authButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        authButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        authButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add arranged subviews
        contentStack.addArrangedSubview(userProfileContainer)
        contentStack.addArrangedSubview(assistantsSection)
        contentStack.addArrangedSubview(metricsSection)
        contentStack.addArrangedSubview(aiChatButton)
        contentStack.addArrangedSubview(featuredSection)
        contentStack.addArrangedSubview(authButton)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(contentStack)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DS.Spacing.md * 1.5),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DS.Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DS.Spacing.md),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -(DS.Spacing.md + 96)
            ),
        ])
        
        // User profile card pinned to container
        NSLayoutConstraint.activate([
            userProfileCard.topAnchor.constraint(equalTo: userProfileContainer.topAnchor),
            userProfileCard.leadingAnchor.constraint(equalTo: userProfileContainer.leadingAnchor),
            userProfileCard.trailingAnchor.constraint(equalTo: userProfileContainer.trailingAnchor),
            userProfileCard.bottomAnchor.constraint(equalTo: userProfileContainer.bottomAnchor),
        ])
        
        // Equal widths for metric cards
        metricsSection.setEqualWidthConstraint()
        
        // Fixed height for assistants row (portrait + landscape safe)
        assistantsSection.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        // Auth button full width height
        authButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    private func setupActions() {
        // Profile card actions
        userProfileCard.onUpgradeTapped = { [weak self] in
            self?.onUpgradeTapped?()
        }
        userProfileCard.onNameTapped = { [weak self] in
            self?.onProfileNameTapped?()
        }
        userProfileCard.onAvatarTapped = { [weak self] in
            self?.onAvatarTapped?()
        }
        userProfileCard.onMenuTapped = { [weak self] in
            self?.onProfileMenuTapped?()
        }
        
        // Metrics actions
        metricsSection.onGemsTapped = { [weak self] in
            self?.onGemsCardTapped?()
        }
        metricsSection.onFriendsTapped = { [weak self] in
            self?.onFriendsCardTapped?()
        }
        
        // Assistants
        assistantsSection.onItemTapped = { [weak self] index in
            self?.onAssistantItemTapped?(index)
        }
        
        // AI Chat button
        aiChatButton.onTap = { [weak self] in
            self?.onAiChatTapped?()
        }
        
        // Featured actions
        featuredSection.onItemTapped = { [weak self] index in
            self?.onFeaturedItemTapped?(index)
        }
        
        // Auth (login/logout)
        authButton.addTarget(self, action: #selector(handleAuthButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public API
    
    /// Configure the view based on current user.
    /// If user is nil → show Login button, otherwise Logout.
    public func configure(with user: UserDTO?) {
        if let user = user {
            userProfileContainer.isHidden = false
            userProfileCard.configure(with: user)
            metricsSection.updateGemsValue("\(user.currentGemBalance)")
            setAuthButtonMode(.logout)
        } else {
            userProfileContainer.isHidden = true
            metricsSection.updateGemsValue("0")
            setAuthButtonMode(.login)
        }
    }
    
    /// Allows controller to override button mode manually if لازم شد.
    public func setAuthButtonMode(_ mode: AuthButtonMode) {
        authButtonMode = mode
        switch mode {
        case .login:
            authButton.setTitle("Login to Ai Features", for: .normal)
            authButton.backgroundColor = .systemBlue
        case .logout:
            authButton.setTitle("Logout from Ai Features", for: .normal)
            authButton.backgroundColor = .systemRed
        }
    }
    
    public func setLocalAvatar(_ image: UIImage) {
        userProfileCard.setLocalAvatar(image)
    }
    
    // MARK: - Actions
    
    @objc
    private func handleAuthButtonTapped() {
        switch authButtonMode {
        case .login:
            onLoginTapped?()
        case .logout:
            onLogoutTapped?()
        }
    }
}

// MARK: - UserProfileCardView

/// Card displaying user profile, avatar, name, ID, and actions.
private final class UserProfileCardView: UIView {
    
    // Callbacks
    var onUpgradeTapped: (() -> Void)?
    var onNameTapped: (() -> Void)?
    var onAvatarTapped: (() -> Void)?
    var onMenuTapped: (() -> Void)?
    
    private let titleLabel = UILabel()
    private let menuButton = UIButton(type: .system)
    
    private let containerStack = UIStackView()
    
    private let avatarView = RemoteAvatarImageView()
    private let nameStack = UIStackView()
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let upgradeButton = UIButton(type: .system)
    
    // Gesture recognizers
    private lazy var nameTapGesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(handleNameTapped))
        return g
    }()
    
    private lazy var avatarTapGesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(handleAvatarTapped))
        return g
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
        setupActions()
    }
    
    private func setupView() {
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Title row
        titleLabel.text = "User Profile"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = DS.Color.text
        
        let menuImage = UIImage(systemName: "ellipsis") // placeholder, vertical in RTL adjusted by system
        menuButton.setImage(menuImage, for: .normal)
        menuButton.tintColor = DS.Color.text
        
        // Avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 28
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = UIColor.systemGray4
        avatarView.contentMode = .scaleAspectFill
        avatarView.isUserInteractionEnabled = true
        
        // Name & ID
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = DS.Color.text
        nameLabel.numberOfLines = 1
        
        idLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        idLabel.textColor = UIColor.secondaryLabel
        
        nameStack.axis = .vertical
        nameStack.alignment = .leading
        nameStack.spacing = 4
        nameStack.addArrangedSubview(nameLabel)
        nameStack.addArrangedSubview(idLabel)
        nameStack.isUserInteractionEnabled = true
        
        // Upgrade button
        upgradeButton.setTitle("Upgrade to premium", for: .normal)
        upgradeButton.setTitleColor(.white, for: .normal)
        upgradeButton.backgroundColor = UIColor.systemBlue
        upgradeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        upgradeButton.layer.cornerRadius = 14
        upgradeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Main horizontal stack
        containerStack.axis = .horizontal
        containerStack.alignment = .center
        containerStack.spacing = DS.Spacing.md
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        let leftStack = UIStackView(arrangedSubviews: [nameStack, upgradeButton])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 8
        
        containerStack.addArrangedSubview(avatarView)
        containerStack.addArrangedSubview(leftStack)
        containerStack.setCustomSpacing(DS.Spacing.md, after: avatarView)
        
        // Top row
        let topRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), menuButton])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        
        let rootStack = UIStackView(arrangedSubviews: [topRow, containerStack])
        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = DS.Spacing.md
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(rootStack)
        
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: DS.Spacing.md),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DS.Spacing.md),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DS.Spacing.md),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DS.Spacing.md),
            
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor)
        ])
    }
    
    private func setupLayout() {
        // No extra layout here, all handled in setupView.
    }
    
    private func setupActions() {
        upgradeButton.addTarget(self, action: #selector(handleUpgradeTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(handleMenuTapped), for: .touchUpInside)
        
        nameStack.addGestureRecognizer(nameTapGesture)
        avatarView.addGestureRecognizer(avatarTapGesture)
    }
    
    // MARK: - Configure
    
    func configure(with user: UserDTO) {
        let fullName: String
        if let first = user.firstName, let last = user.lastName, !first.isEmpty || !last.isEmpty {
            fullName = [first, last].compactMap { $0 }.joined(separator: " ")
        } else if let username = user.username {
            fullName = username
        } else {
            fullName = "User"
        }
        nameLabel.text = fullName
        
        idLabel.text = "ID : \(user.telegramId)"
        
        if var path = user.photoSmall ?? user.photoBig {
            let updatedAt = user.updatedAt
            let ts = Int(updatedAt.timeIntervalSince1970)
            if path.contains("?") {
                path += "&v=\(ts)"
            } else {
                path += "?v=\(ts)"
            }
            print("final avatar path with version: \(path)")
            avatarView.setImageWithUserPath(path)
        } else {
            avatarView.image = UIImage(named: "ic_profile_placeholder")
        }
    }
    
    
    public func setLocalAvatar(_ image: UIImage) {
        avatarView.image = image
    }
    
    // MARK: - Handlers
    
    @objc
    private func handleUpgradeTapped() {
        onUpgradeTapped?()
    }
    
    @objc
    private func handleNameTapped() {
        onNameTapped?()
    }
    
    @objc
    private func handleAvatarTapped() {
        onAvatarTapped?()
    }
    
    @objc
    private func handleMenuTapped() {
        onMenuTapped?()
    }
}

// MARK: - RemoteAvatarImageView

/// Simple image view that loads remote image using AppEnvironment.baseURLString + relative path.
private final class RemoteAvatarImageView: UIImageView {
    
    private var currentTask: URLSessionDataTask?
    
    /// Sets image from a user-relative path (e.g. "/uploads/.._small.png").
    func setImageWithUserPath(_ path: String?) {
        currentTask?.cancel()
        image = nil
        
        guard let path = path else {
            backgroundColor = UIColor.systemGray5
            return
        }
        
        guard let baseURL = URL(string: AppEnvironment.baseURLString) else {
            backgroundColor = UIColor.systemGray5
            return
        }
        
        // Use relative URL so "/uploads/..." is appended after base path.
        guard let url = URL(string: path, relativeTo: baseURL) else {
            backgroundColor = UIColor.systemGray5
            return
        }
        
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = img
            }
        }
        currentTask = task
        task.resume()
    }
}

// MARK: - AssistantsSectionView

public final class AssistantsSectionView: UIView {
    
    /// Called when an assistant item is tapped (index in current list).
    public var onItemTapped: ((Int) -> Void)?
    
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    
    private var items: [AssistantItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
    }
    
    private func setupView() {
        titleLabel.text = "Assistants"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = DS.Color.text
        
        scrollView.showsHorizontalScrollIndicator = false
        
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(scrollView)
        scrollView.addSubview(stack)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLayout() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -4),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    public func configure(assistants: [AssistantItem]) {
        self.items = assistants
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, item) in assistants.enumerated() {
            let view = AssistantItemView()
            view.configure(name: item.name, imageName: item.imageName)
            view.tag = index
            view.onTapped = { [weak self, weak view] in
                guard let self = self, let view = view else { return }
                self.onItemTapped?(view.tag)
            }
            stack.addArrangedSubview(view)
            
            view.widthAnchor.constraint(equalToConstant: 80).isActive = true
        }
    }
}

private final class AssistantItemView: UIView {
    
    var onTapped: (() -> Void)?
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
        
        imageView.backgroundColor = UIColor.systemGray4
        imageView.layer.cornerRadius = 26
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Placeholder icon name, user will provide real assets later
        imageView.image = UIImage(named: "ic_assistant_placeholder")
        
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = DS.Color.text
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        
        let stack = UIStackView(arrangedSubviews: [imageView, nameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            imageView.widthAnchor.constraint(equalToConstant: 52),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
    }
    
    private func setupLayout() { }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    func configure(name: String, imageName: String) {
        nameLabel.text = name
        // Actual vector / image asset to be added later
        if let img = UIImage(named: imageName) {
            imageView.image = img
        }
    }
    
    @objc
    private func handleTap() {
        onTapped?()
    }
}

// MARK: - MetricsSectionView
public struct Callbacks {
    public var onGemsTapped: (() -> Void)?
    public var onFriendsTapped: (() -> Void)?
}

public final class MetricsSectionView: UIView {
    
    public var onGemsTapped: (() -> Void)?
    public var onFriendsTapped: (() -> Void)?
    
    private let stack = UIStackView()
    private let gemsCard = MetricCardView()
    private let friendsCard = MetricCardView()
    
    private var equalWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
    }
    
    private func setupView() {
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = DS.Spacing.md
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        stack.addArrangedSubview(gemsCard)
        stack.addArrangedSubview(friendsCard)
        
        // Configure content
        gemsCard.configure(title: "Gems", value: "0", iconName: "ic_gems_metric")
        friendsCard.configure(title: "Friend", value: "0", iconName: "ic_friends_metric")
        
        // Tap
        gemsCard.onTap = { [weak self] in self?.onGemsTapped?() }
        friendsCard.onTap = { [weak self] in self?.onFriendsTapped?() }
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    public func setEqualWidthConstraint() {
        // Distribution .fillEqually already ensures equal width; no extra constraint needed.
        // This method exists only to satisfy call from parent for clarity.
    }
    
    public func configure(gemsValue: String, friendsValue: String) {
        gemsCard.updateValue(gemsValue)
        friendsCard.updateValue(friendsValue)
    }
    
    public func updateGemsValue(_ value: String) {
        gemsCard.updateValue(value)
    }
}

// MARK: - FeaturedSectionView

public final class FeaturedSectionView: UIView {
    
    var onItemTapped: ((Int) -> Void)?
    
    private let titleLabel = UILabel()
    private let stack = UIStackView()
    
    private var items: [FeaturedItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
    }
    
    private func setupView() {
        titleLabel.text = "Featured"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = DS.Color.text
        
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(stack)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLayout() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    public func configure(items: [FeaturedItem]) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, item) in items.enumerated() {
            let row = FeaturedRowView()
            row.configure(title: item.title, subtitle: item.subtitle)
            row.tag = index
            row.onTapped = { [weak self, weak row] in
                guard let self = self, let row = row else { return }
                self.onItemTapped?(row.tag)
            }
            stack.addArrangedSubview(row)
        }
    }
}

private final class FeaturedRowView: UIView {
    
    var onTapped: (() -> Void)?
    
    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
        
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.backgroundColor = UIColor.systemGray4
        iconView.layer.cornerRadius = 22
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        iconView.image = UIImage(named: "ic_featured_placeholder")
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = DS.Color.text
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 2
        
        addSubview(container)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: DS.Spacing.md),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: DS.Spacing.md),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -DS.Spacing.md),
            textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: DS.Spacing.md),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -DS.Spacing.md),
        ])
    }
    
    private func setupLayout() { }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    @objc
    private func handleTap() {
        onTapped?()
    }
}

// MARK: - AiChatButtonView

private final class AiChatButtonView: UIView {
    
    var onTap: (() -> Void)?
    
    private let container = UIView()
    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
        
        // Blue pill background
        container.backgroundColor = UIColor.systemBlue
        container.layer.cornerRadius = 22
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon background (square)
        iconBackground.backgroundColor = UIColor.systemTeal
        iconBackground.layer.cornerRadius = 10
        iconBackground.layer.masksToBounds = true
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.contentMode = .scaleAspectFit
        // Placeholder icon
        iconView.image = UIImage(named: "ic_ai_chat") ?? UIImage(systemName: "message.fill")
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "AI Chat (Ask Anything)"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .white
        
        addSubview(container)
        container.addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        
        let hStack = UIStackView(arrangedSubviews: [iconBackground, titleLabel])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            // From edges of HonistAiHomeView: 16pt left/right
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Fixed height so در portrait و landscape شکل ثابت بمونه
            container.heightAnchor.constraint(equalToConstant: 56),
            
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: container.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            iconBackground.widthAnchor.constraint(equalToConstant: 36),
            iconBackground.heightAnchor.constraint(equalTo: iconBackground.widthAnchor),
            
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
        ])
    }
    
    private func setupLayout() { }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap() {
        onTap?()
    }
}
