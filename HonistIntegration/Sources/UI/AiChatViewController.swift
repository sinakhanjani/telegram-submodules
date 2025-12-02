import UIKit
import HonistKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext

/// Chat screen between user and AI assistant / prompt.
/// - If `conversationId` is nil => new conversation.
/// - Uses pagination (20-by-20) with `listConversationMessages` when conversationId exists.
public final class AiChatViewController: HonistBaseViewController {

    // MARK: - Dependencies

    private let logic: AiLogic

    // MARK: - Inputs

    private var conversationId: String?
    private let assistantId: String?
    private let promptId: String?

    // MARK: - UI

    private let rootView = AiChatRootView()

    // راحت‌تر برای دسترسی
    private var tableView: UITableView { rootView.tableView }
    private var inputBar: AiChatInputBar { rootView.inputBar }

    // MARK: - State

    private var messages: [AiMessageDTO] = []

    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private var isLoadingPage: Bool = false
    private var hasMorePages: Bool = true

    // فاصله‌ها
    private let bottomOffsetWhenKeyboardHidden: CGFloat = 16.0
    private let bottomOffsetWhenKeyboardShownExtraGap: CGFloat = 4.0

    // MARK: - Init
    
    /// - Parameter referrals: optional initial list of referrals to display.
    public init(context: AccountContext,
                assistantId: String? = nil,
                conversationId: String? = nil,
                promptId: String? = nil,
                assistantName: String,
                logic: AiLogic = AiLogic()
    ) {
        self.assistantId = assistantId
        self.conversationId = conversationId
        self.promptId = promptId
        self.logic = logic
        super.init(
             context: context,
             title: assistantName,
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
        
        configureTableView()

        inputBar.delegate = self

        // ✅ حالت اولیه: کیبورد بسته → ۱۶ تا فاصله از پایین
        rootView.setInputBarBottomOffset(bottomOffsetWhenKeyboardHidden, animated: false)

        // Keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        // اگر مکالمه‌ای داریم، پیام‌های قبلی رو لود کن
        if conversationId != nil {
            loadInitialMessages()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard

    @objc
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let durationNumber = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
            let curveNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
            return
        }

        let duration = durationNumber.doubleValue
        let options = UIView.AnimationOptions(rawValue: curveNumber.uintValue << 16)
        let keyboardFrame = frameValue.cgRectValue

        // ارتفاع کیبورد نسبت به view
        let kbInView = view.convert(keyboardFrame, from: nil)
        let rawKeyboardHeight = max(0, view.bounds.height - kbInView.origin.y)

        // چون rootView از safeArea پیروی می‌کنه، از height، safeArea پایین رو کم می‌کنیم
        let effectiveKeyboardHeight = max(0, rawKeyboardHeight - view.safeAreaInsets.bottom)

        // فاصله‌ای که می‌خوایم بین inputBar و بالای کیبورد باشه (مثلاً ۴)
        let offset = effectiveKeyboardHeight + bottomOffsetWhenKeyboardShownExtraGap

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.rootView.setInputBarBottomOffset(offset, animated: false)
            // برای اینکه table زیر inputBar نره
            self.updateTableBottomInset()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc
    private func handleKeyboardWillHide(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let durationNumber = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
            let curveNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        else {
            // برگرد به فاصله‌ی ۱۶
            rootView.setInputBarBottomOffset(bottomOffsetWhenKeyboardHidden, animated: true)
            updateTableBottomInset()
            return
        }

        let duration = durationNumber.doubleValue
        let options = UIView.AnimationOptions(rawValue: curveNumber.uintValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.rootView.setInputBarBottomOffset(self.bottomOffsetWhenKeyboardHidden, animated: false)
            self.updateTableBottomInset()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func updateTableBottomInset() {
        // ارتفاع فعلی inputBar + کمی فاصله، که ردیف‌ها زیرش قایم نشن
        let barHeight = inputBar.bounds.height
        let inset = barHeight + 8
        tableView.contentInset.bottom = inset
        tableView.scrollIndicatorInsets.bottom = inset
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // هر بار layout شد، این رو sync می‌کنیم
        updateTableBottomInset()
    }

    // MARK: - Table setup

    private func configureTableView() {
        let tv = tableView
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        tv.separatorStyle = .none
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tv.scrollIndicatorInsets = tv.contentInset

        tv.register(
            AiChatMessageCell.self,
            forCellReuseIdentifier: AiChatMessageCell.reuseIdentifier
        )
    }

    // MARK: - Loading messages

    private func loadInitialMessages() {
        currentPage = 1
        hasMorePages = true
        messages.removeAll()
        tableView.reloadData()
        loadNextPage(prepend: false)
    }

    private func loadNextPage(prepend: Bool) {
        guard !isLoadingPage, hasMorePages, let conversationId = conversationId else { return }

        isLoadingPage = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let payload = try await self.logic.listConversationMessages(
                    conversationId: conversationId,
                    page: currentPage,
                    limit: pageSize
                )

                let newItems = payload.items
                if newItems.count < self.pageSize {
                    self.hasMorePages = false
                } else {
                    self.currentPage += 1
                }

                await MainActor.run {
                    if prepend {
                        self.messages.insert(contentsOf: newItems, at: 0)

                        let oldOffset = self.tableView.contentOffset.y
                        let oldHeight = self.tableView.contentSize.height

                        self.tableView.reloadData()

                        let newHeight = self.tableView.contentSize.height
                        let delta = newHeight - oldHeight
                        self.tableView.contentOffset.y = oldOffset + delta
                    } else {
                        self.messages = newItems
                        self.tableView.reloadData()
                        self.scrollToBottom(animated: false)
                    }
                }
            } catch {
                // TODO: error UI
            }

            await MainActor.run {
                self.isLoadingPage = false
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: animated)
    }

    // MARK: - Sending
    private func send(text: String) {
        guard assistantId != nil || promptId != nil else { return }

        inputBar.setSending(true)

        Task { [weak self] in
            guard let self else { return }
            do {
                let result: AiSendMessageResultDTO

                if let promptId = self.promptId {
                    result = try await self.logic.sendMessageWithPrompt(
                        promptId: promptId,
                        conversationId: self.conversationId,
                        content: text
                    )
                } else if let assistantId = self.assistantId {
                    result = try await self.logic.sendMessageToAssistant(
                        assistantId: assistantId,
                        conversationId: self.conversationId,
                        content: text
                    )
                } else {
                    throw NSError(
                        domain: "AiChat",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No assistant or prompt specified"]
                    )
                }

                await MainActor.run {
                    if self.conversationId == nil {
                        self.conversationId = result.conversationId
                    }

                    self.messages.append(result.userMessage)
                    self.messages.append(result.assistantMessage)

                    self.tableView.reloadData()
                    self.scrollToBottom(animated: true)

                    self.inputBar.clearText()
                    self.inputBar.setSending(false)
                }

                Task { [weak self] in
                    guard let self else { return }
                    do {
                        let user = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
                        await MainActor.run {
                            // update GEM UI.
                            self.updateGemCount(user.currentGemBalance)
                        }
                    } catch {
                        print("⚠️ meWithAutoRefresh failed:", error)
                    }
                }

            } catch {
                await MainActor.run {
                    self.inputBar.setSending(false)

                    print("❌ AI chat request failed:", error)

                    let msg: String
                    if let honistError = error as? HonistError {
                        msg = honistError.errorDescription ?? ""
                    } else {
                        msg = error.localizedDescription
                    }

                    self.showInfoAlert(
                        title: "Request Failed",
                        message: msg
                    )
                }
            }
        }
    }


    // MARK: - Alerts

    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil)
        )
        present(alert, animated: true, completion: nil)
    }
    // MARK: - Helpers

    public func viewModel(at indexPath: IndexPath) -> AiChatMessageViewModel {
        let dto = messages[indexPath.row]
        return AiChatMessageViewModel(message: dto)
    }
}

// MARK: - AiChatInputBarDelegate

extension AiChatViewController: AiChatInputBarDelegate {
    public func aiChatInputBarDidTapSend(_ inputBar: AiChatInputBar, text: String) {
        send(text: text)
    }
}

// MARK: - UITableViewDataSource

extension AiChatViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AiChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as! AiChatMessageCell

        let vm = viewModel(at: indexPath)
        cell.configure(with: vm)
        cell.onCopyTapped = { [weak self] in
            guard let _ = self else { return }
            UIPasteboard.general.string = vm.text
        }

        return cell
    }
}

// MARK: - UITableViewDelegate + pagination

extension AiChatViewController: UITableViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let offsetY = scrollView.contentOffset.y
        if offsetY < 40, !isLoadingPage, hasMorePages {
            loadNextPage(prepend: true)
        }
    }
}
