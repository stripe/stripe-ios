//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

import StripeConnect
import SwiftUI
import UIKit

class MainViewController: UITableViewController {

    /// Rows that display inside this table
    enum Row: String, CaseIterable {
        case accountOnboarding = "Account onboarding"
        case documents = "Documents"
        case payments = "Payments"
        case logout = "Log out"

        var label: String { rawValue }

        var accessoryType: UITableViewCell.AccessoryType {
            if self == .logout {
                return .none
            }
            return .disclosureIndicator
        }

        var labelColor: UIColor {
            if self == .logout {
                return .systemRed
            }
            return .label
        }
    }

    /// Spinner that displays when log out row is selected
    let logoutSpinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    /// Navbar button title view
    lazy var navbarTitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: "chevron.down",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10)),
                        for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = .label
        button.addTarget(self, action: #selector(configureServer), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.accessibilityLabel = "Configure server"
        return button
    }()

    override var title: String? {
        didSet {
            navbarTitleButton.setTitle(title, for: .normal)
        }
    }

    var currentAppearanceOption = ExampleAppearanceOptions.default
    var stripeConnectInstance: StripeConnectInstance?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize publishable key
        STPAPIClient.shared.publishableKey = ServerConfiguration.shared.publishableKey

        // Initialize Stripe instance
        stripeConnectInstance = StripeConnectInstance(
            customFonts: ExampleAppearanceOptions.customFonts,
            fetchClientSecret: fetchClientSecret
        )

        // Configure navbar
        title = ServerConfiguration.shared.label
        navigationItem.titleView = navbarTitleButton
        addChangeAppearanceButtonNavigationItem(to: self)
    }

    func fetchClientSecret() async -> String? {
        var request = URLRequest(url: ServerConfiguration.shared.endpoint)
        request.httpMethod = "POST"

        // For demo purposes, the account is configured from the client,
        // but it's recommended that this be configured on your server
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = ServerConfiguration.shared.account.map {
            try! JSONSerialization.data(withJSONObject: ["account": $0])
        }

        do {
            // Fetch the AccountSession client secret
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["client_secret"] as? String
        } catch {
            UIApplication.shared.showToast(message: error.localizedDescription)
            return nil
        }
    }

    /// Called when table row is selected
    func performAction(_ row: Row, cell: UITableViewCell) {
        guard let stripeConnectInstance else { return }

        let viewControllerToPush: UIViewController

        switch row {
        case .accountOnboarding:
            let accountOnboardingVC = stripeConnectInstance.createAccountOnboarding { [weak navigationController] in
                navigationController?.popViewController(animated: true)
            }
            accountOnboardingVC.title = "Account onboarding"
            let button = UIBarButtonItem(
                image: UIImage(systemName: "slider.horizontal.3"),
                primaryAction: .init(handler: { [weak accountOnboardingVC] _ in
                    let view = AccountOnboardingConfigurationView(accountOnboardingViewController: accountOnboardingVC)
                    accountOnboardingVC?.present(UIHostingController(rootView: view), animated: true)
                }))
            button.accessibilityLabel = "Configure account onboarding"
            accountOnboardingVC.navigationItem.rightBarButtonItem = button
            viewControllerToPush = accountOnboardingVC

        case .documents:
            viewControllerToPush = stripeConnectInstance.createDocuments()
            viewControllerToPush.title = "Documents"

        case .payments:
            viewControllerToPush = stripeConnectInstance.createPayments()
            viewControllerToPush.title = "Payments"

        case .logout:
            cell.accessoryView = logoutSpinner
            logoutSpinner.startAnimating()
            Task { @MainActor in
                await stripeConnectInstance.logout()
                self.logoutSpinner.stopAnimating()
            }
            return
        }

        addChangeAppearanceButtonNavigationItem(to: viewControllerToPush)
        navigationController?.pushViewController(viewControllerToPush, animated: true)
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

    /// Displays a menu to pick from a selection of example appearances
    @objc
    func selectAppearance(sender: UIBarButtonItem) {
        let optionMenu = UIAlertController(title: "Change appearance", message: "These are some example appearances configured in ExampleAppearanceOptions", preferredStyle: .actionSheet)

        // iPad compatibility
        if let popoverPresentationController = optionMenu.popoverPresentationController {
            if let buttonView = sender.value(forKey: "view") as? UIView {
                popoverPresentationController.sourceRect = buttonView.frame
                popoverPresentationController.sourceView = buttonView
            } else {
                popoverPresentationController.sourceView = view
            }
        }

        ExampleAppearanceOptions.allCases.forEach { option in
            let action = UIAlertAction(title: option.label, style: .default) { [weak self] _ in
                self?.currentAppearanceOption = option
                self?.stripeConnectInstance?.update(appearance: .init(option))
            }
            if currentAppearanceOption == option {
                let icon = UIImage(systemName: "checkmark")
                action.setValue(icon, forKey: "image")
            }
            optionMenu.addAction(action)
        }
        optionMenu.addAction(.init(title: "Cancel", style: .cancel))

        self.present(optionMenu, animated: true, completion: nil)
    }

    @objc
    func configureServer() {
        let view = ServerConfigurationView { [weak self] in
            self?.title = ServerConfiguration.shared.label
        }
        self.present(UIHostingController(rootView: view), animated: true)
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
}

extension MainViewController {
    /// Helper to insert in a nav controller from SceneDelegate / AppDelegate
    static func makeInNavigationController() -> UINavigationController {
        UINavigationController(rootViewController: MainViewController(nibName: nil, bundle: nil))
    }
}
