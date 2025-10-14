import UIKit

public final class HonistLabel: UILabel {
    public override init(frame: CGRect) { super.init(frame: frame); common() }
    public required init?(coder: NSCoder) { super.init(coder: coder); common() }
    private func common() { textAlignment = .center; numberOfLines = 0 }
}