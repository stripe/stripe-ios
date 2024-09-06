//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(PrivateBetaConnect) import StripeConnect
import SwiftUI
import UIKit

class MainViewController: UITableViewController {

    let appInfo: AppInfo
    let merchant: MerchantInfo
    
    init(appInfo: AppInfo, merchant: MerchantInfo) {
        self.appInfo = appInfo
        self.merchant = merchant
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Rows that display inside this table
    enum Row: String, CaseIterable {
        case payouts = "Payouts"

        var label: String { rawValue }

        var accessoryType: UITableViewCell.AccessoryType {
            .disclosureIndicator
        }

        var labelColor: UIColor {
            return .label
        }
    }

    /// Navbar button title view
    lazy var navbarTitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: "chevron.down",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10)),
                        for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = .label
        button.addTarget(self, action: #selector(presentServerSettings), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.accessibilityLabel = "Configure server"
        return button
    }()

    override var title: String? {
        didSet {
            navbarTitleButton.setTitle(title, for: .normal)
        }
    }

    lazy var embeddedComponentManager: EmbeddedComponentManager = {
        return .init(appearance: AppSettings.shared.appearanceInfo.appearance, fetchClientSecret: { [weak self, merchant] in
            do {
                return try await API.accountSession(merchantId: merchant.id).get().clientSecret
            } catch {
                self?.presentAlert(title: "An error occurred", message: "Failed to retrieve client secret.")
                return nil
            }
        })
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = merchant.displayName ?? merchant.merchantId
        navigationItem.titleView = navbarTitleButton
        addChangeAppearanceButtonNavigationItem(to: self)
    }
    
    func addChangeAppearanceButtonNavigationItem(to viewController: UIViewController) {
         // Add a button to change the appearance
         let button = UIBarButtonItem(
             image: UIImage(systemName: "paintpalette"),
             style: .plain,
             target: self,
             action: #selector(selectAppearance)
         )
         button.accessibilityLabel = "Change appearance"
         var buttonItems = viewController.navigationItem.rightBarButtonItems ?? []
         buttonItems = [button] + buttonItems
         viewController.navigationItem.rightBarButtonItems = buttonItems
     }
    
    @objc
    func selectAppearance() {
        self.navigationController?.present(AppearanceSettings(componentManager: embeddedComponentManager).containerViewController, animated: true)
    }

    /// Called when table row is selected
    func performAction(_ row: Row, cell: UITableViewCell) {
        let viewControllerToPush: UIViewController

        switch row {
        case .payouts:
            viewControllerToPush = embeddedComponentManager.createPayoutsViewController()
        }
        
        viewControllerToPush.navigationItem.backButtonDisplayMode = .minimal
        addChangeAppearanceButtonNavigationItem(to: viewControllerToPush)
        navigationController?.pushViewController(viewControllerToPush, animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.allCases[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = row.label
        cell.textLabel?.textColor = row.labelColor
        cell.accessoryType = row.accessoryType
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.isSelected = false

        performAction(Row.allCases[indexPath.row], cell: cell)
    }
    
    @objc
    func presentServerSettings() {
        self.present(AppSettingsView(appInfo: appInfo).containerViewController, animated: true)
    }
    
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
