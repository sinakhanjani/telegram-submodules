import UIKit
import HonistDesignSystem

/// Root view for the list of AI conversations for a given assistant.
/// Shows:
/// - tableView with conversations
/// - or empty state "Start New Chat" when there is no data.
public final class AiConversationsRootView: UIView {

    // MARK: - Public subviews

    public let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    public let emptyStateButton: UIButton = UIButton(type: .system)

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Setup

    private func commonInit() {
        backgroundColor = DS.Color.background

        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
        addSubview(emptyStateButton)

        // Table styling
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        // Empty state button styling
        emptyStateButton.setTitle("Start New Chat", for: .normal)
        emptyStateButton.setTitleColor(.systemBlue, for: .normal)
        emptyStateButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        emptyStateButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        emptyStateButton.tintColor = .systemBlue

        // Small padding for image + title
        emptyStateButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        emptyStateButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)

        NSLayoutConstraint.activate([
            // Table view fills safe area
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 16),

            // Empty state centered
            emptyStateButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Start hidden until data is known
        setEmptyStateVisible(false)
    }

    // MARK: - Public helpers

    /// Shows empty state (and hides table) when there is no data.
    public func setEmptyStateVisible(_ visible: Bool) {
        emptyStateButton.isHidden = !visible
        tableView.isHidden = visible
    }
}
