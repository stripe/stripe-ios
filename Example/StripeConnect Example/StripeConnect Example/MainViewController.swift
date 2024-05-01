//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

import StripeConnect
import UIKit

class MainViewController: UITableViewController {

    /// Rows that display inside this table
    enum Row: String, CaseIterable {
        case payments = "Payments"
        case logout = "Log out"

        var label: String { rawValue }

        var accessoryType: UITableViewCell.AccessoryType {
            if self == .logout {
                return .none
            }
            return .disclosureIndicator
        }
    }

    /// Spinner that displays when log out row is selected
    let logoutSpinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    var currentAppearanceOption = ExampleAppearanceOptions.default

    var stripeConnectInstance: StripeConnectInstance?

    override func viewDidLoad() {
        super.viewDidLoad()

        STPAPIClient.shared.publishableKey = "pk_test_51MZRIlLirQdaQn8EJpw9mcVeXokTGaiV1ylz5AVQtcA0zAkoM9fLFN81yQeHYBLkCiID1Bj0sL1Ngzsq9ksRmbBN00O3VsIUdQ"
        stripeConnectInstance = StripeConnectInstance(
            fetchClientSecret: fetchClientSecret
        )
    }

    func fetchClientSecret() async -> String? {
        let url = URL(string: "https://stripe-connect-example.glitch.me/account_session")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

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

        // Add an "Appearance" button to change the appearance
        viewControllerToPush.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Appearance",
            style: .plain,
            target: self,
            action: #selector(selectAppearance)
        )
        navigationController?.pushViewController(viewControllerToPush, animated: true)
    }

    /// Displays a menu to pick from a selection of example appearances
    @objc
    func selectAppearance() {
        let optionMenu = UIAlertController(title: nil, message: "Choose appearance", preferredStyle: .actionSheet)

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

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.allCases[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = row.label
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
