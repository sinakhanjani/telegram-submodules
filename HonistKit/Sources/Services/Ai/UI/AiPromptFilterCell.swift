import UIKit
import HonistDesignSystem

/// View model for filter chips in the Popular segment.
public struct AiPromptFilterViewModel {
    public let title: String
    public let badgeText: String
    
    public init(title: String, badgeText: String) {
        self.title = title
        self.badgeText = badgeText
    }
}

/// Collection cell representing a single filter (e.g. "All 99+", "General 10").
public final class AiPromptFilterCell: UICollectionViewCell {

    public static let reuseIdentifier: String = "AiPromptFilterCell"

    // Chip container (the pill that gets colored on selection)
    private let chipView: UIView = UIView()

    private let titleLabel: UILabel = UILabel()
    private let badgeContainerView: UIView = UIView()
    private let badgeLabel: UILabel = UILabel()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Setup

    private func commonInit() {
        // Cell background stays clear; only chipView is colored
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        chipView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainerView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(chipView)
        chipView.addSubview(titleLabel)
        chipView.addSubview(badgeContainerView)
        badgeContainerView.addSubview(badgeLabel)

        // Chip styling
        chipView.layer.cornerRadius = 13
        chipView.layer.masksToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        badgeContainerView.layer.cornerRadius = 8
        badgeContainerView.layer.masksToBounds = true

        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textAlignment = .center

        let horizontalPadding: CGFloat = 10
        let chipHeight: CGFloat = 26

        NSLayoutConstraint.activate([
            // Chip now hugs the contentView horizontally → کمتر شدن فاصله بین سلول‌ها
            chipView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chipView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chipView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chipView.heightAnchor.constraint(equalToConstant: chipHeight),

            titleLabel.leadingAnchor.constraint(equalTo: chipView.leadingAnchor, constant: horizontalPadding),
            titleLabel.centerYAnchor.constraint(equalTo: chipView.centerYAnchor),

            badgeContainerView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
            badgeContainerView.trailingAnchor.constraint(equalTo: chipView.trailingAnchor, constant: -horizontalPadding),
            badgeContainerView.centerYAnchor.constraint(equalTo: chipView.centerYAnchor),
            badgeContainerView.heightAnchor.constraint(equalToConstant: 16),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainerView.leadingAnchor, constant: 5),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainerView.trailingAnchor, constant: -5),
            badgeLabel.topAnchor.constraint(equalTo: badgeContainerView.topAnchor, constant: 1),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainerView.bottomAnchor, constant: -1),
        ])

        updateColors(selected: isSelected)
    }
    
    // MARK: - State

    public override var isSelected: Bool {
        didSet {
            updateColors(selected: isSelected)
        }
    }

    public func updateColors(selected: Bool) {
        if selected {
            chipView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
            titleLabel.textColor = UIColor.systemBlue
            badgeContainerView.backgroundColor = UIColor.systemBlue
            badgeLabel.textColor = UIColor.white
        } else {
            chipView.backgroundColor = UIColor.clear
            titleLabel.textColor = DS.Color.text
            badgeContainerView.backgroundColor = UIColor.secondarySystemBackground
            badgeLabel.textColor = UIColor.secondaryLabel
        }
    }

    // MARK: - Configure

    public func configure(with viewModel: AiPromptFilterViewModel) {
        titleLabel.text = viewModel.title
        badgeLabel.text = viewModel.badgeText
    }
}

