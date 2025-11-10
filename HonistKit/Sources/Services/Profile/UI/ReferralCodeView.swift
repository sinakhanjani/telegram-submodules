import UIKit
import HonistUIComponents
import HonistDesignSystem

/// Pure view for referral input; no networking here.
/// Controller injects actions via closure/delegate.
public final class ReferralCodeView: UIView, UITextFieldDelegate {

    // MARK: - Public UI
    public let cancelButton = UIButton(type: .system)
    public let doneButton = UIButton(type: .system)
    public let titleLabel = UILabel()

    public let textField = HonistFilledTextField()
    public let confirmButton = HonistPrimaryButton()

    /// Container card (edge-to-edge width, rounded=0 for bar-like look)
    public let cardView = UIView()

    /// Called when user taps confirm/done or presses return
    public var onConfirm: ((String) -> Void)?
    /// Called when user taps cancel
    public var onCancel: (() -> Void)?

    // MARK: - Private
    private let contentStack = UIStackView()   // vertical stack inside card
    private let headerView = UIView()          // custom header to center title perfectly

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    private func build() {
        backgroundColor = .clear

        // --- Card (popup) ---
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = DS.Color.background
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true

        // --- Header (Cancel | Title(center) | Done) ---
        headerView.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Enter Referral Code"
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

            // Title perfectly centered
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            // Avoid overlap with buttons
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cancelButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: doneButton.leadingAnchor, constant: -8),
        ])

        // --- Field + Button ---
        textField.placeholder = "Referral Code"
        textField.delegate = self
        textField.accessibilityIdentifier = "referral_textfield"

        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.accessibilityIdentifier = "referral_confirm_button"
        confirmButton.addTarget(self, action: #selector(onConfirmTap), for: .touchUpInside)

        // --- Content stack inside card ---
        contentStack.axis = .vertical
        contentStack.spacing = DS.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardView)
        cardView.addSubview(contentStack)

        contentStack.addArrangedSubview(headerView)
        contentStack.setCustomSpacing(DS.Spacing.md * 1.2, after: headerView)
        contentStack.addArrangedSubview(textField)
        contentStack.setCustomSpacing(DS.Spacing.md * 1.5, after: textField)
        contentStack.addArrangedSubview(confirmButton)

        NSLayoutConstraint.activate([
            // Edge-to-edge horizontally
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            confirmButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])

        // Actions
        cancelButton.addTarget(self, action: #selector(onCancelTap), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(onDoneTap), for: .touchUpInside)
    }

    @objc private func onCancelTap() { onCancel?() }
    @objc private func onDoneTap()   { onConfirmTap() }

    @objc private func onConfirmTap() {
        // Keep keyboard open; do NOT resign
        let code = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        onConfirm?(code)
    }

    // Enforce ASCII & length while typing
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        guard string.canBeConverted(to: .ascii) else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        if string.rangeOfCharacter(from: allowed.inverted) != nil { return false }

        let current = textField.text ?? ""
        if let r = Range(range, in: current) {
            let newStr = current.replacingCharacters(in: r, with: string)
            return newStr.count <= 64
        }
        return true
    }

    /// Loading visual
    public func setLoading(_ loading: Bool) {
        confirmButton.setLoading(loading)
        cancelButton.isEnabled = !loading
        doneButton.isEnabled = !loading
        textField.isEnabled = !loading

        UIView.animate(withDuration: 0.2) {
            self.textField.alpha = loading ? 0.6 : 1.0
            self.cardView.alpha = loading ? 0.97 : 1.0
        }
    }
}
