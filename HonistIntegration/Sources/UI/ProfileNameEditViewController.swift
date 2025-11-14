// Services/Profile/UI/ProfileNameEditViewController.swift

import UIKit
import HonistKit

/// Glassy popup for editing first & last name.
/// - Uses blur background
/// - Works in portrait & landscape with adaptive width
/// - Calls ProfileLogic.updateName on confirm.
public final class ProfileNameEditViewController: UIViewController {
    
    private let rootView = ProfileNameEditView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let dimView = UIView()
    
    private var cardCenterYConstraint: NSLayoutConstraint!
    private var cardHeightConstraint: NSLayoutConstraint!
    private var rootWidthConstraint: NSLayoutConstraint?
    
    private let logic: ProfileLogic
    private let initialFirstName: String?
    private let initialLastName: String?
    
    public var onNameUpdated: ((UserDTO) -> Void)?

    private var isSubmitting = false {
        didSet { rootView.setLoading(isSubmitting) }
    }
    
    // MARK: - Init
    
    public init(
        logic: ProfileLogic = ProfileLogic(),
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.logic = logic
        self.initialFirstName = firstName
        self.initialLastName = lastName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        definesPresentationContext = true
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        bindActions()
        
        // Prefill with current values if provided
        rootView.setInitialValues(
            firstName: initialFirstName ?? "",
            lastName: initialLastName ?? ""
        )
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Focus first name field initially
        rootView.firstNameField.becomeFirstResponder()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWidthForOrientation()
    }
    
    // MARK: - UI
    
    private func buildUI() {
        view.backgroundColor = .clear
        
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
        
        // Horizontal: 12pt margins in portrait, overridable in landscape
        let lead = rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        lead.priority = .defaultHigh
        
        let trail = rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        trail.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            lead,
            trail,
            rootView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        // Height ~35% of screen
        cardHeightConstraint = rootView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35)
        cardHeightConstraint.isActive = true
        
        // Slightly below vertical center in portrait
        cardCenterYConstraint = rootView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40)
        cardCenterYConstraint.isActive = true
    }
    
    private func bindActions() {
        rootView.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        rootView.onConfirm = { [weak self] first, last in
            self?.submit(firstName: first, lastName: last)
        }
    }
    
    // MARK: - Orientation width logic
    
    private func updateWidthForOrientation() {
        let isLandscape = view.bounds.width > view.bounds.height
        
        if isLandscape {
            // Fixed width based on shorter side
            let target = max(min(view.bounds.width, view.bounds.height) - 24, 320)
            if rootWidthConstraint == nil {
                rootWidthConstraint = rootView.widthAnchor.constraint(equalToConstant: target)
            }
            rootWidthConstraint?.constant = target
            rootWidthConstraint?.isActive = true
            
            // Attach to top in landscape
            cardCenterYConstraint.isActive = false
            cardCenterYConstraint = rootView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: -8
            )
            cardCenterYConstraint.isActive = true
        } else {
            // Portrait: rely on horizontal constraints with margins
            rootWidthConstraint?.isActive = false
            
            cardCenterYConstraint.isActive = false
            cardCenterYConstraint = rootView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: 40
            )
            cardCenterYConstraint.isActive = true
        }
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Submit
    
    private func submit(firstName: String, lastName: String) {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedFirst.isEmpty else {
            showInlineAlert("Please enter your first name.")
            return
        }
        
        isSubmitting = true
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let userDTO = try await self.logic.updateName(
                    firstName: trimmedFirst,
                    lastName: trimmedLast
                )
                
                await MainActor.run {
                    self.onNameUpdated?(userDTO)
                    self.dismiss(animated: true)
                }
            } catch {
                let msg = (error as? HonistError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.showInlineAlert(msg)
                }
            }
            await MainActor.run {
                self.isSubmitting = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showInlineAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
