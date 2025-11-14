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
        onUpdated: ((UserDTO) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        let vc = ProfileNameEditViewController(
            firstName: firstName,
            lastName: lastName
        )
        vc.onNameUpdated = onUpdated
        presenter.present(vc, animated: animated, completion: completion)
    }
}
