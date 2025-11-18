import UIKit
 import HonistModels
 import HonistDesignSystem

// MARK: - Internal assets

private enum ProAssets {
    static let headerImageName = "honist_pro_header"          // TODO: add to Assets
    static let featureChatIconName = "honist_pro_feature_chat"
    static let featureModelsIconName = "honist_pro_feature_models"
    static let featureImagesIconName = "honist_pro_feature_images"
    static let featureFilesIconName = "honist_pro_feature_files"
}

// MARK: - Bullet row for features ("Unlimited chat messages", ...)

public final class ProFeatureRowView: UIView {

    private let iconView = UIImageView()
    private let label = UILabel()

    init(iconName: String?, systemFallback: String, text: String) {
        super.init(frame: .zero)
        setup(iconName: iconName, systemFallback: systemFallback, text: text)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(iconName: nil, systemFallback: "circle.fill", text: "")
    }

    private func setup(iconName: String?, systemFallback: String, text: String) {
        translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        if let name = iconName, let img = UIImage(named: name) {
            iconView.image = img
        } else {
            iconView.image = UIImage(systemName: systemFallback)
        }
        iconView.tintColor = .white

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(white: 1.0, alpha: 0.9)
        label.numberOfLines = 2
        label.text = text

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Root view

/// Root view for "Get PRO Access" paywall.

/// Root view for "Get PRO Access" paywall.
public final class ProAccessPaywallView: UIView {

    // MARK: - Public callbacks

    public var onProductSelected: ((ProductDTO) -> Void)?
    public var onPrimaryButtonTapped: ((ProductDTO?) -> Void)?
    public var onCloseTapped: (() -> Void)?

    // MARK: - Private state

    private var products: [ProductDTO] = []
    private var selectedProductId: String? {
        didSet {
            updateProductSelectionUI()
            updatePrimaryButtonTitle()
        }
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let featuresStack = UIStackView()
    private let productsStack = UIStackView()

    private let primaryButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private let primaryButtonSpinner = UIActivityIndicatorView(style: .medium) // 👈 اضافه شد

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
        // ثابت مثل اسکرین، نه وابسته به دارک/لایت
        backgroundColor = UIColor(
            red: 27/255,
            green: 35/255,
            blue: 49/255,
            alpha: 1.0
        )

        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80)
        ])

        // Content stack
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

        // Header image
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFit
        headerImageView.image = UIImage(named: ProAssets.headerImageName) ??
            UIImage(systemName: "person.circle.fill")
        headerImageView.tintColor = .white

        headerContainer.addSubview(headerImageView)

        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerImageView.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            headerImageView.heightAnchor.constraint(equalTo: headerContainer.widthAnchor, multiplier: 0.5),
            headerImageView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])

        // Close button در گوشه بالا
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        closeButton.layer.cornerRadius = 14
        closeButton.clipsToBounds = true
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        headerContainer.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 4),
            closeButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -4),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        contentStack.addArrangedSubview(headerContainer)

        // Title "Get PRO Access"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        let titleText = "Get PRO Access"
        let attributed = NSMutableAttributedString(string: titleText)
        if let range = titleText.range(of: "PRO") {
            let nsRange = NSRange(range, in: titleText)
            attributed.addAttributes([
                .foregroundColor: UIColor.systemBlue
            ], range: nsRange)
        }
        attributed.addAttributes([
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.white
        ], range: NSRange(location: 0, length: titleText.count))

        titleLabel.attributedText = attributed

        // Subtitle under title
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = UIColor(white: 1.0, alpha: 0.85)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Upgrade to unlock more powerful features."

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 6

        contentStack.addArrangedSubview(titleStack)

        // Features list
        featuresStack.axis = .vertical
        featuresStack.spacing = 8
        featuresStack.translatesAutoresizingMaskIntoConstraints = false

        let feature1 = ProFeatureRowView(
            iconName: ProAssets.featureChatIconName,
            systemFallback: "message.fill",
            text: "Unlimited chat messages"
        )
        let feature2 = ProFeatureRowView(
            iconName: ProAssets.featureModelsIconName,
            systemFallback: "brain.head.profile",
            text: "Latest AI models"
        )
        let feature3 = ProFeatureRowView(
            iconName: ProAssets.featureImagesIconName,
            systemFallback: "photo.on.rectangle",
            text: "Infinite image generations"
        )
        let feature4 = ProFeatureRowView(
            iconName: ProAssets.featureFilesIconName,
            systemFallback: "doc.text.magnifyingglass",
            text: "File & URL summaries"
        )

        [feature1, feature2, feature3, feature4].forEach { featuresStack.addArrangedSubview($0) }

        contentStack.addArrangedSubview(featuresStack)

        // Products stack (Vertical)
        productsStack.axis = .vertical
        productsStack.spacing = 8
        productsStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(productsStack)

        // Primary button at bottom
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.layer.cornerRadius = 12
        primaryButton.clipsToBounds = true
        primaryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.backgroundColor = UIColor.systemBlue
        primaryButton.setTitle("Continue", for: .normal)
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)

        addSubview(primaryButton)

        NSLayoutConstraint.activate([
            primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            primaryButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        // 👇 Spinner روی خود دکمه
        primaryButtonSpinner.translatesAutoresizingMaskIntoConstraints = false
        primaryButtonSpinner.hidesWhenStopped = true
        primaryButton.addSubview(primaryButtonSpinner)

        NSLayoutConstraint.activate([
            primaryButtonSpinner.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
            primaryButtonSpinner.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor)
        ])
    }

    // MARK: - Public config

    /// Configure view with list of subscription products.
    /// - Parameters:
    ///   - products: list of ProductDTO (weekly, yearly, ...)
    ///   - selectedProductId: initial selected id
    public func configure(
        products: [ProductDTO],
        selectedProductId: String?
    ) {
        self.products = products
        self.selectedProductId = selectedProductId ?? products.first?.id

        rebuildProductsSection()
        updatePrimaryButtonTitle()
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

    // MARK: - Products UI

    private func rebuildProductsSection() {
        productsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, product) in products.enumerated() {
            let row = ProProductRowView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 74).isActive = true

            let isSelected = (product.id == selectedProductId)
            // منطق Best Offer: محصول popular یا اولین محصول در صورت نبودن popular
            let isBestOffer: Bool
            if product.isPopular {
                isBestOffer = true
            } else {
                isBestOffer = (index == 0 && !products.contains(where: { $0.isPopular }))
            }

            row.configure(
                with: product,
                isSelected: isSelected,
                isBestOffer: isBestOffer
            )

            row.addTarget(self,
                          action: #selector(handleRowTap(_:)),
                          for: .touchUpInside)

            productsStack.addArrangedSubview(row)
        }
    }

    @objc
    private func handleRowTap(_ sender: UIControl) {
        guard
            let index = productsStack.arrangedSubviews.firstIndex(where: { $0 === sender }),
            index < products.count
        else { return }

        let product = products[index]

        // ۱) انتخاب داخلی
        selectedProductId = product.id

        // ۲) اطلاع دادن به کنترلر
        onProductSelected?(product)
    }

    private func updateProductSelectionUI() {
        for (index, view) in productsStack.arrangedSubviews.enumerated() {
            guard
                let row = view as? ProProductRowView,
                index < products.count
            else { continue }

            let product = products[index]
            let isSelected = (product.id == selectedProductId)
            let isBestOffer = product.isPopular ||
                (index == 0 && !products.contains(where: { $0.isPopular }))

            row.configure(with: product,
                          isSelected: isSelected,
                          isBestOffer: isBestOffer)
        }
    }

    private func updatePrimaryButtonTitle() {
        guard let selected = products.first(where: { $0.id == selectedProductId }) else {
            primaryButton.setTitle("Continue", for: .normal)
            return
        }

        primaryButton.setTitle(selected.title, for: .normal)
    }

    // MARK: - Actions

    @objc
    private func primaryButtonTapped() {
        let selected = products.first { $0.id == selectedProductId }
        onPrimaryButtonTapped?(selected)
    }

    @objc
    private func closeButtonTapped() {
        onCloseTapped?()
    }
}
