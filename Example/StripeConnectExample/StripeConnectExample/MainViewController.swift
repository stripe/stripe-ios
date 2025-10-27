//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(PreviewConnect) import StripeConnect
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
        case onboarding = "Account onboarding"
        case payouts = "Payouts"
        case payments = "Payments"
        // TODO: add this once in preview
        // case checkScanning = "Check scanning"

        var label: String { rawValue }

        var attributedLabel: NSAttributedString {
            let attributeString = NSMutableAttributedString(
                string: label,
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize),
                ]
            )
            if isBeta {
                attributeString.append(NSAttributedString(
                    string: " Beta",
                    attributes: [
                        .font: UIFont.preferredFont(forTextStyle: .footnote),
                        .foregroundColor: UIColor.secondaryLabel,
                    ]
                ))
            }
            return attributeString
        }

        var isBeta: Bool {
            switch self {
            case .onboarding:
                return false  // GA
            case .payouts:
                return true   // Experimental
            case .payments:
                return true   // Experimental
            }
        }

        var detailText: String {
            switch self {
            case .onboarding:
                return "Show a localized onboarding form that validates data."
            case .payouts:
                return "Show payouts and allow your users to perform payouts."
            case .payments:
                return "Show payments and allow your users to view payment details and manage disputes."
            }
        }
    }

    lazy var embeddedComponentManager: EmbeddedComponentManager = {
        return .init(appearance: AppSettings.shared.appearanceInfo.appearance,
                     fonts: customFonts(),
                     fetchClientSecret: { [merchant] in
                        do {
                            return try await API.accountSession(merchantId: merchant.id).get().clientSecret
                        } catch {
                            return nil
                        }
                     })
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = merchant.displayName.map { "Demo account: \($0)" } ?? merchant.merchantId
        navigationController?.delegate = self
        addChangeAppearanceButtonNavigationItem(to: self)

        navigationItem.leftBarButtonItem = .init(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(presentServerSettings)
        )
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
        var viewControllerToPresent: UIViewController

        // Create a view controller for the selected component
        switch row {
        case .onboarding:
            let savedOnboardingSettings = AppSettings.shared.onboardingSettings
            let onboardingConfig = embeddedComponentManager.createAccountOnboardingController(
                fullTermsOfServiceUrl: savedOnboardingSettings.fullTermsOfServiceUrl,
                recipientTermsOfServiceUrl: savedOnboardingSettings.recipientTermsOfServiceUrl,
                privacyPolicyUrl: savedOnboardingSettings.privacyPolicyUrl,
                skipTermsOfServiceCollection: savedOnboardingSettings.skipTermsOfService.boolValue,
                collectionOptions: savedOnboardingSettings.accountCollectionOptions)
            onboardingConfig.delegate = self
            onboardingConfig.title = row.label
            onboardingConfig.present(from: self, animated: true)
            return
        case .payouts:
            let payoutsVC = embeddedComponentManager.createPayoutsViewController()
            payoutsVC.delegate = self
            viewControllerToPresent = payoutsVC
        case .payments:
            // Use saved payments settings from AppSettings
            let savedPaymentsSettings = AppSettings.shared.paymentsSettings
            let defaultFilters = savedPaymentsSettings.paymentsListDefaultFiltersOptions

            let paymentsVC = embeddedComponentManager.createPaymentsViewController(
                defaultFilters: defaultFilters
            )
            paymentsVC.delegate = self
            viewControllerToPresent = paymentsVC
        }

        // Fetch ViewController presentation settings
        let presentationSettings = AppSettings.shared.presentationSettings

        if presentationSettings.embedInTabBar {
            // Embed in a tab bar
            let tabBarController = UITabBarController()
            viewControllerToPresent.tabBarItem = .init(title: row.label, image: UIImage(systemName: "star"), tag: 0)

            tabBarController.viewControllers = [viewControllerToPresent]

            viewControllerToPresent = tabBarController
        }

        // Configure the component VC's navbar
        viewControllerToPresent.navigationItem.backButtonDisplayMode = .minimal
        addChangeAppearanceButtonNavigationItem(to: viewControllerToPresent)
        viewControllerToPresent.title = row.label

        if presentationSettings.presentationStyleIsPush {
            // Push to navigation stack
            navigationController?.pushViewController(viewControllerToPresent, animated: true)
        } else {
            // Modally present

            let closeAction = UIAction { [weak viewControllerToPresent] _ in
                viewControllerToPresent?.dismiss(animated: true)
            }

            if presentationSettings.embedInNavBar {
                // Add a close button to navbar
                viewControllerToPresent.navigationItem.leftBarButtonItem = .init(systemItem: .close, primaryAction: closeAction)

                // Embed inside a navbar
                viewControllerToPresent = UINavigationController(rootViewController: viewControllerToPresent)
            } else {
                // Add floating close button
                let closeButton = UIButton(type: .close, primaryAction: closeAction)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                viewControllerToPresent.view.addSubview(closeButton)
                NSLayoutConstraint.activate([
                    closeButton.topAnchor.constraint(equalTo: viewControllerToPresent.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    closeButton.trailingAnchor.constraint(equalTo: viewControllerToPresent.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                ])
            }
            present(viewControllerToPresent, animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.allCases[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.attributedText = row.attributedLabel
        cell.detailTextLabel?.text = row.detailText
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = StripeConnectExampleAppKeys.onboardingCellAccessibilityID
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
        (presentedViewController ?? self).present(alert, animated: true)
    }

    func customFonts() -> [EmbeddedComponentManager.CustomFontSource] {
        // Note: The font name does not always match the file name,
        // but it makes initialization of font source easier when it does.
        let fonts: [String] = [
            "Handjet-Regular",
            "Handjet-Bold",
        ]

        let fontSources: [EmbeddedComponentManager.CustomFontSource] = fonts.map { fontName in
            guard let fontFileURL = Bundle.main.url(forResource: fontName, withExtension: "ttf"),
                  let font = UIFont(name: fontName, size: UIFont.systemFontSize) else {
                print("Failed to load font with name \(fontName)")
                return nil
            }
            do {
                return try .init(font: font, fileUrl: fontFileURL)
            } catch {
                print("Failed to create font source \(error)")
                return nil
            }
        }
        .compactMap({ $0 })

        if fontSources.count != fonts.count {
            print("Failed to load some fonts. Below are the available fonts to choose from: ")
            for family in UIFont.familyNames.sorted() {
                print("Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("- \(name)")
                }
            }
        }

        return fontSources
    }
}

// MARK: - AccountOnboardingControllerDelegate

extension MainViewController: AccountOnboardingControllerDelegate {
    func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController) {
        //  Retrieve account details to check the status of details_submitted, charges_enabled, payouts_enabled, and other capabilities
        ToastManager.shared.show("Did exit called")
    }

    func accountOnboarding(_ accountOnboarding: AccountOnboardingController, didFailLoadWithError error: any Error) {
        ToastManager.shared.show("Error loading account onboarding")
    }
}

// MARK: - PayoutsViewControllerDelegate

extension MainViewController: PayoutsViewControllerDelegate {
    func payouts(_ payouts: PayoutsViewController, didFailLoadWithError error: any Error) {
        presentAlert(title: "Error loading payouts", message: (error as NSError).debugDescription)
    }
}

// MARK: - PaymentsViewControllerDelegate

extension MainViewController: PaymentsViewControllerDelegate {
    func payments(_ payments: PaymentsViewController, didFailLoadWithError error: any Error) {
        presentAlert(title: "Error loading payments", message: (error as NSError).debugDescription)
    }
}

// MARK: - UINavigationControllerDelegate

extension MainViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        // Hide the navbar on the component VC if it's disabled in presentation settings

        navigationController.isNavigationBarHidden = !AppSettings.shared.presentationSettings.embedInNavBar && viewController != self

        if navigationController.isNavigationBarHidden {

            // Add floating back button so we can still navigate back

            let backButton = UIButton(
                type: .system,
                primaryAction: UIAction(
                    title: "Back",
                    image: UIImage(systemName: "chevron.backward"),
                    handler: { _ in
                        navigationController.popViewController(animated: true)
                    }
                ))
            backButton.backgroundColor = .systemBackground.withAlphaComponent(0.5)
            backButton.layer.cornerRadius = 4
            backButton.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(backButton)
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                backButton.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            ])
        }
    }
}
