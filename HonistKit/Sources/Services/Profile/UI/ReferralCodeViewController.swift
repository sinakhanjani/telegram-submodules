import UIKit
import HonistDesignSystem
import HonistFoundation

/// Glassy popup slightly above center; background visible via blur.
/// Keyboard stays up; errors are shown via UIAlertController.
public final class ReferralCodeViewController: UIViewController {

    private let rootView = ReferralCodeView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let dimView = UIView()

    private var cardCenterYConstraint: NSLayoutConstraint!
    private var cardHeightConstraint: NSLayoutConstraint!

    // NEW: width constraint used only in landscape
    private var rootWidthConstraint: NSLayoutConstraint?

    private let logic: ProfileLogic
    private var isSubmitting = false { didSet { rootView.setLoading(isSubmitting) } }

    // MARK: - Init
    public init(logic: ProfileLogic = ProfileLogic()) {
        self.logic = logic
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        definesPresentationContext = true
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        bindActions()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Bring up keyboard immediately and keep it up
        rootView.textField.becomeFirstResponder()
    }

    // Keep portrait/landscape width logic up-to-date on layout changes
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWidthForOrientation()
    }

    // MARK: - UI
    private func buildUI() {
        view.backgroundColor = .clear

        // Fullscreen blur + subtle dim
        blurView.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        rootView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.08)

        view.addSubview(blurView)
        view.addSubview(dimView)
        view.addSubview(rootView)

        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // --- Horizontal constraints (Portrait default: 12pt margins)
        // Use lower priority so fixed width in landscape can override cleanly
        let lead = rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        lead.priority = .defaultHigh // 750

        let trail = rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        trail.priority = .defaultHigh // 750

        NSLayoutConstraint.activate([
            lead, trail,
            rootView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // --- Vertical sizing/positioning (unchanged)
        cardHeightConstraint = rootView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35)
        cardHeightConstraint.isActive = true

        cardCenterYConstraint = rootView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 68)
        cardCenterYConstraint.isActive = true
    }

    private func bindActions() {
        rootView.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        rootView.onConfirm = { [weak self] code in
            self?.submit(code: code)
        }
        // Do NOT add any endEditing to keep keyboard open.
    }

    // MARK: - Orientation width logic
    private func updateWidthForOrientation() {
        let isLandscape = view.bounds.width > view.bounds.height

        if isLandscape {
            // --- Fixed width logic ---
            let target = max(min(view.bounds.width, view.bounds.height) - 24, 320)
            if rootWidthConstraint == nil {
                rootWidthConstraint = rootView.widthAnchor.constraint(equalToConstant: target)
            }
            rootWidthConstraint?.constant = target
            rootWidthConstraint?.isActive = true

            // --- Vertical position adjustment ---
            cardCenterYConstraint.isActive = false
            cardCenterYConstraint = rootView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
            cardCenterYConstraint.isActive = true
        } else {
            // Portrait
            rootWidthConstraint?.isActive = false

            cardCenterYConstraint.isActive = false
            cardCenterYConstraint = rootView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 68)
            cardCenterYConstraint.isActive = true
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Submit
    private func submit(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showInlineAlert("Please enter your referral code.")
            return
        }

        isSubmitting = true
        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await self.logic.submitReferral(code: trimmed)
                await MainActor.run { self.dismiss(animated: true) } // success
            } catch {
                let msg = (error as? HonistError)?.errorDescription ?? error.localizedDescription
                await MainActor.run { self.showInlineAlert(msg) }     // ALERT (keeps keyboard; we don't resign)
            }
            await MainActor.run { self.isSubmitting = false }
        }
    }

    // MARK: - Helpers
    private func showInlineAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
