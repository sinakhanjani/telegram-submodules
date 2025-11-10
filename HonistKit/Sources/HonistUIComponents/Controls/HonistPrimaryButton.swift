import UIKit
import HonistDesignSystem

public final class HonistPrimaryButton: UIButton {
    private var activity: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        common()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        common()
    }

    private func common() {
        // Basic primary look similar to Telegram
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = UIColor.secondarySystemBackground
        setTitleColor(tintColor, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

        addSubview(activity)
        NSLayoutConstraint.activate([
            activity.centerYAnchor.constraint(equalTo: centerYAnchor),
            activity.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    /// Show/Hide inline loading spinner while preserving layout
    public func setLoading(_ loading: Bool) {
        isEnabled = !loading
        alpha = loading ? 0.7 : 1.0
        titleLabel?.layer.opacity = loading ? 0.0 : 1.0
        loading ? activity.startAnimating() : activity.stopAnimating()
    }
}
