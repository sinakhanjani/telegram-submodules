import UIKit
import HonistKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext

/// Main controller for the AI Assistants screen.
/// - Segment "Assistants": shows list of AiAssistantDTO
/// - Segment "Popular": shows prompt filters and list of prompts grouped by assistant.
public final class AiAssistantsViewController: HonistBaseViewController {

    // MARK: - Types

    private enum Segment: Int {
        case assistants = 0
        case popular = 1
    }

    private struct PromptFilterItem {
        /// nil means "All"
        let assistantId: String?
        let title: String
        let count: Int
    }

    // MARK: - Public callbacks

    /// Called when user selects an assistant cell.
    internal var onAssistantSelected: ((AiAssistantDTO) -> Void)?

    /// Called when user selects a prompt cell.
    internal var onPromptSelected: ((AiPromptDTO) -> Void)?

    // MARK: - Dependencies

    private let logic: AiLogic

    // MARK: - State

    private let rootView = AiAssistantsRootView()

    private var currentSegment: Segment = .assistants {
        didSet {
            updateSegmentUI()
        }
    }

    private var assistants: [AiAssistantDTO] = []
    private var allPrompts: [AiPromptDTO] = []

    private var promptFilters: [PromptFilterItem] = []
    private var selectedFilterIndex: Int = 0 {
        didSet {
            applySelectedFilter()
        }
    }

    private var visiblePrompts: [AiPromptDTO] = []
    
    // MARK: - Init
    
    /// - Parameter referrals: optional initial list of referrals to display.
    public init(context: AccountContext) {
        self.logic = AiLogic()
         super.init(
             context: context,
             title: "Assistants",
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
        
        configureSegmentedControl()
        configureCollectionView()
        configureTableView()

        rootView.setFiltersVisible(false, animated: false)

        loadAssistants()
        loadPrompts()
    }

    // MARK: - Configuration

    private func configureSegmentedControl() {
        rootView.segmentedControl.addTarget(
            self,
            action: #selector(segmentChanged(_:)),
            for: .valueChanged
        )
    }

    private func configureCollectionView() {
        let cv = rootView.filtersCollectionView
        cv.dataSource = self
        cv.delegate = self

        cv.register(
            AiPromptFilterCell.self,
            forCellWithReuseIdentifier: AiPromptFilterCell.reuseIdentifier
        )
    }

    private func configureTableView() {
        let tv = rootView.tableView
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 64
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine

        tv.register(
            AiAssistantCell.self,
            forCellReuseIdentifier: AiAssistantCell.reuseIdentifier
        )
        tv.register(
            AiPromptCell.self,
            forCellReuseIdentifier: AiPromptCell.reuseIdentifier
        )
    }

    // MARK: - Loading data

    private func loadAssistants() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.logic.loadAssistants()
                self.assistants = result
                DispatchQueue.main.async {
                    if self.currentSegment == .assistants {
                        self.rootView.tableView.reloadData()
                    }
                }
            } catch {
                // TODO: Show error UI if needed
                print("Failed to load assistants:", error.localizedDescription)
            }
        }
    }

    private func loadPrompts() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.logic.loadPrompts()
                self.allPrompts = result
                self.buildPromptFilters(from: result)
                DispatchQueue.main.async {
                    if self.currentSegment == .popular {
                        self.rootView.filtersCollectionView.reloadData()
                        self.rootView.tableView.reloadData()
                    }
                }
            } catch {
                // TODO: Show error UI if needed
                print("Failed to load prompts:", error.localizedDescription)
            }
        }
    }

    // MARK: - Prompt filters building

    private func buildPromptFilters(from prompts: [AiPromptDTO]) {
        guard !prompts.isEmpty else {
            promptFilters = []
            visiblePrompts = []
            return
        }

        // 1) "All" item
        var filters: [PromptFilterItem] = [
            PromptFilterItem(
                assistantId: nil,
                title: "All",
                count: prompts.count
            ),
        ]

        // 2) Group by assistant id
        var grouped: [String: [AiPromptDTO]] = [:]
        for prompt in prompts {
            let key = prompt.assistantId
            grouped[key, default: []].append(prompt)
        }

        // 3) Create filter item for each assistant group
        //    Sorted by assistant name for stable UI.
        let sortedGroups = grouped
            .sorted { lhs, rhs in
                let lhsName = lhs.value.first?.assistant.name ?? ""
                let rhsName = rhs.value.first?.assistant.name ?? ""
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }

        for (assistantId, items) in sortedGroups {
            guard let first = items.first else { continue }
            let title = first.assistant.name
            filters.append(
                PromptFilterItem(
                    assistantId: assistantId,
                    title: title,
                    count: items.count
                )
            )
        }

        promptFilters = filters
        selectedFilterIndex = 0
        visiblePrompts = prompts
    }

    private func applySelectedFilter() {
        guard !allPrompts.isEmpty else {
            visiblePrompts = []
            rootView.tableView.reloadData()
            return
        }
        guard selectedFilterIndex < promptFilters.count else { return }
        let filter = promptFilters[selectedFilterIndex]

        if let assistantId = filter.assistantId {
            visiblePrompts = allPrompts.filter { $0.assistantId == assistantId }
        } else {
            visiblePrompts = allPrompts
        }

        rootView.tableView.reloadData()
    }

    // MARK: - Segment handling

    @objc
    private func segmentChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let newSegment = Segment(rawValue: index) ?? .assistants
        currentSegment = newSegment
    }

    private func updateSegmentUI() {
        switch currentSegment {
        case .assistants:
            rootView.setFiltersVisible(false, animated: true)
            title = "Assistants"
        case .popular:
            rootView.setFiltersVisible(true, animated: true)
            title = "Assistants"
        }

        rootView.tableView.reloadData()
        rootView.filtersCollectionView.reloadData()

        // انتخاب پیش‌فرض فیلتر All وقتی به popular می‌رویم
        if currentSegment == .popular && !promptFilters.isEmpty {
            selectedFilterIndex = 0
            let indexPath = IndexPath(item: 0, section: 0)
            rootView.filtersCollectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .left
            )
        }
    }
}

// MARK: - UITableViewDataSource

extension AiAssistantsViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentSegment {
        case .assistants:
            return assistants.count
        case .popular:
            return visiblePrompts.count
        }
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch currentSegment {
        case .assistants:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AiAssistantCell.reuseIdentifier,
                for: indexPath
            ) as! AiAssistantCell

            let assistant = assistants[indexPath.row]
            let vm = AiAssistantCellViewModel(
                name: assistant.name,
                subtitle: assistant.shortDescription,
                avatarUrl: assistant.avatarUrl
            )
            cell.configure(with: vm)
            return cell

        case .popular:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AiPromptCell.reuseIdentifier,
                for: indexPath
            ) as! AiPromptCell

            let prompt = visiblePrompts[indexPath.row]

            let snippet = prompt.promptText

            let vm = AiPromptCellViewModel(
                title: prompt.title,
                snippet: snippet,
                gemCost: prompt.gemCost
            )
            cell.configure(with: vm)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension AiAssistantsViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch currentSegment {
        case .assistants:
            guard indexPath.row < assistants.count else { return }
            let assistant = assistants[indexPath.row]
            let vc = AiConversationsViewController.init(context: self.context, assistantId: assistant.id, assistantTitle: assistant.name)
            self.navigationController?.pushViewController(vc, animated: true)
            
            onAssistantSelected?(assistant)
            // در آینده اینجا navigation به صفحه چت یا جزئیات assistant را اضافه می‌کنیم.

        case .popular:
            guard indexPath.row < visiblePrompts.count else { return }
            let prompt = visiblePrompts[indexPath.row]
            let vc = AiChatViewController.init(context: self.context, assistantId: nil, conversationId: nil, promptId: prompt.id, assistantName: prompt.assistant.name)
            self.navigationController?.pushViewController(vc, animated: true)

            onPromptSelected?(prompt)
            // در آینده اینجا navigation به صفحه چت prompt-based را اضافه می‌کنیم.
        }
    }
}

// MARK: - UICollectionViewDataSource

extension AiAssistantsViewController: UICollectionViewDataSource {

    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return promptFilters.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AiPromptFilterCell.reuseIdentifier,
            for: indexPath
        ) as! AiPromptFilterCell

        let filter = promptFilters[indexPath.item]
        let title = filter.title
        let badgeText: String

        if filter.assistantId == nil {
            // "All" item
            if filter.count > 99 {
                badgeText = "99+"
            } else {
                badgeText = "\(filter.count)"
            }
        } else {
            badgeText = "\(filter.count)"
        }

        let vm = AiPromptFilterViewModel(title: title, badgeText: badgeText)
        cell.configure(with: vm)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension AiAssistantsViewController: UICollectionViewDelegate {

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        selectedFilterIndex = indexPath.item
    }
}
