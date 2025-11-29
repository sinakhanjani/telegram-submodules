import UIKit
import HonistDesignSystem

public final class AiAssistantsRootView: UIView {

    // MARK: - Public subviews (used by controller)

    public let segmentedControl: UISegmentedControl
    public let filtersCollectionView: UICollectionView
    public let tableView: UITableView

    // We use this constraint to collapse filters when on Assistants segment.
    private var filtersHeightConstraint: NSLayoutConstraint!

    private let segmentContainer = UIView()
    
    // MARK: - Init

    internal override init(frame: CGRect) {
        // Segmented control
        let seg = UISegmentedControl(items: ["Assistants", "Popular"])
        seg.selectedSegmentIndex = 0

        // Filters collection (horizontal chips)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        let filtersCV = UICollectionView(frame: .zero, collectionViewLayout: layout)
        filtersCV.showsHorizontalScrollIndicator = false
        filtersCV.backgroundColor = .clear

        // Table view
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        tv.tableFooterView = UIView()

        self.segmentedControl = seg
        self.filtersCollectionView = filtersCV
        self.tableView = tv

        super.init(frame: frame)
        commonInit()
    }

    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func commonInit() {
        backgroundColor = DS.Color.background

        // Disable autoresizing mask
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        filtersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        segmentContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add views
        addSubview(segmentContainer)
        segmentContainer.addSubview(segmentedControl)

        addSubview(filtersCollectionView)
        addSubview(tableView)

        // Basic Telegram-like styling
        segmentedControl.backgroundColor = UIColor.secondarySystemBackground
        segmentedControl.selectedSegmentTintColor = UIColor.systemBlue
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            ],
            for: .normal
        )
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            ],
            for: .selected
        )

        tableView.backgroundColor = .clear

        let spacing: CGFloat = DS.Spacing.md

        // Filters height (for show/hide)
        filtersHeightConstraint = filtersCollectionView.heightAnchor.constraint(equalToConstant: 40)

        NSLayoutConstraint.activate([
            // --- Segment container (centered, fixed width) ---
            segmentContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentContainer.widthAnchor.constraint(equalToConstant: 260),
            segmentContainer.heightAnchor.constraint(equalToConstant: 34),

            // Segmented control fills container
            segmentedControl.topAnchor.constraint(equalTo: segmentContainer.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentContainer.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: segmentContainer.trailingAnchor),

            // --- Filters collection ---
            filtersCollectionView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor, constant: spacing),
            filtersCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            filtersCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            filtersHeightConstraint,

            // --- Table view ---
            tableView.topAnchor.constraint(equalTo: filtersCollectionView.bottomAnchor, constant: spacing / 2),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 16),
        ])
    }
    // MARK: - Public helpers

    /// Shows or hides the horizontal filters bar (used when switching segments).
    public func setFiltersVisible(_ visible: Bool, animated: Bool) {
        filtersHeightConstraint.constant = visible ? 40 : 0
        filtersCollectionView.isHidden = !visible

        guard animated else {
            layoutIfNeeded()
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
