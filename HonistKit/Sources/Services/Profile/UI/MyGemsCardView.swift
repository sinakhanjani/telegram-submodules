import UIKit
import HonistDesignSystem

final class MyGemsCardView: UIView {

    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private var iconWidthConstraint: NSLayoutConstraint?

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
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.backgroundColor = .clear
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.image = UIImage(named: "ic_gem_my_gems") ?? UIImage(systemName: "diamond.fill")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = DS.Color.text
        titleLabel.text = "My Gems"

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        valueLabel.textColor = DS.Color.text
        valueLabel.textAlignment = .right

        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.numberOfLines = 1

        // Keep title on a single line as well to avoid unexpected wrapping in tight widths
        titleLabel.numberOfLines = 1

        // برای جلوگیری از conflict: اجازه فشرده شدن افقی متن‌ها در عرض‌های تنگ
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
    }

    private func setupLayout() {
        let iconWidth = iconView.widthAnchor.constraint(equalToConstant: 32)
        iconWidth.priority = .defaultHigh
        self.iconWidthConstraint = iconWidth

        let titleLeading = titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12)
        titleLeading.priority = .defaultHigh

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconWidth,
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLeading,
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -8),

            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        // ارتفاع حداقلی کارت
        let minHeight = container.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        minHeight.priority = .defaultHigh
        minHeight.isActive = true
    }

    func configure(currentGems: Int) {
        valueLabel.text = "\(currentGems)"
    }
}
