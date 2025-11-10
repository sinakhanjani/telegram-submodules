import UIKit
import HonistDesignSystem

public final class GemsOptionCell: UITableViewCell {
    
    static public let reuseId = "GemsOptionCell"
    
    private let container = UIView()
    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let hStack = UIStackView()
    private let spacer = UIView()
    private let chevronImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    private func build() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true
        
        iconBackground.layer.cornerRadius = 10
        iconBackground.clipsToBounds = true
        iconBackground.backgroundColor = UIColor.clear
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .center
        iconView.tintColor = .white
        iconView.backgroundColor = UIColor.clear
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .vertical)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = DS.Color.text
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        contentView.addSubview(container)
        
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.distribution = .fill

        // Prepare fixed-size icon background and embed iconView
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconBackground.heightAnchor.constraint(equalTo: iconBackground.widthAnchor).isActive = true

        iconBackground.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
        ])

        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        container.addSubview(hStack)
        hStack.addArrangedSubview(iconBackground)
        hStack.addArrangedSubview(titleLabel)
        hStack.addArrangedSubview(spacer)

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        hStack.addArrangedSubview(chevronImageView)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            container.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // Removed the accessoryType = .disclosureIndicator line
    }
    
    public func configure(with model: ViewModel) {
        titleLabel.text = model.title
        iconView.image = UIImage(named: model.iconName) ?? UIImage(systemName: model.systemFallback)
    }
    
    public struct ViewModel {
        public let title: String
        public let iconName: String
        public let systemFallback: String
        public let iconBackgroundColor: UIColor

        public init(
            title: String,
            iconName: String,
            systemFallback: String,
            iconBackgroundColor: UIColor
        ) {
            self.title = title
            self.iconName = iconName
            self.systemFallback = systemFallback
            self.iconBackgroundColor = iconBackgroundColor
        }
    }
}

