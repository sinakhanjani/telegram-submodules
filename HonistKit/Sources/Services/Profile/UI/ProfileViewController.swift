import HonistDesignSystem
import HonistUIComponents
import UIKit

public final class ProfileViewController: UIViewController {
    let label = HonistLabel()
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
        title = "Profile"
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        label.text = "Profile Screen ✅"
    }
}
