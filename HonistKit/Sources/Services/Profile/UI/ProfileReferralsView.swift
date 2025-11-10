// Services/Profile/UI/ProfileReferralsView.swift

import UIKit
import HonistDesignSystem
import HonistUIComponents
import HonistFoundation

// MARK: - Root view

/// Main view for "My Referrals" screen.
/// Contains:
/// - Header badge
/// - Title + subtitle
/// - Invite Friend button
/// - Copy referral code card
/// - Metrics (Friends / Rewards)
/// - Friends list title + vertical list of referrals
public final class ProfileReferralsView: UIView {
    
    // MARK: - Public callbacks
    
    /// Called when "Invite Friend" button is tapped.
    public var onInviteTapped: (() -> Void)?
    
    /// Called when "Copy Referral Code" card is tapped.
    public var onCopyCodeTapped: (() -> Void)?
    
    // MARK: - Subviews
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let headerView = ReferralsHeaderView()
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let inviteButton = UIButton(type: .system)
    private let copyCodeCard = ReferralCodeCardView()
    
    private let metricsView = ReferralsMetricsView()
    
    private let friendsTitleLabel = UILabel()
    private let friendsListStack = UIStackView()
    private let emptyStateView = FriendsEmptyStateView()
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    // MARK: - Build
    
    private func build() {
        backgroundColor = DS.Color.background
        
        // Scroll
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Main vertical stack
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = DS.Spacing.md * 1.5
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title + subtitle
        titleLabel.text = "My Referrals"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = DS.Color.text
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Invite Friends & Get Bonuses"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        
        // Invite button
        inviteButton.setTitle("Invite Friend", for: .normal)
        inviteButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        inviteButton.setTitleColor(.white, for: .normal)
        inviteButton.backgroundColor = .systemBlue
        inviteButton.layer.cornerRadius = 16
        inviteButton.layer.masksToBounds = true
        inviteButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.addTarget(self, action: #selector(handleInviteTapped), for: .touchUpInside)
        
        // Copy code card
        copyCodeCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Metrics
        metricsView.translatesAutoresizingMaskIntoConstraints = false
        
        // Friends title
        friendsTitleLabel.text = "Friends List"
        friendsTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        friendsTitleLabel.textColor = DS.Color.text
        
        // Friends list stack
        friendsListStack.axis = .vertical
        friendsListStack.alignment = .fill
        friendsListStack.spacing = 8
        friendsListStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Empty state view
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        
        // Friends section container
        let friendsContainer = UIStackView(arrangedSubviews: [friendsTitleLabel])
        friendsContainer.axis = .vertical
        friendsContainer.alignment = .leading
        friendsContainer.spacing = 8
        
        let listContainer = UIView()
        listContainer.translatesAutoresizingMaskIntoConstraints = false
        listContainer.addSubview(friendsListStack)
        listContainer.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            friendsListStack.topAnchor.constraint(equalTo: listContainer.topAnchor),
            friendsListStack.leadingAnchor.constraint(equalTo: listContainer.leadingAnchor),
            friendsListStack.trailingAnchor.constraint(equalTo: listContainer.trailingAnchor),
            friendsListStack.bottomAnchor.constraint(lessThanOrEqualTo: listContainer.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: listContainer.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: listContainer.centerYAnchor, constant: 40),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: listContainer.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: listContainer.trailingAnchor, constant: -16)
        ])
        
        // Title stack
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 4
        
        // Embed into main content
        contentStack.addArrangedSubview(headerView)
        contentStack.addArrangedSubview(titleStack)
        contentStack.addArrangedSubview(inviteButton)
        contentStack.addArrangedSubview(copyCodeCard)
        contentStack.addArrangedSubview(metricsView)
        contentStack.addArrangedSubview(friendsContainer)
        contentStack.addArrangedSubview(listContainer)
        
        addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        setupLayout()
        
        // Copy code tap
        copyCodeCard.onTap = { [weak self] in
            self?.onCopyCodeTapped?()
        }
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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DS.Spacing.md),
        ])
        
        // Header height (adaptive to orientation)
        headerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.23).isActive = true
        
        inviteButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        copyCodeCard.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    // MARK: - Public configuration
    
    /// Configure metrics section.
    public func configureMetrics(friendsCount: Int, totalRewards: Int) {
        metricsView.configure(
            friendsCount: friendsCount,
            rewardsValue: "\(totalRewards)"
        )
    }
    
    /// Configure referral code (shown inside copy card).
    public func configureReferralCode(_ code: String?) {
        copyCodeCard.configure(code: code ?? "—")
    }
    
    /// Configure list of referrals.
    public func configureReferrals(_ referrals: [ReferralDTO]) {
        friendsListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if referrals.isEmpty {
            friendsListStack.isHidden = true
            emptyStateView.isHidden = false
        } else {
            friendsListStack.isHidden = false
            emptyStateView.isHidden = true
            
            for referral in referrals {
                let row = ReferralFriendRowView()
                row.configure(with: referral)
                friendsListStack.addArrangedSubview(row)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc
    private func handleInviteTapped() {
        onInviteTapped?()
    }
}

// MARK: - ReferralsHeaderView

/// Top hero header with badge / illustration.
private final class ReferralsHeaderView: UIView {
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    private func build() {
        backgroundColor = .clear
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        // Placeholder asset; real illustration should be added later.
        imageView.image = UIImage(named: "ic_referrals_header") ?? UIImage(systemName: "sparkles")
        imageView.tintColor = .systemPurple
        
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

// MARK: - ReferralCodeCardView

/// Card that shows "Copy Referral Code" and the actual code.
private final class ReferralCodeCardView: UIView {
    
    var onTap: (() -> Void)?
    
    private let container = UIView()
    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let codeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
        addTapGesture()
    }
    
    private func build() {
        isUserInteractionEnabled = true
        
        container.backgroundColor = UIColor.systemBlue
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        iconBackground.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        iconBackground.layer.cornerRadius = 10
        iconBackground.layer.masksToBounds = true
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.image = UIImage(named: "ic_referral_copy") ?? UIImage(systemName: "doc.on.doc.fill")
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "Copy Referral Code"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        
        codeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        codeLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        
        addSubview(container)
        container.addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, codeLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            iconBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 36),
            iconBackground.heightAnchor.constraint(equalTo: iconBackground.widthAnchor),
            
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            
            textStack.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    func configure(code: String) {
        codeLabel.text = code
    }
    
    @objc
    private func handleTap() {
        onTap?()
    }
}

// MARK: - ReferralsMetricsView (friends / rewards)

/// Metrics row for this screen.
/// Uses MetricCardView but cards are not tappable.
public final class ReferralsMetricsView: UIView {
    
    private let stack = UIStackView()
    private let friendsCard = MetricCardView()
    private let rewardsCard = MetricCardView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    private func build() {
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = DS.Spacing.md
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        stack.addArrangedSubview(friendsCard)
        stack.addArrangedSubview(rewardsCard)
        
        // Configure titles/default values
        friendsCard.configure(title: "Friend", value: "0", iconName: "ic_friends_metric")
        rewardsCard.configure(title: "Rewards", value: "0", iconName: "ic_gems_metric")
        
        // In this screen, metrics are not tappable
        friendsCard.isUserInteractionEnabled = false
        rewardsCard.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    public func configure(friendsCount: Int, rewardsValue: String) {
        friendsCard.updateValue("\(friendsCount)")
        rewardsCard.updateValue("\(rewardsValue), GET 2x")
    }
}

// MARK: - ReferralFriendRowView

/// Single row in the "Friends List" section.
private final class ReferralFriendRowView: UIView {
    
    private let container = UIView()
    private let avatarView = RemoteAvatarImageView()
    private let nameLabel = UILabel()
    private let hStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    private func build() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Container
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.image = UIImage(named: "ic_referral_avatar_placeholder")
            ?? UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .secondaryLabel
        
        // Name label
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = DS.Color.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Horizontal stack: [avatar][name]
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(avatarView)
        hStack.addArrangedSubview(nameLabel)
        
        addSubview(container)
        container.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            // Container pin to row
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Stack inside container
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            // Avatar size
            avatarView.widthAnchor.constraint(equalToConstant: 36),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
            
            // Minimum row height
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }
    
    func configure(with referral: ReferralDTO) {
        let invitee = referral.invitee
        let fullName = [invitee?.firstName, invitee?.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        if !fullName.isEmpty {
            nameLabel.text = fullName
        } else if let username = invitee?.username, !username.isEmpty {
            nameLabel.text = username
        } else {
            nameLabel.text = "Friend"
        }
        
        if let photoSmall = invitee?.photoSmall {
            avatarView.setImageWithUserPath(photoSmall)
        }
    }
}

// MARK: - Small helper

private extension UIView {
    /// Pins all edges of this view to its superview.
    func pinEdges(to superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
        ])
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


/// Empty state view shown when there are no referral friends.
/// Shows an icon + title + subtitle centered.
final class FriendsEmptyStateView: UIView {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let vStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    private func build() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "ic_referrals_empty")
            ?? UIImage(systemName: "person.2.slash")
        imageView.tintColor = UIColor.systemPurple
        
        // Title
        titleLabel.text = "The Friends list is empty"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = DS.Color.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        // Subtitle
        subtitleLabel.text = "Invite your first friend to be displayed here"
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        
        // Stack
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        vStack.addArrangedSubview(imageView)
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(subtitleLabel)
        
        addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            vStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
    }
}
