import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import HonistKit

public final class HonistGemBadgeNode: ASDisplayNode {
    private let textNode = ImmediateTextNode()
    private let imageNode = ASImageNode()
    
    private var gems: Int = 0
    private var currentTextColor: UIColor
    
    public init(textColor: UIColor, backgroundColor: UIColor) {
        self.currentTextColor = textColor
        super.init()
        
        self.isUserInteractionEnabled = false
        self.automaticallyManagesSubnodes = false
        
        // Text
        self.textNode.displaysAsynchronously = false
        self.textNode.attributedText = NSAttributedString(
            string: "0",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: textColor
            ]
        )
        
        // Icon
        if let img = UIImage(named: "ic_gem_nav") ?? UIImage(systemName: "diamond.fill") {
            self.imageNode.image = img.withRenderingMode(.alwaysTemplate)
            self.imageNode.contentMode = .scaleAspectFit
            self.imageNode.tintColor = .systemTeal
        }
        
        self.backgroundColor = backgroundColor
        self.cornerRadius = 15.0
        self.clipsToBounds = true
        
        // Subnodes
        self.addSubnode(self.textNode)
        self.addSubnode(self.imageNode)
    }
    
    public func updateColors(textColor: UIColor, backgroundColor: UIColor) {
        self.currentTextColor = textColor
        
        let string = self.textNode.attributedText?.string ?? "\(self.gems)"
        self.textNode.attributedText = NSAttributedString(
            string: string,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: textColor
            ]
        )
        self.backgroundColor = backgroundColor
        
        self.setNeedsLayout()
    }
    
    public func setGems(_ value: Int) {
        self.gems = value
        self.textNode.attributedText = NSAttributedString(
            string: "\(value)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: self.currentTextColor
            ]
        )
        self.setNeedsLayout()
    }
    
    public override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let textSize = self.textNode.updateLayout(CGSize(width: 100.0, height: 22.0))
        let iconSide: CGFloat = 18.0
        let horizontalPadding: CGFloat = 6.0 * 2
        let spacing: CGFloat = 4.0
        
        let width = textSize.width + iconSide + spacing + horizontalPadding
        let height: CGFloat = 30.0
        
        return CGSize(width: width, height: height)
    }
    
    public override func layout() {
        super.layout()
        
        let bounds = self.bounds
        let iconSide: CGFloat = 18.0
        let spacing: CGFloat = 4.0
        
        let textSize = self.textNode.updateLayout(CGSize(width: 100.0, height: bounds.height))
        
        let totalWidth = textSize.width + spacing + iconSide
        let startX = (bounds.width - totalWidth) / 2.0
        
        self.textNode.frame = CGRect(
            x: startX,
            y: floor((bounds.height - textSize.height) / 2.0),
            width: textSize.width,
            height: textSize.height
        )
        
        self.imageNode.frame = CGRect(
            x: self.textNode.frame.maxX + spacing,
            y: floor((bounds.height - iconSide) / 2.0),
            width: iconSide,
            height: iconSide
        )
    }
}
