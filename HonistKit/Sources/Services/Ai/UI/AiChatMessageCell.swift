import UIKit
import HonistDesignSystem

public final class AiChatMessageCell: UITableViewCell {

    public static let reuseIdentifier = "AiChatMessageCell"

    // MARK: - Callbacks

    public var onCopyTapped: (() -> Void)?

    // MARK: - UI

    private let bubbleView = UIView()
    private let messageTextView = UITextView()
    private let copyButton = UIButton(type: .system)

    // Constraints برای راست/چپ بودن حباب
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!

    private var copyLeadingConstraint: NSLayoutConstraint!
    private var copyTrailingConstraint: NSLayoutConstraint!

    // MARK: - Init

    internal override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        copyButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageTextView)
        contentView.addSubview(copyButton)

        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.masksToBounds = true

        // 🔹 TextView شبیه UILabel قبلی
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.isSelectable = true
        messageTextView.backgroundColor = .clear
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.font = DS.Font.body()
        messageTextView.textColor = DS.Color.text
        messageTextView.dataDetectorTypes = [] // اگر بعداً خواستی لینک‌ها دتکت بشن، اینجا اضافه کن
        messageTextView.textAlignment = .left

        // copy icon زیر هر پیام
        let copyImage = UIImage(systemName: "doc.on.doc")
        copyButton.setImage(copyImage, for: .normal)
        copyButton.tintColor = DS.Color.secondaryText
        copyButton.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)

        let maxBubbleWidthMultiplier: CGFloat = 0.75

        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 12
        )
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -12
        )
        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(
            lessThanOrEqualTo: contentView.widthAnchor,
            multiplier: maxBubbleWidthMultiplier
        )

        copyLeadingConstraint = copyButton.leadingAnchor.constraint(
            equalTo: bubbleView.leadingAnchor,
            constant: 4
        )
        copyTrailingConstraint = copyButton.trailingAnchor.constraint(
            equalTo: bubbleView.trailingAnchor,
            constant: -4
        )

        NSLayoutConstraint.activate([
            bubbleLeadingConstraint,
            bubbleTrailingConstraint,
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            bubbleWidthConstraint,

            // همون padding قبلی: بالا/پایین ۸، چپ/راست ۱۲
            messageTextView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageTextView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageTextView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageTextView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            copyButton.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            copyButton.heightAnchor.constraint(equalToConstant: 16),
            copyButton.widthAnchor.constraint(equalToConstant: 16)
        ])

        // پیش‌فرض: incoming
        copyLeadingConstraint.isActive = true
        copyTrailingConstraint.isActive = false
    }

    // MARK: - Configure

    public func configure(with viewModel: AiChatMessageViewModel) {
        // 🔹 Base attributed text از ViewModel
        let mutable = NSMutableAttributedString(attributedString: viewModel.attributedText)

        // رنگ متن بر اساس outgoing/incoming
        let textColor: UIColor = viewModel.isOutgoing
            ? DS.Color.bubbleOutgoingText
            : DS.Color.bubbleIncomingText

        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: textColor, range: fullRange)

        messageTextView.attributedText = mutable

        // Direction / alignment (مثل قبل)
        messageTextView.textAlignment = viewModel.textAlignment

        switch viewModel.baseWritingDirection {
        case .rightToLeft:
            messageTextView.semanticContentAttribute = .forceRightToLeft
        case .leftToRight:
            messageTextView.semanticContentAttribute = .forceLeftToRight
        default:
            messageTextView.semanticContentAttribute = .unspecified
        }

        // مطمئن شو offset اسکرول صفره
        messageTextView.setContentOffset(.zero, animated: false)

        // outgoing = user (سمت راست)
        if viewModel.isOutgoing {
            bubbleTrailingConstraint.isActive = true
            bubbleLeadingConstraint.isActive = false

            bubbleView.backgroundColor = DS.Color.bubbleOutgoing

            copyTrailingConstraint.isActive = true
            copyLeadingConstraint.isActive = false
        } else {
            bubbleTrailingConstraint.isActive = false
            bubbleLeadingConstraint.isActive = true

            bubbleView.backgroundColor = DS.Color.bubbleIncoming

            copyTrailingConstraint.isActive = false
            copyLeadingConstraint.isActive = true
        }
    }

    // MARK: - Actions

    @objc
    private func didTapCopy() {
        onCopyTapped?()
    }
}
