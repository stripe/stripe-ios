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
        case onboarding = "Account Onboarding"
        case payouts = "Payouts"

        var label: String { rawValue }

        var description: String {
            switch self {
            case .onboarding:
                return "Show a localized onboarding form that validates data."
            case .payouts:
                return "Show payout information and allow your users to perform payouts."
            }
        }
    }

    lazy var embeddedComponentManager: EmbeddedComponentManager = {
        return .init(appearance: AppSettings.shared.appearanceInfo.appearance,
                     fonts: customFonts(),
                     fetchClientSecret: { [weak self, merchant] in
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

        switch row {
        case .onboarding:
            let savedOnboardingSettings = AppSettings.shared.onboardingSettings
            viewControllerToPresent = embeddedComponentManager.createAccountOnboardingViewController(
                fullTermsOfServiceUrl: savedOnboardingSettings.fullTermsOfServiceUrl,
                recipientTermsOfServiceUrl: savedOnboardingSettings.recipientTermsOfServiceUrl,
                privacyPolicyUrl: savedOnboardingSettings.privacyPolicyUrl,
                skipTermsOfServiceCollection: savedOnboardingSettings.skipTermsOfService.boolValue,
                collectionOptions: savedOnboardingSettings.accountCollectionOptions)
        case .payouts:
            viewControllerToPresent = embeddedComponentManager.createPayoutsViewController()
        }

        let presentationSettings = AppSettings.shared.presentationSettings
        if presentationSettings.embedInTabBar {
            let tabBarController = UITabBarController()
            viewControllerToPresent.tabBarItem = .init(title: row.label, image: UIImage(systemName: "star"), tag: 0)

            tabBarController.viewControllers = [viewControllerToPresent]

            viewControllerToPresent = tabBarController
        }

        viewControllerToPresent.navigationItem.backButtonDisplayMode = .minimal
        addChangeAppearanceButtonNavigationItem(to: viewControllerToPresent)
        viewControllerToPresent.title = row.label

        if presentationSettings.presentationStyleIsPush {
            navigationController?.pushViewController(viewControllerToPresent, animated: true)
        } else {
            viewControllerToPresent.navigationItem.leftBarButtonItem = .init(systemItem: .close, primaryAction: .init(handler: { [weak viewControllerToPresent] _ in
                viewControllerToPresent?.dismiss(animated: true)
            }))

            if presentationSettings.embedInNavBar {
                viewControllerToPresent = UINavigationController(rootViewController: viewControllerToPresent)
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
        let cell = UITableViewCell()
        cell.textLabel?.text = row.label
        cell.detailTextLabel?.text = row.description
        cell.accessoryType = .disclosureIndicator
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

extension MainViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.isNavigationBarHidden = !AppSettings.shared.presentationSettings.embedInNavBar && viewController != self

        if navigationController.isNavigationBarHidden {
            // Add floating back button
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
