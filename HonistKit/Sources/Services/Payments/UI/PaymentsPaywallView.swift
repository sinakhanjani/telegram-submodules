import UIKit
import HonistDesignSystem
import HonistModels

// MARK: - Internal helpers

private enum PaymentsAssets {
    // You will add these names into your Assets.xcassets later.
    static let headerImageName = "honist_paywall_header"
    static let subscriptionIconName = "honist_paywall_subscription_icon"
    static let oneTimePackIconName = "honist_paywall_pack_icon"
}

/// Card visual style: subscription (top list) vs one-time pack (bottom horizontal list).
private enum ProductCardStyle {
    case subscription
    case oneTime
}

private final class InsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

/// Simple reusable product card used in both vertical and horizontal sections.
// MARK: - ProductCardView

/// Simple reusable product card used in both vertical and horizontal sections.
/// Always uses a dark-style background (like Telegram dark paywall).
private final class ProductCardView: UIControl {

    // MARK: - UI

    private let containerView = UIView()
    private let iconImageView = UIImageView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()        // e.g. "50 Gems / Month"
    private let priceLabel = UILabel()           // e.g. "$3.99/month"

    private let separatorView = UIView()
    private let descriptionLabel = UILabel()     // long description text

    private let popularBadgeLabel = UILabel()
    private let discountBadgeLabel = UILabel()

    // Keep a reference for layout decisions if needed
    private var style: ProductCardStyle = .subscription

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // Use UIControl highlight behavior
        backgroundColor = .clear
        layer.cornerRadius = 0

        // --- Container (card) ---
        containerView.translatesAutoresizingMaskIntoConstraints = false
        // Always dark-style background (independent of system theme)
        containerView.backgroundColor = UIColor(
            red: 40/255,
            green: 46/255,
            blue: 60/255,
            alpha: 1.0
        )
        containerView.layer.cornerRadius = 24
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.clipsToBounds = false
        containerView.isUserInteractionEnabled = false
        
        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // --- Icon ---
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        // --- Title / subtitle ---
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.textColor = UIColor(white: 1.0, alpha: 0.85)
        subtitleLabel.numberOfLines = 1

        // --- Price ---
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.boldSystemFont(ofSize: 18)
        priceLabel.textColor = .white
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        // --- Badges ---
        popularBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        popularBadgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        popularBadgeLabel.textColor = .white
        popularBadgeLabel.backgroundColor = .systemPurple
        popularBadgeLabel.textAlignment = .center
        popularBadgeLabel.layer.cornerRadius = 10
        popularBadgeLabel.clipsToBounds = true
        popularBadgeLabel.isHidden = true

        discountBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        discountBadgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        discountBadgeLabel.textColor = .white
        discountBadgeLabel.backgroundColor = .systemRed
        discountBadgeLabel.textAlignment = .center
        discountBadgeLabel.layer.cornerRadius = 10
        discountBadgeLabel.clipsToBounds = true
        discountBadgeLabel.isHidden = true

        // --- Separator ---
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor(white: 1.0, alpha: 0.18)

        // --- Description ---
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = UIColor(white: 1.0, alpha: 0.85)
        descriptionLabel.numberOfLines = 0

        // --- Layout ---

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [iconImageView, textStack, priceLabel])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 12
        topRow.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(topRow)
        containerView.addSubview(separatorView)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(popularBadgeLabel)
        containerView.addSubview(discountBadgeLabel)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            // Top row (icon + texts + price)
            topRow.topAnchor.constraint(equalTo: containerView.topAnchor, constant: DS.Spacing.md * 1.2),
            topRow.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.md * 2.0),
            topRow.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.md * 2.0),

            // Separator
            separatorView.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: DS.Spacing.md * 1.3),
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.md * 2.0),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.md * 2.0),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: DS.Spacing.md * 1.3),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.md * 2.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.md * 2.0),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -DS.Spacing.md * 1.8),

            // Popular badge (top-right)
            popularBadgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            popularBadgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            popularBadgeLabel.heightAnchor.constraint(equalToConstant: 20),

            // Discount badge (top-left)
            discountBadgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            discountBadgeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            discountBadgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Configuration

    /// Configure the card with given product and style.
    func configure(with product: ProductDTO, style: ProductCardStyle, isSelected: Bool) {
        self.style = style

        // Icon
        switch style {
        case .subscription:
            let img = UIImage(named: PaymentsAssets.subscriptionIconName) ??
                UIImage(systemName: "diamond.fill")
            iconImageView.image = img
        case .oneTime:
            let img = UIImage(named: PaymentsAssets.oneTimePackIconName) ??
                UIImage(systemName: "diamond.fill")
            iconImageView.image = img
        }

        titleLabel.text = "Premium"

        // "50 Gems / Month" مثل اسکرین‌شات
        subtitleLabel.text = makeSubtitleText(for: product)

        // Long description زیر خط
        descriptionLabel.text = product.shortDescription ?? product.subject

        priceLabel.text = Self.formatPrice(
            cents: product.basePriceCents,
            currencyCode: product.currency
        )

        // Popular badge
        if product.isPopular {
            popularBadgeLabel.text = "POPULAR"
            popularBadgeLabel.isHidden = false
            popularBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        } else {
            popularBadgeLabel.isHidden = true
        }

        // Discount badge (offer)
        if let offer = product.offer {
            discountBadgeLabel.text = "\(offer.discountValue)% OFF"
            discountBadgeLabel.isHidden = false
            discountBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
        } else {
            discountBadgeLabel.isHidden = true
        }

        applySelection(isSelected: isSelected)
    }

    private func makeSubtitleText(for product: ProductDTO) -> String? {
        if let gems = product.gemsPerPeriod,
           let period = product.period?.lowercased() {
            let periodText: String
            switch period {
            case "weekly": periodText = "Week"
            case "monthly": periodText = "Month"
            case "annually", "yearly": periodText = "Year"
            default: periodText = period.capitalized
            }
            return "\(gems) Gems / \(periodText)"
        }

        // Fallback
        return product.subject
    }

    private func applySelection(isSelected: Bool) {
        containerView.layer.borderWidth = isSelected ? 2 : 1
        containerView.layer.borderColor = isSelected
            ? UIColor.systemYellow.cgColor
            : UIColor.clear.cgColor
    }

    override var isHighlighted: Bool {
        didSet {
            // Simple pressed feedback
            containerView.alpha = isHighlighted ? 0.8 : 1.0
        }
    }

    // MARK: - Helpers

    public static func formatPrice(cents: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        if let result = formatter.string(from: amount) {
            return result
        } else {
            return "\(amount) \(currencyCode)"
        }
    }
}

// MARK: - OneTimePackCardView (square cards for horizontal section)
/// Square card just for one-time packs (horizontal list).
/// Designed for ~120x110 size.
private final class OneTimePackCardView: UIControl {

    // MARK: - UI

    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let amountLabel = UILabel()     // e.g. "110"
    private let gemsLabel = UILabel()       // "Gems"
    private let priceLabel = UILabel()      // "$ 9.99"

    private let popularBadgeLabel = InsetLabel()
    private let discountBadgeLabel = InsetLabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        self.clipsToBounds = false
        
        // --- Container (square card) ---
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(
            red: 40/255,
            green: 46/255,
            blue: 60/255,
            alpha: 1.0
        )
        containerView.layer.cornerRadius = 16      // 👈 کوچیک‌تر شد
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.clipsToBounds = false
        containerView.isUserInteractionEnabled = false   // تاچ روی خود کنترل

        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // --- Icon ---
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        // --- Amount + "Gems" ---
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = UIFont.boldSystemFont(ofSize: 18)        // 👈 کوچیک‌تر
        amountLabel.textColor = .white
        amountLabel.numberOfLines = 1
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.7

        gemsLabel.translatesAutoresizingMaskIntoConstraints = false
        gemsLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium) // 👈 کوچک
        gemsLabel.textColor = .white
        gemsLabel.text = "Gems"

        let amountStack = UIStackView(arrangedSubviews: [amountLabel, gemsLabel])
        amountStack.axis = .horizontal
        amountStack.spacing = 4
        amountStack.alignment = .firstBaseline
        amountStack.translatesAutoresizingMaskIntoConstraints = false

        // --- Price ---
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.boldSystemFont(ofSize: 14)   // 👈 کوچک
        priceLabel.textColor = .white
        priceLabel.textAlignment = .center
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.7
        priceLabel.numberOfLines = 1

        // --- Badges ---
        popularBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        popularBadgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        popularBadgeLabel.textColor = .white
        popularBadgeLabel.backgroundColor = .systemYellow
        popularBadgeLabel.textAlignment = .center
        popularBadgeLabel.layer.cornerRadius = 11
        popularBadgeLabel.clipsToBounds = true
        popularBadgeLabel.isHidden = true

        discountBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        discountBadgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        discountBadgeLabel.textColor = .white
        discountBadgeLabel.backgroundColor = .systemPink
        discountBadgeLabel.textAlignment = .center
        discountBadgeLabel.layer.cornerRadius = 11
        discountBadgeLabel.clipsToBounds = true
        discountBadgeLabel.isHidden = true

        containerView.addSubview(iconImageView)
        containerView.addSubview(amountStack)
        containerView.addSubview(priceLabel)
        containerView.addSubview(popularBadgeLabel)
        containerView.addSubview(discountBadgeLabel)

        NSLayoutConstraint.activate([
            // Icon بالای کارت، وسط افقی
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),

            // "110 Gems" زیر آیکون
            amountStack.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            amountStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // 🟡 قیمت: نزدیک‌تر به amountStack، نه چسبیده به پایین
            priceLabel.topAnchor.constraint(equalTo: amountStack.bottomAnchor, constant: 6),
            priceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8),

            // Popular / Discount badge – روی لبه‌ی بالای کارت
            popularBadgeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            popularBadgeLabel.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            popularBadgeLabel.heightAnchor.constraint(equalToConstant: 22),

            discountBadgeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            discountBadgeLabel.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            discountBadgeLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    // MARK: - Configuration

    func configure(with product: ProductDTO, style: ProductCardStyle = .oneTime, isSelected: Bool) {
        // آیکون
        let img = UIImage(named: PaymentsAssets.oneTimePackIconName) ??
            UIImage(systemName: "diamond.fill")
        iconImageView.image = img

        // مقدار جِمز
        if let gems = product.gemsPerPeriod {
            amountLabel.text = "\(gems)"
        } else {
            amountLabel.text = product.title
        }

        // قیمت
        priceLabel.text = ProductCardView.formatPrice(
            cents: product.basePriceCents,
            currencyCode: product.currency
        )

        // Badge ها
        if product.isPopular {
            popularBadgeLabel.text = "POPULAR"
            popularBadgeLabel.isHidden = false
            discountBadgeLabel.isHidden = true
        } else if let offer = product.offer {
            discountBadgeLabel.text = "\(offer.discountValue)% OFF"
            discountBadgeLabel.isHidden = false
            popularBadgeLabel.isHidden = true
        } else {
            popularBadgeLabel.isHidden = true
            discountBadgeLabel.isHidden = true
        }

        applySelection(isSelected: isSelected)
    }

    private func applySelection(isSelected: Bool) {
        containerView.layer.borderWidth = isSelected ? 1 : 1
        containerView.layer.borderColor = isSelected
            ? UIColor.systemYellow.cgColor
            : UIColor.clear.cgColor
    }

    override var isHighlighted: Bool {
        didSet {
            containerView.alpha = isHighlighted ? 0.8 : 1.0
        }
    }
}


// MARK: - PaymentsPaywallView
/// Root view for the payments paywall modal.
/// - Does not own any networking logic.
/// - Receives data from the view controller and exposes user actions via closures.
public final class PaymentsPaywallView: UIView {

    // MARK: - Public callbacks

    /// Called whenever user selects a product (either subscription or one-time pack).
    public var onProductSelected: ((ProductDTO) -> Void)?

    /// Called when primary button is tapped with currently selected product (if any).
    public var onPrimaryButtonTapped: ((ProductDTO?) -> Void)?

    /// Called when user taps the close "X" button.
    public var onCloseTapped: (() -> Void)?

    // MARK: - Private state

    private var subscriptionProducts: [ProductDTO] = []
    private var oneTimeProducts: [ProductDTO] = []
    private var selectedProductId: String? {
        didSet {
            updateSelectionUI()
            updatePrimaryButtonTitle()
        }
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerImageView = UIImageView()

    private let subscriptionSectionStack = UIStackView()

    private let oneTimeTitleLabel = UILabel()
    private let oneTimeScrollView = UIScrollView()
    private let oneTimeStack = UIStackView()
    private let bannerSubtitleLabel = UILabel()

    private let primaryButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private let primaryButtonSpinner = UIActivityIndicatorView(style: .medium) // 👈 اضافه کن
    
    private let autoRenewLabel = UILabel()
    
    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // Telegram-ish blue / navy background for full screen
        backgroundColor =  UIColor(
            red: 27/255,
            green: 35/255,
            blue: 49/255,
            alpha: 1.0
        )

        // MARK: Close button (X) – we will place it on top of the banner later
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeImage = UIImage(systemName: "xmark")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        closeButton.layer.cornerRadius = 16
        closeButton.clipsToBounds = true
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Scroll view to allow whole content to scroll together
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.layer.cornerRadius = 15
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = true
        
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Card-like background for actual paywall content
        let cardBackground = UIView()
        cardBackground.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.backgroundColor = UIColor.clear
        cardBackground.layer.cornerRadius = 24
        cardBackground.layer.masksToBounds = true

        let containerWrapper = UIView()
        containerWrapper.translatesAutoresizingMaskIntoConstraints = false
        containerWrapper.addSubview(cardBackground)
        contentStack.addArrangedSubview(containerWrapper)

        NSLayoutConstraint.activate([
            cardBackground.topAnchor.constraint(equalTo: containerWrapper.topAnchor, constant: 20),
            cardBackground.leadingAnchor.constraint(equalTo: containerWrapper.leadingAnchor),
            cardBackground.trailingAnchor.constraint(equalTo: containerWrapper.trailingAnchor),
            cardBackground.bottomAnchor.constraint(equalTo: containerWrapper.bottomAnchor)
        ])
        
        // Main vertical stack inside the card
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardBackground.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: cardBackground.bottomAnchor, constant: -20)
        ])

        // MARK: - Hero area (banner only, no text on image)

        let heroContainer = UIView()
        heroContainer.translatesAutoresizingMaskIntoConstraints = false

        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.image = UIImage(named: PaymentsAssets.headerImageName) ??
            UIImage(systemName: "sparkles")
        headerImageView.clipsToBounds = true

        heroContainer.addSubview(headerImageView)

        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroContainer.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor)
        ])
        headerImageView.heightAnchor.constraint(
            equalTo: headerImageView.widthAnchor,
            multiplier: 4.0/9.0
        ).isActive = true
        
        // Subtitle on top of banner (bottom-center)
        bannerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bannerSubtitleLabel.text = "Stock up on Gems and chat without limits!"
        bannerSubtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        bannerSubtitleLabel.textColor = .white
        bannerSubtitleLabel.textAlignment = .center
        bannerSubtitleLabel.numberOfLines = 2
        // Slight shadow to be readable on bright parts of image
        bannerSubtitleLabel.layer.shadowColor = UIColor.black.cgColor
        bannerSubtitleLabel.layer.shadowOpacity = 0.4
        bannerSubtitleLabel.layer.shadowRadius = 2
        bannerSubtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)

        heroContainer.addSubview(bannerSubtitleLabel)

        NSLayoutConstraint.activate([
            bannerSubtitleLabel.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            bannerSubtitleLabel.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 21),
            bannerSubtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: heroContainer.leadingAnchor, constant: 24),
            bannerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: heroContainer.trailingAnchor, constant: -24)
        ])

        // Put close button ON TOP of the banner (top-right corner)
        heroContainer.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        cardStack.addArrangedSubview(heroContainer)

        // MARK: - Subscription section (vertical list)

        subscriptionSectionStack.axis = .vertical
        subscriptionSectionStack.spacing = 10
        subscriptionSectionStack.translatesAutoresizingMaskIntoConstraints = false
        
        subscriptionSectionStack.layoutMargins = UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)
        subscriptionSectionStack.isLayoutMarginsRelativeArrangement = true
        cardStack.addArrangedSubview(subscriptionSectionStack)

        // Auto-renew label
        autoRenewLabel.translatesAutoresizingMaskIntoConstraints = false
        autoRenewLabel.text = "The subscription will automatically renew every month"
        autoRenewLabel.font = UIFont.systemFont(ofSize: 12)
        autoRenewLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        autoRenewLabel.numberOfLines = 0
        autoRenewLabel.textAlignment = .center

        let autoRenewWrapper = UIView()
        autoRenewWrapper.translatesAutoresizingMaskIntoConstraints = false
        autoRenewWrapper.addSubview(autoRenewLabel)

        NSLayoutConstraint.activate([
            autoRenewLabel.topAnchor.constraint(equalTo: autoRenewWrapper.topAnchor, constant: 4),
            autoRenewLabel.leadingAnchor.constraint(equalTo: autoRenewWrapper.leadingAnchor, constant: 16),
            autoRenewLabel.trailingAnchor.constraint(equalTo: autoRenewWrapper.trailingAnchor, constant: -16),
            autoRenewLabel.bottomAnchor.constraint(equalTo: autoRenewWrapper.bottomAnchor, constant: -4)
        ])

        cardStack.addArrangedSubview(autoRenewWrapper)
        
        // MARK: - One-time packs section

        // --- Separator before one-time packs ---
        let oneTimeSeparator = UIView()
        oneTimeSeparator.translatesAutoresizingMaskIntoConstraints = false
        oneTimeSeparator.backgroundColor = UIColor(white: 1.0, alpha: 0.15)

        NSLayoutConstraint.activate([
            oneTimeSeparator.heightAnchor.constraint(equalToConstant: 1)
        ])

        cardStack.addArrangedSubview(oneTimeSeparator)

        oneTimeScrollView.translatesAutoresizingMaskIntoConstraints = false
        oneTimeScrollView.showsHorizontalScrollIndicator = false
        oneTimeScrollView.alwaysBounceHorizontal = true

        oneTimeStack.axis = .horizontal
        oneTimeStack.spacing = 12
        oneTimeStack.translatesAutoresizingMaskIntoConstraints = false

        oneTimeScrollView.addSubview(oneTimeStack)
        cardStack.addArrangedSubview(oneTimeScrollView)

        NSLayoutConstraint.activate([
            oneTimeStack.topAnchor.constraint(equalTo: oneTimeScrollView.contentLayoutGuide.topAnchor),
            oneTimeStack.leadingAnchor.constraint(equalTo: oneTimeScrollView.contentLayoutGuide.leadingAnchor),
            oneTimeStack.trailingAnchor.constraint(equalTo: oneTimeScrollView.contentLayoutGuide.trailingAnchor),
            oneTimeStack.bottomAnchor.constraint(equalTo: oneTimeScrollView.contentLayoutGuide.bottomAnchor),
            oneTimeStack.heightAnchor.constraint(equalTo: oneTimeScrollView.frameLayoutGuide.heightAnchor)
        ])

        // MARK: - Primary button (outside scroll, pinned near bottom)

        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setTitle("Continue", for: .normal)
        primaryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        primaryButton.backgroundColor = .systemBlue
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.layer.cornerRadius = 12
        primaryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)

        addSubview(primaryButton)

        NSLayoutConstraint.activate([
            primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            primaryButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        primaryButtonSpinner.translatesAutoresizingMaskIntoConstraints = false
        primaryButtonSpinner.hidesWhenStopped = true
        primaryButton.addSubview(primaryButtonSpinner)

        NSLayoutConstraint.activate([
            primaryButtonSpinner.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
            primaryButtonSpinner.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor)
        ])
    }

    // MARK: - Public configuration

    /// Configure paywall view with products and selected product id.
    public func configure(
        subscriptionProducts: [ProductDTO],
        oneTimeProducts: [ProductDTO],
        selectedProductId: String?
    ) {
        self.subscriptionProducts = subscriptionProducts
        self.oneTimeProducts = oneTimeProducts
        self.selectedProductId = selectedProductId

        rebuildSubscriptionSection()
        rebuildOneTimeSection()
        updatePrimaryButtonTitle()
    }

    // MARK: - Sections rebuilding

    private func rebuildSubscriptionSection() {
        subscriptionSectionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for product in subscriptionProducts {
            let card = ProductCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.configure(
                with: product,
                style: .subscription,
                isSelected: product.id == selectedProductId
            )
            card.addTarget(self, action: #selector(handleCardTap(_:)), for: .touchUpInside)

            subscriptionSectionStack.addArrangedSubview(card)
        }
    }

    private func rebuildOneTimeSection() {
        oneTimeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for product in oneTimeProducts {
            let card = OneTimePackCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.widthAnchor.constraint(equalToConstant: 130).isActive = true
            card.heightAnchor.constraint(equalToConstant: 110).isActive = true

            card.configure(
                with: product,
                isSelected: product.id == selectedProductId
            )
            card.addTarget(self, action: #selector(handleCardTap(_:)), for: .touchUpInside)

            oneTimeStack.addArrangedSubview(card)
        }

        let hasOneTime = !oneTimeProducts.isEmpty
        oneTimeScrollView.isHidden = !hasOneTime
        // oneTimeTitleLabel دیگه استفاده نمی‌شه، اگه خواستی می‌تونی کلاً حذفش کنی
    }
    
    // MARK: - Selection / button updates

    private func updateSelectionUI() {
        // Currently sections are rebuilt when selection changes,
        // so there is nothing to update here. Kept for future optimizations.
    }

    private func updatePrimaryButtonTitle() {
        guard let product = (subscriptionProducts + oneTimeProducts).first(where: { $0.id == selectedProductId }) else {
            primaryButton.setTitle("Continue", for: .normal)
            return
        }

        let priceText = ProductCardView.formatPrice(
            cents: product.basePriceCents,
            currencyCode: product.currency
        )

        let periodText: String
        if let period = product.period?.lowercased() {
            switch period {
            case "weekly":
                periodText = "/ week"
            case "monthly":
                periodText = "/ month"
            case "annually", "yearly":
                periodText = "/ year"
            default:
                periodText = ""
            }
        } else {
            periodText = ""
        }

        let buttonTitle: String
        if let subject = product.subject, !subject.isEmpty {
            buttonTitle = "Get \(subject) for \(priceText) \(periodText)"
        } else {
            buttonTitle = "Get \(product.title) for \(priceText) \(periodText)"
        }

        primaryButton.setTitle(buttonTitle.trimmingCharacters(in: .whitespaces), for: .normal)
    }
    
    // MARK: - Loading state

    public func setPrimaryButtonLoading(_ isLoading: Bool) {
        if isLoading {
            primaryButton.isEnabled = false
            primaryButtonSpinner.startAnimating()
            primaryButton.alpha = 0.8
        } else {
            primaryButton.isEnabled = true
            primaryButtonSpinner.stopAnimating()
            primaryButton.alpha = 1.0
        }
    }

    // MARK: - Actions

    @objc
    private func handleCardTap(_ sender: UIControl) {
        // لیست عمودی (اشتراک‌ها)
        if let index = subscriptionSectionStack.arrangedSubviews.firstIndex(where: { $0 === sender }),
           index < subscriptionProducts.count {
            let product = subscriptionProducts[index]
            selectedProductId = product.id
            onProductSelected?(product)
            rebuildSubscriptionSection()
            rebuildOneTimeSection()
            return
        }

        // لیست افقی (پک‌ها)
        if let index = oneTimeStack.arrangedSubviews.firstIndex(where: { $0 === sender }),
           index < oneTimeProducts.count {
            let product = oneTimeProducts[index]
            selectedProductId = product.id
            onProductSelected?(product)
            rebuildSubscriptionSection()
            rebuildOneTimeSection()
            return
        }
    }
    @objc
    private func primaryButtonTapped() {
        let selected = (subscriptionProducts + oneTimeProducts)
            .first(where: { $0.id == selectedProductId })
        onPrimaryButtonTapped?(selected)
    }

    @objc
    private func closeButtonTapped() {
        onCloseTapped?()
    }
}
