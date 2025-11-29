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
        self.setupNavigationItems()

        configureTableView()
        configureEmptyState()

        loadConversations()
    }

    // MARK: - Setup

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

    // MARK: - Navigation Items

    private func setupNavigationItems() {
        // System 'new message' icon (compose)
        let composeItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapCompose))

        // Ensure compose is the first (rightmost) item.
        // If there are existing rightBarButtonItems from base or elsewhere, prepend compose.
        var currentItems = self.navigationItem.rightBarButtonItems ?? []
        // Avoid duplicates if setup is called multiple times
        if !currentItems.contains(where: { ($0.target === self) && ($0.action == #selector(didTapCompose)) }) {
            currentItems.insert(composeItem, at: 0)
        }
        self.navigationItem.rightBarButtonItems = currentItems
    }

    @objc
    private func didTapCompose() {
        // Placeholder for future implementation
        // e.g., trigger starting a new conversation flow
        onStartNewChat?()
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

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < filteredConversations.count else { return }
        let convo = filteredConversations[indexPath.row]
        onConversationSelected?(convo)
    }
}

