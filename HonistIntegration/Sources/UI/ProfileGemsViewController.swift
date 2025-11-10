import UIKit
import HonistKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext

public final class ProfileGemsViewController: HonistBaseViewController {
    
    private let rootView = ProfileGemsView()
    
    private let profileLogic = ProfileLogic()

    private enum OptionType {
        case watchAds
        case buyGems
        case referral
    }
    
    private struct OptionItem {
        let type: OptionType
        let viewModel: GemsOptionCell.ViewModel
    }
    
    private var items: [OptionItem] = [
        //        .init(
        //            type: .watchAds,
        //            viewModel: .init(
        //                title: "Watch Ads",
        //                iconName: "ic_gems_watch_ads",
        //                systemFallback: "play.rectangle.fill",
        //                iconBackgroundColor: UIColor.systemOrange
        //            )
        //        ),
        .init(
            type: .buyGems,
            viewModel: .init(
                title: "Buy Gems",
                iconName: "ic_gems_buy",
                systemFallback: "creditcard.fill",
                iconBackgroundColor: UIColor.systemGreen
            )
        ),
        .init(
            type: .referral,
            viewModel: .init(
                title: "Referral",
                iconName: "ic_gems_referral",
                systemFallback: "person.3.fill",
                iconBackgroundColor: UIColor.systemPurple
            )
        )
    ]
    
    // MARK: - Init
    
    public init(context: AccountContext) {
         super.init(
             context: context,
             title: "Gems",
             hidesBackButton: false
         )
     }

     required init(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    
    // MARK: - DisplayNode
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode(viewBlock: { [weak self] in
            let view = UIView()
            view.backgroundColor = self?.presentationData.theme.list.plainBackgroundColor ?? .systemBackground
            return view
        })
        
        self.displayNodeDidLoad()
    }
    
    
    // MARK: - Lifecycle
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        attachRootView(rootView)
        setupTable()
        configureHeader()
    }
    
    private func setupTable() {
        let tableView = rootView.tableView
        tableView.register(GemsOptionCell.self, forCellReuseIdentifier: GemsOptionCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureHeader() {
        let gems = AuthAppServices.shared.authLogic.currentUser?.currentGemBalance ?? 0
        rootView.configureHeader(currentGems: gems)
    }
}

// MARK: - UITableViewDataSource

extension ProfileGemsViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: GemsOptionCell.reuseId,
            for: indexPath
        ) as! GemsOptionCell
        
        let item = items[indexPath.row]
        cell.configure(with: item.viewModel)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProfileGemsViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]
        switch item.type {
        case .watchAds:
            // TODO: navigate to "Watch Ads" screen
            break
        case .buyGems:
            // TODO: navigate to "Buy Gems" screen
            break
        case .referral:
            // TODO: navigate to "Referral" screen
            Task { [weak self] in
                let result = try? await self?.profileLogic.fetchReferrals(page: 1, limit: 1000)
                let refList = result?.items ?? []

                guard let self else { return }
                let vc = ProfileReferralsViewController.init(context: self.context, referrals: refList)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        }
    }
}
