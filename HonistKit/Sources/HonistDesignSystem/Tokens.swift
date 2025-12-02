import UIKit

public enum DS {

    // MARK: - Colors

    public enum Color {
        public static let background = UIColor.systemBackground
        public static let secondaryBackground = UIColor.secondarySystemBackground

        public static let text = UIColor.label
        public static let secondaryText = UIColor.secondaryLabel

        public static let separator = UIColor.separator
        public static let accent = UIColor.systemBlue
        public static let destructive = UIColor.systemRed

        public static let bubbleIncoming = UIColor.secondarySystemBackground
        public static let bubbleOutgoing = UIColor.systemBlue
        public static let bubbleTextIncoming = UIColor.label
        public static let bubbleTextOutgoing = UIColor.white
        // ✅ aliases so your code compiles
        public static let bubbleIncomingText = bubbleTextIncoming
        public static let bubbleOutgoingText = bubbleTextOutgoing
        public static let inputBackground = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor.black.withAlphaComponent(0.25)
            } else {
                return UIColor.systemGray5
            }
        }
        
        public static let inputBarBackground = UIColor.systemBackground.withAlphaComponent(0.92)
        public static let inputFieldBackground = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        public static let inputPlaceholder = UIColor.secondaryLabel
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
    }

    // MARK: - Radius

    public enum Radius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 20
        public static let pill: CGFloat = 999
    }

    // MARK: - Fonts

    public enum Font {
        public static func title(_ size: CGFloat = 17) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: .semibold)
        }

        public static func body(_ size: CGFloat = 15) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: .regular)
        }

        public static func caption(_ size: CGFloat = 13) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: .regular)
        }
    }
}
