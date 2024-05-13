//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

import AuthenticationServices
import SafariServices
import StripeConnect
import SwiftUI
import UIKit

class MainViewController: UITableViewController {

    /// Rows that display inside this table
    enum Row: CaseIterable {
        case accountManagement
        case accountOnboardingSafari
        case accountOnboardingAuthClient
        case accountOnboardingAuthServer
        case documents
        case payments
        case paymentDetails
        case payouts
        case payoutsList
        case logout

        var label: String {
            switch self {
            case .accountManagement: 
                return "Account management"
            case .accountOnboardingSafari,
                 .accountOnboardingAuthClient,
                 .accountOnboardingAuthServer:
                return "Account onboarding"
            case .documents: 
                return "Documents"
            case .payments: 
                return "Payments"
            case .paymentDetails: 
                return "Payment details"
            case .payouts: 
                return "Payouts"
            case .payoutsList: 
                return "Payouts list"
            case .logout: 
                return "Log out"
            }
        }
        var subtitle: String? {
            switch self {
            case .accountOnboardingSafari:
                return "Safari; server-side secret fetch"
            case .accountOnboardingAuthClient:
                return "AuthSession; mobile-side secret fetch"
            case .accountOnboardingAuthServer:
                return "AuthSession; server-side secret fetch"
            default:
                return nil
            }
        }

        var hasDisclosureAccessory: Bool {
            switch self {
            case .accountOnboardingSafari,
                 .accountOnboardingAuthClient,
                 .accountOnboardingAuthServer,
                 .logout:
                return false
            default:
                return true
            }
        }

        var labelColor: UIColor {
            if self == .logout {
                return .systemRed
            }
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
        case .accountManagement:
            viewControllerToPush = stripeConnectInstance.createAccountManagement()

        case .accountOnboardingSafari:
            let safariVC = SFSafariViewController(url: getHostedComponentURL(component: "account-onboarding"))
            safariVC.modalPresentationStyle = .popover
            safariVC.dismissButtonStyle = .close
            present(safariVC, animated: true)
            return

        case .accountOnboardingAuthClient:
            let spinner = cell.accessoryView as? UIActivityIndicatorView
            spinner?.startAnimating()
            Task { @MainActor in
                await stripeConnectInstance.presentAccountOnboarding(self)
                spinner?.stopAnimating()
            }

            return

        case .accountOnboardingAuthServer:
            /*
             1. Create an auth session from a URL that hosts the
                `account-onboarding` or `account-management` component.
             2. Set the callbackURLScheme to the the URL your webpage will
                redirect to when the user exits account onboarding. 
                For example: 'stripe-connect-example-app://exit-flow'.
             */
            let authSession = ASWebAuthenticationSession(
                url: getHostedComponentURL(component: "account-onboarding", returnScheme: "stripe-connect-example-app"),
                callbackURLScheme: "stripe-connect-example-app") { _, error in
                    if let error {
                        print(error)
                    }
                }

            // 3. Set the `presentationContextProvider` so the auth session can
            //    be presented on the current window
            authSession.presentationContextProvider = self

            // 4. Start the session to present the view
            if authSession.canStart {
                authSession.start()
            }

            return

        case .documents:
            viewControllerToPush = stripeConnectInstance.createDocuments()

        case .payments:
            viewControllerToPush = stripeConnectInstance.createPayments()

        case .paymentDetails:
            if let account = ServerConfiguration.shared.account {
                let view = PaymentsListView(account: account) { [weak navigationController] id in
                    let detailsView = stripeConnectInstance.createPaymentDetails(paymentId: id)
                    navigationController?.present(detailsView, animated: true)
                }
                viewControllerToPush = UIHostingController(rootView: view)
            } else {
                let alertController = UIAlertController(title: "Payment ID", message: "Specify a payment ID or switch to a demo account to choose from a list.", preferredStyle: .alert)

                alertController.addTextField { (textField) in
                    textField.placeholder = "ch_xxx"
                }

                // Create a Submit action
                let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned alertController, weak navigationController] _ in
                    if let id = alertController.textFields?.first?.text,
                       !id.isEmpty {
                        let detailsView = stripeConnectInstance.createPaymentDetails(paymentId: id)
                        navigationController?.present(detailsView, animated: true)
                    }
                }
                alertController.addAction(submitAction)
                present(alertController, animated: true)
                return
            }

        case .payouts:
            viewControllerToPush = stripeConnectInstance.createPayouts()

        case .payoutsList:
            viewControllerToPush = stripeConnectInstance.createPayoutsList()

        case .logout:
            let spinner = cell.accessoryView as? UIActivityIndicatorView
            spinner?.startAnimating()
            Task { @MainActor in
                await stripeConnectInstance.logout()
                spinner?.stopAnimating()
            }
            return

        }

        if viewControllerToPush.title == nil {
            viewControllerToPush.title = row.label
        }
        addChangeAppearanceButtonNavigationItem(to: viewControllerToPush)
        navigationController?.pushViewController(viewControllerToPush, animated: true)
    }

    func getHostedComponentURL(component: String, returnScheme: String? = nil) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = ServerConfiguration.shared.endpoint.host
        urlComponents.path = ""
        urlComponents.queryItems = [
            // The user's preferred locale may differ from the app locale.
            // It's recommended to send the app's locale to your server for use
            // in the StripeConnectInstance.
            .init(name: "locale", value: "\(Locale.current.languageCode!)-\(Locale.current.regionCode!)"),

            // For demo purposes, the account and component type are
            // configured from the client, but it's recommended that these
            // be configured on your server
            .init(name: "account", value: ServerConfiguration.shared.account),
            .init(name: "component", value: "account-onboarding"),

            .init(name: "appearance", value: currentAppearanceOption.rawValue),
        ]
        if let returnScheme {
            urlComponents.queryItems?.append(.init(name: "returnScheme", value: returnScheme))
        }
        return urlComponents.url!
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
        var content = cell.defaultContentConfiguration()
        content.text = row.label
        content.textProperties.color = row.labelColor
        content.secondaryText = row.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = row.hasDisclosureAccessory ? .disclosureIndicator : .none

        if !row.hasDisclosureAccessory {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.hidesWhenStopped = true
            cell.accessoryView = spinner
        }

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

// MARK: - ASWebAuthenticationPresentationContextProviding

extension MainViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}

extension MainViewController {
    /// Helper to insert in a nav controller from SceneDelegate / AppDelegate
    static func makeInNavigationController() -> UINavigationController {
        UINavigationController(rootViewController: MainViewController(nibName: nil, bundle: nil))
    }
}
