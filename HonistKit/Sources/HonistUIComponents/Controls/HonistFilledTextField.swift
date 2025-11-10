import UIKit
import HonistDesignSystem

public final class HonistFilledTextField: UITextField {
    public override init(frame: CGRect) {
        super.init(frame: frame); common()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder); common()
    }

    private func common() {
        // Filled field with rounded corners (auto dark/light)
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 10
        layer.masksToBounds = true
        borderStyle = .none
        textColor = DS.Color.text
        clearButtonMode = .whileEditing
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        leftViewMode = .always

        // English-only feel
        autocapitalizationType = .none
        autocorrectionType = .no
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        spellCheckingType = .no
        enablesReturnKeyAutomatically = true
        returnKeyType = .done
        keyboardType = .asciiCapable
    }
}
