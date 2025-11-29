import UIKit
import HonistDesignSystem

/// View model for the prompt list cell in Popular segment.
public struct AiPromptCellViewModel {
    public let title: String
    public let snippet: String
    public let gemCost: Int?

    public init(title: String, snippet: String, gemCost: Int?) {
        self.title = title
        self.snippet = snippet
        self.gemCost = gemCost
    }
}

/// Table cell for a single prompt item in Popular segment.
public final class AiPromptCell: UITableViewCell {

    public static let reuseIdentifier: String = "AiPromptCell"

    private let titleLabel: UILabel = UILabel()
    private let snippetLabel: UILabel = UILabel()
    private let badgeContainerView: UIView = UIView()
    private let badgeLabel: UILabel = UILabel()
    private let diamondImageView: UIImageView = UIImageView()

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
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainerView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        diamondImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(snippetLabel)
        contentView.addSubview(badgeContainerView)
        badgeContainerView.addSubview(badgeLabel)
        badgeContainerView.addSubview(diamondImageView)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = DS.Color.text

        snippetLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        snippetLabel.textColor = UIColor.secondaryLabel
        snippetLabel.numberOfLines = 3

        badgeContainerView.layer.cornerRadius = 12
        badgeContainerView.layer.masksToBounds = true
        badgeContainerView.backgroundColor = UIColor.systemBlue

        badgeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = UIColor.white
        badgeLabel.textAlignment = .center

        diamondImageView.image = UIImage(named: "ic_gem_nav")
        diamondImageView.contentMode = .scaleAspectFit

        let spacing: CGFloat = DS.Spacing.md

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeContainerView.leadingAnchor, constant: -spacing),

            badgeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            badgeContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            badgeContainerView.heightAnchor.constraint(equalToConstant: 24),

            badgeLabel.centerYAnchor.constraint(equalTo: badgeContainerView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainerView.leadingAnchor, constant: 8),

            diamondImageView.centerYAnchor.constraint(equalTo: badgeContainerView.centerYAnchor),
            diamondImageView.leadingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 4),
            diamondImageView.trailingAnchor.constraint(equalTo: badgeContainerView.trailingAnchor, constant: -8),
            diamondImageView.widthAnchor.constraint(equalToConstant: 20),
            diamondImageView.heightAnchor.constraint(equalToConstant: 20),

            snippetLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            snippetLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            snippetLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            snippetLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
        ])
    }

    // MARK: - Configure

    public func configure(with viewModel: AiPromptCellViewModel) {
        titleLabel.text = viewModel.title
        snippetLabel.text = viewModel.snippet

        if let gem = viewModel.gemCost, gem > 0 {
            badgeContainerView.isHidden = false
            badgeLabel.text = String(gem)
        } else {
            badgeContainerView.isHidden = true
            badgeLabel.text = nil
        }
    }
}

