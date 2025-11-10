// Services/Profile/ProfileNameEditFeature.swift
import UIKit
import HonistKit

/// Feature entry point for "Edit Name" popup.
public enum ProfileNameEditFeature: HonistRoutable {
    
    /// Protocol requirement (no params).
    public static func makeRoot() -> UIViewController {
        return makeRoot(firstName: nil, lastName: nil)
    }
    
    /// More explicit factory with initial names.
    public static func makeRoot(firstName: String?, lastName: String?) -> UIViewController {
        let vc = ProfileNameEditViewController(
            firstName: firstName,
            lastName: lastName
        )
        return vc
    }
    
    /// Helper to present from any controller.
    public static func present(
        over presenter: UIViewController,
        firstName: String?,
        lastName: String?,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let modal = makeRoot(firstName: firstName, lastName: lastName)
        presenter.present(modal, animated: animated, completion: completion)
    }
}
