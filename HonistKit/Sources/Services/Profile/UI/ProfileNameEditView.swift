// Services/Profile/UI/ProfileNameEditView.swift

import UIKit
import HonistUIComponents
import HonistDesignSystem

/// Pure view for editing first & last name.
/// Controller handles networking via ProfileLogic.
public final class ProfileNameEditView: UIView, UITextFieldDelegate {
    
    // MARK: - Public UI
    
    public let cancelButton = UIButton(type: .system)
    public let doneButton = UIButton(type: .system)
    public let titleLabel = UILabel()
    
    public let firstNameField = HonistFilledTextField()
    public let lastNameField = HonistFilledTextField()
    public let confirmButton = HonistPrimaryButton()
    
    /// Container card (rounded popup)
    public let cardView = UIView()
    
    /// Called when user taps confirm/done or presses return on last field.
    public var onConfirm: ((String, String) -> Void)?
    
    /// Called when user taps cancel.
    public var onCancel: (() -> Void)?
    
    // MARK: - Private
    
    private let contentStack = UIStackView()
    private let headerView = UIView()
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    // MARK: - Build
    
    private func build() {
        backgroundColor = .clear
        
        // Card
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = DS.Color.background
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
        
        // Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "User Info"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = DS.Color.text
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(cancelButton)
        headerView.addSubview(doneButton)
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cancelButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: doneButton.leadingAnchor, constant: -8),
        ])
        
        // Fields
        firstNameField.placeholder = "First name"
        firstNameField.delegate = self
        firstNameField.accessibilityIdentifier = "profile_first_name_field"
        
        lastNameField.placeholder = "Last name"
        lastNameField.delegate = self
        lastNameField.accessibilityIdentifier = "profile_last_name_field"
        
        // Confirm button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.accessibilityIdentifier = "profile_name_save_button"
        confirmButton.addTarget(self, action: #selector(onConfirmTap), for: .touchUpInside)
        
        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = DS.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(cardView)
        cardView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(headerView)
        contentStack.setCustomSpacing(DS.Spacing.md * 1.2, after: headerView)
        contentStack.addArrangedSubview(firstNameField)
        contentStack.addArrangedSubview(lastNameField)
        contentStack.setCustomSpacing(DS.Spacing.md * 1.5, after: lastNameField)
        contentStack.addArrangedSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            firstNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            lastNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            confirmButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
        
        // Actions
        cancelButton.addTarget(self, action: #selector(onCancelTap), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(onDoneTap), for: .touchUpInside)
    }
    
    // MARK: - Public helpers
    
    /// Prefills text fields with current values.
    public func setInitialValues(firstName: String, lastName: String) {
        firstNameField.text = firstName
        lastNameField.text = lastName
    }
    
    /// Loading state visual.
    public func setLoading(_ loading: Bool) {
        confirmButton.setLoading(loading)
        cancelButton.isEnabled = !loading
        doneButton.isEnabled = !loading
        firstNameField.isEnabled = !loading
        lastNameField.isEnabled = !loading
        
        UIView.animate(withDuration: 0.2) {
            self.cardView.alpha = loading ? 0.97 : 1.0
            self.firstNameField.alpha = loading ? 0.6 : 1.0
            self.lastNameField.alpha = loading ? 0.6 : 1.0
        }
    }
    
    // MARK: - Actions
    
    @objc private func onCancelTap() { onCancel?() }
    @objc private func onDoneTap()   { onConfirmTap() }
    
    @objc private func onConfirmTap() {
        let first = (firstNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last  = (lastNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        onConfirm?(first, last)
    }
    
    // MARK: - UITextFieldDelegate
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === firstNameField {
            lastNameField.becomeFirstResponder()
        } else {
            onConfirmTap()
        }
        return true
    }
}
