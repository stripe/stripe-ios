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

        var isBeta: Bool { true }

        var detailText: String {
            switch self {
            case .onboarding:
                return "Show a localized onboarding form that validates data."
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
                            return nil
                        }
                     })
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = merchant.displayName.map { "Demo account: \($0)" } ?? merchant.merchantId
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
