import UIKit
import HonistRouting

public enum ProfileFeature: HonistRoutable {
    public static func makeRoot() -> UIViewController {
        return ProfileViewController()
    }
}
