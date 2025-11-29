import UIKit
import HonistKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext

/// Shows list of AI conversations for a specific assistant.
/// - Data source: AiLogic.listConversations(page:limit:)
/// - Filters by assistantId.
/// - When list is empty, shows "Start New Chat" centered button.
public final class AiConversationsViewController: HonistBaseViewController {

    // MARK: - Public callbacks

    /// Called when user taps "Start New Chat" in empty state.
    internal var onStartNewChat: (() -> Void)?

    /// Called when user selects a specific conversation row.
    internal var onConversationSelected: ((AiConversationDTO) -> Void)?

    // MARK: - Dependencies

    private let logic: AiLogic

    // MARK: - State

    private let rootView = AiConversationsRootView()

    private let assistantId: String
    private let assistantTitle: String

    private var allConversations: [AiConversationDTO] = []
    private var filteredConversations: [AiConversationDTO] = []
    
    // MARK: - Init
    
    /// - Parameter referrals: optional initial list of referrals to display.
    public init(context: AccountContext,
                assistantId: String,
                assistantTitle: String,
                logic: AiLogic = AiLogic()
    ) {
        self.assistantId = assistantId
        self.assistantTitle = assistantTitle
        self.logic = logic
        
        super.init(
             context: context,
             title: assistantTitle,
             hidesBackButton: false
         )
     }

     required init(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

    // MARK: - DisplayNode
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode(viewBlock: { [weak self] in
            let view = UIView()
            if let theme = self?.presentationData.theme {
                view.backgroundColor = theme.rootController.navigationBar.blurredBackgroundColor
            }
            return view
        })
        
        self.displayNodeDidLoad()
    }

    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()

        self.attachRootView(rootView)
        self.updateBaseUI()

        // Setup right bar buttons: [compose, gem]
        var rightItems: [UIBarButtonItem] = []

        if let gemItem = makeGemBarButtonItem() {
            rightItems.append(gemItem)
        }
        if let composeItem = makeComposeBarButtonItem() {
            rightItems.append(composeItem)
        }
        if !rightItems.isEmpty {
            self.navigationItem.rightBarButtonItems = rightItems
        }

        configureTableView()
        configureEmptyState()

        loadConversations()
    }
    
    // MARK: - Setup
    
    /// Builds a compose bar button item using a customDisplayNode
    private func makeComposeBarButtonItem() -> UIBarButtonItem? {
        let node = ASDisplayNode { [weak self] in
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
            button.tintColor = DS.Color.text
            button.addTarget(self, action: #selector(AiConversationsViewController.didTapCompose), for: .touchUpInside)
            return button
        }
        node.style.preferredSize = CGSize(width: 30, height: 30)

        guard let item = UIBarButtonItem(customDisplayNode: node) else {
            return nil
        }
        return item
    }

    private func configureTableView() {
        let tv = rootView.tableView
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 64

        tv.register(
            AiConversationCell.self,
            forCellReuseIdentifier: AiConversationCell.reuseIdentifier
        )
    }

    private func configureEmptyState() {
        rootView.emptyStateButton.addTarget(
            self,
            action: #selector(didTapEmptyStateButton),
            for: .touchUpInside
        )
    }

    // MARK: - Data loading

    private func loadConversations(page: Int = 1, limit: Int = 50) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let payload = try await self.logic.listConversations(page: page, limit: limit)
                self.allConversations = payload.items

                // Filter by assistantId
                self.filteredConversations = self.allConversations.filter { $0.assistantId == self.assistantId }

                DispatchQueue.main.async {
                    let isEmpty = self.filteredConversations.isEmpty
                    self.rootView.setEmptyStateVisible(isEmpty)
                    self.rootView.tableView.reloadData()
                }
            } catch {
                // TODO: Replace with proper error UI
                print("Failed to load conversations:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.filteredConversations = []
                    self.rootView.setEmptyStateVisible(true)
                    self.rootView.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Actions
    
    @objc
    private func didTapCompose() {
        // Placeholder for future implementation
        // e.g., trigger starting a new conversation flow
        onStartNewChat?()
    }

    @objc
    private func didTapEmptyStateButton() {
        //
        onStartNewChat?()
    }

    // MARK: - Helpers

    /// Returns a short date string:
    /// - If within last 7 days: weekday ("Mon", "Tue", ...)
    /// - Otherwise: month + day ("Sep 3").
    private func formattedDateString(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current

        if let days = calendar.dateComponents([.day], from: date, to: now).day,
           days >= 0, days < 7 {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "EEE" // e.g. Mon, Tue, Wed
            return fmt.string(from: date)
        } else {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "MMM d" // e.g. Sep 3
            return fmt.string(from: date)
        }
    }

    /// Builds the view model for a specific conversation row.
    private func makeViewModel(for conversation: AiConversationDTO) -> AiConversationCellViewModel {
        // Title: use conversation.title or assistant name as fallback
        let title: String = {
            if let raw = conversation.title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                return raw
            } else {
                return assistantTitle
            }
        }()

        // Subtitle: lastMessage or empty
        let subtitle = conversation.lastMessage ?? ""

        // Date: based on createdAt as requested
        let dateText = formattedDateString(from: conversation.createdAt)

        // Badge: totalMessages
        let badgeText = "\(conversation.totalMessages)"

        return AiConversationCellViewModel(
            title: title,
            subtitle: subtitle,
            dateText: dateText,
            badgeText: badgeText
        )
    }
}

// MARK: - UITableViewDataSource

extension AiConversationsViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredConversations.count
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AiConversationCell.reuseIdentifier,
            for: indexPath
        ) as! AiConversationCell

        let conversation = filteredConversations[indexPath.row]
        let vm = makeViewModel(for: conversation)
        cell.selectionStyle = .none
        cell.configure(with: vm)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AiConversationsViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Disable touch-down highlight effect
        return false
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < filteredConversations.count else { return nil }
        let convo = filteredConversations[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }

            // Ask for confirmation
            let alert = UIAlertController(title: nil, message: NSLocalizedString("Are you sure you want to delete this conversation?", comment: "Delete confirmation"), preferredStyle: .actionSheet)

            let confirm = UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive) { [weak self] _ in
                guard let self else { completion(false); return }

                // Optimistically disable interaction for the row
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.isUserInteractionEnabled = false
                }

                Task { [weak self] in
                    guard let self else { completion(false); return }
                    do {
                        try await self.logic.deleteConversation(conversationId: convo.id)

                        // Update data sources
                        if let idxAll = self.allConversations.firstIndex(where: { $0.id == convo.id }) {
                            self.allConversations.remove(at: idxAll)
                        }
                        // Rebuild filtered list from allConversations to stay consistent
                        self.filteredConversations = self.allConversations.filter { $0.assistantId == self.assistantId }

                        await MainActor.run {
                            // Delete the row if still visible
                            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
                                tableView.performBatchUpdates({
                                    tableView.deleteRows(at: [indexPath], with: .automatic)
                                }, completion: { _ in })
                            } else {
                                tableView.reloadData()
                            }
                            let isEmpty = self.filteredConversations.isEmpty
                            self.rootView.setEmptyStateVisible(isEmpty)
                            completion(true)
                        }
                    } catch {
                        // TODO: show error UI if needed
                        await MainActor.run {
                            if let cell = tableView.cellForRow(at: indexPath) {
                                cell.isUserInteractionEnabled = true
                            }
                            completion(false)
                        }
                    }
                }
            }

            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { _ in
                completion(false)
            }

            alert.addAction(confirm)
            alert.addAction(cancel)

            // For iPad actionSheet popover anchor
            if let popover = alert.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }

            self.present(alert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < filteredConversations.count else { return }
        let convo = filteredConversations[indexPath.row]
        onConversationSelected?(convo)
    }
}

