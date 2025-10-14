import UIKit

public protocol HonistRoutable {
    static func makeRoot() -> UIViewController
}
public enum HonistRouter {
    public static func push(_ vc: UIViewController, on nav: UINavigationController?) {
        nav?.pushViewController(vc, animated: true)
    }
}