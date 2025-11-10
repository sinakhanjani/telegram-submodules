
import UIKit
import HonistDesignSystem

public final class MetricCardView: UIView {
    
    public var onTap: (() -> Void)?
    
    private let container = UIView()
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayout()
        addTapGesture()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
        
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.tintColor = .white
        iconView.backgroundColor = UIColor.systemBlue
        iconView.layer.cornerRadius = 12
        iconView.clipsToBounds = true
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = DS.Color.text
        
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        valueLabel.textColor = DS.Color.text
        
        addSubview(container)
        
        let topRow = UIStackView(arrangedSubviews: [iconView, titleLabel])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        
        let rootStack = UIStackView(arrangedSubviews: [topRow, valueLabel])
        rootStack.axis = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(rootStack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            rootStack.topAnchor.constraint(equalTo: container.topAnchor, constant: DS.Spacing.md),
            rootStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: DS.Spacing.md),
            rootStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -DS.Spacing.md),
            rootStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -DS.Spacing.md),
            
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
        ])
    }
    
    private func setupLayout() { }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    public func configure(title: String, value: String, iconName: String) {
        titleLabel.text = title
        valueLabel.text = value
        // Placeholder asset name; real asset should be added in asset catalog
        iconView.image = UIImage(named: iconName) ?? UIImage(systemName: "circle.fill")
    }
    
    public func updateValue(_ value: String) {
        valueLabel.text = value
    }
    
    @objc
    private func handleTap() {
        onTap?()
    }
}
