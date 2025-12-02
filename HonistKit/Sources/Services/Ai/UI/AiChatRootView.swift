import UIKit
import HonistDesignSystem

public final class AiChatRootView: UIView {

    public let tableView: UITableView
    public let inputBar: AiChatInputBar

    // این کانسترینت رو کنترلر از طریق setInputBarBottomOffset آپدیت می‌کنه
    private var inputBarBottomConstraint: NSLayoutConstraint!

    public override init(frame: CGRect) {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .onDrag
        tv.backgroundColor = .clear
        self.tableView = tv

        self.inputBar = AiChatInputBar(frame: .zero)

        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        backgroundColor = DS.Color.background

        tableView.translatesAutoresizingMaskIntoConstraints = false
        inputBar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
        addSubview(inputBar)

        let safe = safeAreaLayoutGuide

        // 👇 نوار چت به safe area پایین وصل می‌شه، نه به tableView
        inputBarBottomConstraint = inputBar.bottomAnchor.constraint(
            equalTo: safe.bottomAnchor,
            constant: -16   // فاصلهٔ اولیه وقتی کیبورد بسته است
        )

        NSLayoutConstraint.activate([
            // tableView تمام صفحه تا پایین safe area
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            // inputBar روی tableView، چسبیده به پایین safe area
            inputBar.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            inputBarBottomConstraint
        ])
    }

    /// کنترل فاصلهٔ عمودی inputBar از پایین (کنترلر از این استفاده می‌کند)
    public func setInputBarBottomOffset(_ offset: CGFloat, animated: Bool) {
        // offset = فاصله‌ای که از پایین می‌خوای (۱۶ وقتی کیبورد بسته است،
        // یا keyboardHeight+gap وقتی کیبورد باز است)
        inputBarBottomConstraint.constant = -offset

        let animations = { self.layoutIfNeeded() }

        if animated {
            UIView.animate(withDuration: 0.25, animations: animations)
        } else {
            animations()
        }
    }
}
