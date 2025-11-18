import UIKit
 import HonistModels
 import HonistDesignSystem
// MARK: - Product row view (YEARLY ACCESS, WEEKLY ACCESS, ...)

/// Single subscription row, similar to YEARLY / WEEKLY ACCESS in mockup.
public final class ProProductRowView: UIControl {

    // MARK: - UI

    private let cardView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let priceLabel = UILabel()
    private let perPeriodLabel = UILabel()

    private let bestOfferBadge = UILabel()

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
        backgroundColor = .clear

        // Card container
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(
            red: 40/255,
            green: 46/255,
            blue: 60/255,
            alpha: 1.0
        )
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 2
        cardView.layer.borderColor = UIColor.clear.cgColor
        cardView.clipsToBounds = true
        // 🔵 خیلی مهم: تاچ‌ها به خود UIControl برسند نه به cardView
        cardView.isUserInteractionEnabled = false

        addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Left labels
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = UIColor(white: 1.0, alpha: 0.8)
        subtitleLabel.numberOfLines = 1

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 4
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        // Right price labels
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.boldSystemFont(ofSize: 17)
        priceLabel.textColor = .white
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        perPeriodLabel.translatesAutoresizingMaskIntoConstraints = false
        perPeriodLabel.font = UIFont.systemFont(ofSize: 11)
        perPeriodLabel.textColor = UIColor(white: 1.0, alpha: 0.8)
        perPeriodLabel.textAlignment = .right
        perPeriodLabel.numberOfLines = 1

        let rightStack = UIStackView(arrangedSubviews: [priceLabel, perPeriodLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 2
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        // Best offer badge
        bestOfferBadge.translatesAutoresizingMaskIntoConstraints = false
        bestOfferBadge.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        bestOfferBadge.textColor = .white
        bestOfferBadge.backgroundColor = UIColor.systemBlue
        bestOfferBadge.textAlignment = .center
        bestOfferBadge.text = "Best Offer"
        bestOfferBadge.clipsToBounds = true
        bestOfferBadge.layer.cornerRadius = 13
        bestOfferBadge.isHidden = true

        // Main horizontal layout
        let mainRow = UIStackView(arrangedSubviews: [leftStack, rightStack])
        mainRow.axis = .horizontal
        mainRow.alignment = .top
        mainRow.spacing = 12
        mainRow.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(mainRow)
        cardView.addSubview(bestOfferBadge)

        NSLayoutConstraint.activate([
            mainRow.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            mainRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            mainRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            mainRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            // 🔵 Best Offer دقیقاً زیر perPeriodLabel
            bestOfferBadge.topAnchor.constraint(equalTo: perPeriodLabel.bottomAnchor, constant: 4),
            bestOfferBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            bestOfferBadge.heightAnchor.constraint(equalToConstant: 26),
            bestOfferBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            bestOfferBadge.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configuration

    /// Configure row with product DTO.
    /// - Parameters:
    ///   - product: Product data
    ///   - isSelected: draw blue border when true
    ///   - isBestOffer: show "Best Offer" pill
    public func configure(
        with product: ProductDTO,
        isSelected: Bool,
        isBestOffer: Bool
    ) {
        // Left side
        titleLabel.text = product.title.uppercased()
        subtitleLabel.text = product.shortDescription ?? product.subject

        // Right side price
        let priceText = Self.formatPrice(cents: product.basePriceCents, currencyCode: product.currency)
        priceLabel.text = priceText

        if let period = product.period?.lowercased() {
            switch period {
            case "weekly":
                perPeriodLabel.text = "per week"
            case "monthly":
                perPeriodLabel.text = "per month"
            case "annually", "yearly":
                perPeriodLabel.text = "per year"
            default:
                perPeriodLabel.text = nil
            }
        } else {
            perPeriodLabel.text = nil
        }

        // Best offer badge
        bestOfferBadge.isHidden = !isBestOffer

        applySelection(isSelected: isSelected)
    }

    public func setSelected(_ selected: Bool) {
        applySelection(isSelected: selected)
    }

    private func applySelection(isSelected: Bool) {
        cardView.layer.borderColor = isSelected
            ? UIColor.systemBlue.cgColor
            : UIColor.clear.cgColor
    }

    // MARK: - Helpers

    private static func formatPrice(cents: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        return formatter.string(from: amount) ?? "\(amount) \(currencyCode)"
    }
}
