import UIKit
import HonistDesignSystem
import HonistUIComponents

/// View model for configuring `AiAssistantCell`.
public struct AiAssistantCellViewModel {
    public let name: String
    public let subtitle: String?
    public let avatarUrl: String?
    
    public init(name: String, subtitle: String?, avatarUrl: String?) {
        self.name = name
        self.subtitle = subtitle
        self.avatarUrl = avatarUrl
    }
}

/// Table cell used in the Assistants segment.
public final class AiAssistantCell: UITableViewCell {

    public static let reuseIdentifier: String = "AiAssistantCell"

    private let avatarImageView: UIImageView = UIImageView()
    private let nameLabel: UILabel = UILabel()
    private let subtitleLabel: UILabel = UILabel()
    private let infoButton: UIButton = UIButton(type: .system)

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

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(infoButton)

        // Avatar
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = UIColor.secondarySystemBackground
        avatarImageView.image = UIImage(systemName: "person.circle")

        // Labels
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = DS.Color.text

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 2

        // Info icon (i)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = UIColor.systemBlue
        infoButton.isUserInteractionEnabled = false

        let spacing: CGFloat = DS.Spacing.md

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            infoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: spacing),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -spacing),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
        ])
    }

    // MARK: - Configure

    /// Configures the cell content.
    public func configure(with viewModel: AiAssistantCellViewModel) {
        nameLabel.text = viewModel.name
        subtitleLabel.text = viewModel.subtitle

        // Load avatar
        HonistImageLoader.shared.load(viewModel.avatarUrl, into: avatarImageView)
    }
}
