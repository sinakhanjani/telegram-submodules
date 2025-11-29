import UIKit
import HonistDesignSystem
import HonistModels

/// View model for a single conversation row.
public struct AiConversationCellViewModel {
    public let title: String
    public let subtitle: String
    public let dateText: String
    public let badgeText: String

    public init(title: String, subtitle: String, dateText: String, badgeText: String) {
        self.title = title
        self.subtitle = subtitle
        self.dateText = dateText
        self.badgeText = badgeText
    }
}

/// Table cell representing one AI conversation (like the screenshot).
public final class AiConversationCell: UITableViewCell {

    public static let reuseIdentifier: String = "AiConversationCell"

    // Left side labels
    private let titleLabel: UILabel = UILabel()
    private let subtitleLabel: UILabel = UILabel()

    // Right side: date + badge
    private let dateLabel: UILabel = UILabel()
    private let badgeContainerView: UIView = UIView()
    private let badgeLabel: UILabel = UILabel()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Setup

    private func commonInit() {
        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainerView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(badgeContainerView)
        badgeContainerView.addSubview(badgeLabel)

        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = DS.Color.text
        titleLabel.numberOfLines = 1

        // Subtitle (max 2 lines)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byTruncatingTail

        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = UIColor.secondaryLabel
        dateLabel.textAlignment = .right

        // Badge
        badgeContainerView.backgroundColor = UIColor.systemBlue
        badgeContainerView.layer.cornerRadius = 12
        badgeContainerView.layer.masksToBounds = true

        badgeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center

        let verticalPadding: CGFloat = 8

        NSLayoutConstraint.activate([
            // Date label top-right
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalPadding),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Badge under date
            badgeContainerView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 6),
            badgeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            badgeContainerView.heightAnchor.constraint(equalToConstant: 24),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainerView.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainerView.trailingAnchor, constant: -8),
            badgeLabel.topAnchor.constraint(equalTo: badgeContainerView.topAnchor, constant: 2),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainerView.bottomAnchor, constant: -2),

            // Title on the left
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -8),

            // Subtitle under title
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalPadding),
        ])
    }

    // MARK: - Configure

    public func configure(with viewModel: AiConversationCellViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        dateLabel.text = viewModel.dateText
        badgeLabel.text = viewModel.badgeText
    }
}

