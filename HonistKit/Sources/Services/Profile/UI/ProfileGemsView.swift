import UIKit
import HonistDesignSystem

public final class ProfileGemsView: UIView {
    
    public let tableView = UITableView(frame: .zero, style: .plain)
    
    private let headerView = GemsHeaderView()
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }
    
    // MARK: - Build
    
    private func build() {
        backgroundColor = DS.Color.background
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tableView.tableFooterView = UIView()
        
        addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // هدر اولیه با ارتفاع ثابت (بعداً تو layoutSubviews عرضش آپدیت می‌شه)
        let initialWidth = UIScreen.main.bounds.width
        let initialHeight: CGFloat = 320
        headerView.frame = CGRect(x: 0, y: 0, width: initialWidth, height: initialHeight)
        tableView.tableHeaderView = headerView
    }
    
    // MARK: - Public API
    
    public func configureHeader(currentGems: Int) {
        headerView.configure(currentGems: currentGems)
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let header = tableView.tableHeaderView else { return }

        // Ensure header matches table width so Auto Layout can resolve constraints correctly
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        if header.bounds.width != targetWidth {
            var frame = header.frame
            frame.size.width = targetWidth
            header.frame = frame
        }

        // Let the header lay itself out with the new width
        header.setNeedsLayout()
        header.layoutIfNeeded()

        // Ask Auto Layout for the best-fitting height given the fixed width
        let targetSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittingHeight = header.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        // Apply a minimum height to avoid collapsing too much if needed
        let minHeight: CGFloat = 280
        let finalHeight = max(minHeight, fittingHeight)

        if header.frame.height != finalHeight {
            var newFrame = header.frame
            newFrame.size.height = finalHeight
            header.frame = newFrame
            tableView.tableHeaderView = header
        }
    }
}
