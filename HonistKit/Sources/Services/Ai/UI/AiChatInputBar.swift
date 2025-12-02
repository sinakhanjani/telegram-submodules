import UIKit
import HonistDesignSystem

public protocol AiChatInputBarDelegate: AnyObject {
    func aiChatInputBarDidTapSend(_ inputBar: AiChatInputBar, text: String)
}

public final class AiChatInputBar: UIView {

    public weak var delegate: AiChatInputBarDelegate?

    private let backgroundEffectView: UIVisualEffectView
    private let containerView = UIView()
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let minHeight: CGFloat = 44
    private let maxLines: Int = 13

    // 🔹 آیکون اصلی دکمه ارسال را نگه می‌داریم
    private let sendImage = UIImage(systemName: "paperplane.fill")

    // MARK: - Init

    public override init(frame: CGRect) {
        let blur = UIBlurEffect(style: .systemChromeMaterial) // adaptive blur (light/dark)
        self.backgroundEffectView = UIVisualEffectView(effect: blur)
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        // Blur background – pill + blur
        backgroundEffectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundEffectView.layer.cornerRadius = 22
        backgroundEffectView.layer.masksToBounds = true
        addSubview(backgroundEffectView)

        // Container فقط برای لِی‌اوت داخلی
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        backgroundEffectView.contentView.addSubview(containerView)

        // TextView
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = DS.Font.body()
        textView.backgroundColor = .clear
        textView.textColor = DS.Color.text
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.layer.cornerRadius = 18
        textView.layer.masksToBounds = true
        textView.delegate = self
        containerView.addSubview(textView)

        // Send button
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(sendImage, for: .normal)
        sendButton.tintColor = DS.Color.accent
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
        backgroundEffectView.contentView.addSubview(sendButton)

        // Activity indicator وسط دکمه send
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = DS.Color.accent
        sendButton.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Blur pill full inside AiChatInputBar (margin همون ۴ و ۱۶)
            backgroundEffectView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backgroundEffectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backgroundEffectView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            backgroundEffectView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            // Container داخل blur
            containerView.topAnchor.constraint(equalTo: backgroundEffectView.contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: backgroundEffectView.contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: backgroundEffectView.contentView.bottomAnchor, constant: -6),

            // TextView داخل container
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Send button گوشه راست
            sendButton.trailingAnchor.constraint(equalTo: backgroundEffectView.contentView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            // حداقل ارتفاع
            heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),

            // Indicator وسط sendButton
            activityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor)
        ])
    }

    // MARK: - Intrinsic size (auto-grow تا ۱۳ خط)

    public override var intrinsicContentSize: CGSize {
        let tvSize = textView.sizeThatFits(
            CGSize(width: bounds.width - 70, height: .greatestFiniteMagnitude)
        )
        let height = max(minHeight, tvSize.height + 16) // padding بالا/پایین
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    // MARK: - Public

    public func setSending(_ sending: Bool) {
        textView.isEditable = !sending
        sendButton.isEnabled = !sending

        if sending {
            // آیکون رو کامل برمی‌داریم، فقط لودر دیده می‌شه
            sendButton.setImage(nil, for: .normal)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            // آیکون اصلی رو برمی‌گردونیم
            sendButton.setImage(sendImage, for: .normal)
        }
    }

    public func clearText() {
        textView.text = ""
        textViewDidChange(textView)
    }

    // MARK: - Actions

    @objc
    public func didTapSend() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delegate?.aiChatInputBarDidTapSend(self, text: text)
    }
}

// MARK: - UITextViewDelegate

extension AiChatInputBar: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let fittingHeight = textView.sizeThatFits(size).height
        let lineHeight = textView.font?.lineHeight ?? 17
        let maxHeight = lineHeight * CGFloat(maxLines)
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom

        textView.isScrollEnabled = fittingHeight > maxHeight
        invalidateIntrinsicContentSize()
    }
}
