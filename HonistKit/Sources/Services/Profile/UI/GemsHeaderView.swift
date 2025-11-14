import UIKit
import HonistDesignSystem

final class GemsHeaderView: UIView {
    
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    private let gemImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let myGemsCard = MyGemsCardView()
    private let sectionTitleLabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    // MARK: - Build
    
    private func build() {
        backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Use layoutMargins on contentView instead of hard insets on inner stack
        contentView.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 12, right: 16)
        contentView.preservesSuperviewLayoutMargins = false
        
        // Stack
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .zero
        
        contentView.addSubview(stackView)
        
        let top = stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor)
        let leading = stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        let trailing = stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        trailing.priority = .defaultHigh
        let bottom = stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
        
        // Gem image در کانتینر وسط چین
        let gemContainer = UIView()
        gemContainer.translatesAutoresizingMaskIntoConstraints = false
        
        gemImageView.translatesAutoresizingMaskIntoConstraints = false
        gemImageView.contentMode = .scaleAspectFit
        gemImageView.image = UIImage(named: "ic_gem_header") ?? UIImage(systemName: "diamond.fill")
        gemImageView.tintColor = .systemTeal
        
        gemContainer.addSubview(gemImageView)
        
        NSLayoutConstraint.activate([
            gemImageView.centerXAnchor.constraint(equalTo: gemContainer.centerXAnchor),
            gemImageView.topAnchor.constraint(equalTo: gemContainer.topAnchor),
            gemImageView.bottomAnchor.constraint(equalTo: gemContainer.bottomAnchor),
            gemImageView.heightAnchor.constraint(equalToConstant: 72),
            gemImageView.widthAnchor.constraint(equalTo: gemImageView.heightAnchor)
        ])
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Gems"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = DS.Color.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.text =
        "Gems are the virtual currency of HonistAi, enabling you to interact with AI chatbots, use the image generator, or convert them into cryptocurrency; it's where your social engagement meets tangible rewards!"
        
        // Prefer text to compress horizontally if needed
        [titleLabel, descriptionLabel, sectionTitleLabel].forEach { label in
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        
        // My Gems card
        myGemsCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Allow card to shrink horizontally under tight widths
        myGemsCard.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        myGemsCard.setContentHuggingPriority(.defaultLow, for: .horizontal)
        myGemsCard.preservesSuperviewLayoutMargins = true
        
        // Section title
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionTitleLabel.text = "HOW TO GET GEMS"
        sectionTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        sectionTitleLabel.textColor = .secondaryLabel
        sectionTitleLabel.textAlignment = .left
        sectionTitleLabel.numberOfLines = 1
        
        // چیدن داخل stack
        stackView.addArrangedSubview(gemContainer)
        stackView.setCustomSpacing(16, after: gemContainer)
        stackView.addArrangedSubview(infoStack)
        stackView.setCustomSpacing(20, after: infoStack)
        stackView.addArrangedSubview(myGemsCard)
        stackView.setCustomSpacing(24, after: myGemsCard)
        stackView.addArrangedSubview(sectionTitleLabel)
        
        // Improve vertical stability
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    // MARK: - Public
    
    func configure(currentGems: Int) {
        myGemsCard.configure(currentGems: currentGems)
    }
}

