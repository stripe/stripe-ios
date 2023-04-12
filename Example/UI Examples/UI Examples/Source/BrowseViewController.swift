//
//  BrowseViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import PassKit
import SwiftUI
import UIKit

@testable import Stripe
@_spi(STP) import StripePaymentsUI

class BrowseViewController: UITableViewController, STPAddCardViewControllerDelegate,
    STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate
{

    enum Demo: Int {
        static var count: Int {
            if #available(iOS 13.0.0, *) {
                return 10 + 1
            } else {
                return 10
            }
        }

        case STPPaymentCardTextField
        case STPAddCardViewController
        case STPAddCardViewControllerWithAddress
        case STPPaymentOptionsViewController
        case STPPaymentOptionsFPXViewController
        case STPShippingInfoViewController
        case STPAUBECSFormViewController
        case STPCardFormViewController
        case ChangeTheme
        // SwiftUI Values
        case SwiftUICardFormViewController
        case PaymentMethodMessagingView

        var title: String {
            switch self {
            case .STPPaymentCardTextField: return "Card Field"
            case .STPAddCardViewController: return "(Basic Integration) Card Form"
            case .STPAddCardViewControllerWithAddress: return "(Basic Integration) Card Form with Billing Address"
            case .STPPaymentOptionsViewController: return "Payment Option Picker"
            case .STPPaymentOptionsFPXViewController: return "Payment Option Picker (With FPX)"
            case .STPShippingInfoViewController: return "Shipping Info Form"
            case .STPAUBECSFormViewController: return "AU BECS Form"
            case .STPCardFormViewController: return "Card Form"
            case .ChangeTheme: return "Change Theme"
            case .SwiftUICardFormViewController: return "Card Form (SwiftUI)"
            case .PaymentMethodMessagingView: return "Payment Method Messaging View"
            }
        }

        var detail: String {
            switch self {
            case .STPPaymentCardTextField: return "STPPaymentCardTextField"
            case .STPAddCardViewController: return "STPAddCardViewController"
            case .STPAddCardViewControllerWithAddress: return "STPAddCardViewController"
            case .STPPaymentOptionsViewController: return "STPPaymentOptionsViewController"
            case .STPPaymentOptionsFPXViewController: return "STPPaymentOptionsViewController"
            case .STPShippingInfoViewController: return "STPShippingInfoViewController"
            case .STPAUBECSFormViewController: return "STPAUBECSFormViewController"
            case .STPCardFormViewController: return "STPCardFormViewController"
            case .ChangeTheme: return ""
            case .SwiftUICardFormViewController: return "STPCardFormView.Representable"
            case .PaymentMethodMessagingView: return "PaymentMethodMessagingView"
            }
        }
    }

    let customerContext: MockCustomerContext = {
        let keyManager = STPEphemeralKeyManager(
            keyProvider: MockKeyProvider(),
            apiVersion: STPAPIClient.apiVersion,
            performsEagerFetching: true)
        return MockCustomerContext(keyManager: keyManager, apiClient: .shared)
    }()
    let themeViewController = ThemeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stripe UI Examples"
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        navigationController?.navigationBar.isTranslucent = false
    }

    // MARK: UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Demo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        if let example = Demo(rawValue: indexPath.row) {
            cell.textLabel?.text = example.title
            cell.detailTextLabel?.text = example.detail
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let example = Demo(rawValue: indexPath.row) else { return }
        let theme = themeViewController.theme.stpTheme

        switch example {
        case .STPPaymentCardTextField:
            let viewController = CardFieldViewController()
            viewController.theme = theme
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPAddCardViewController:
            let config = STPPaymentConfiguration()
            config.cardScanningEnabled = true
            let viewController = STPAddCardViewController(configuration: config, theme: theme)
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPAddCardViewControllerWithAddress:
            let config = STPPaymentConfiguration()
            config.cardScanningEnabled = true
            config.requiredBillingAddressFields = .full
            let viewController = STPAddCardViewController(configuration: config, theme: theme)
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPPaymentOptionsFPXViewController:
            let config = STPPaymentConfiguration()
            config.fpxEnabled = true
            config.requiredBillingAddressFields = .none
            config.appleMerchantIdentifier = "dummy-merchant-id"
            config.cardScanningEnabled = true
            let viewController = STPPaymentOptionsViewController(
                configuration: config,
                theme: theme,
                customerContext: self.customerContext,
                delegate: self)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPPaymentOptionsViewController:
            let config = STPPaymentConfiguration()
            config.requiredBillingAddressFields = .none
            config.appleMerchantIdentifier = "dummy-merchant-id"
            config.cardScanningEnabled = true
            let viewController = STPPaymentOptionsViewController(
                configuration: config,
                theme: theme,
                customerContext: self.customerContext,
                delegate: self)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPShippingInfoViewController:
            let config = STPPaymentConfiguration()
            config.requiredShippingAddressFields = [.postalAddress]
            let viewController = STPShippingAddressViewController(
                configuration: config,
                theme: theme,
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: nil)
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPAUBECSFormViewController:
            let viewController = AUBECSDebitFormViewController()
            viewController.theme = theme
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPCardFormViewController:
            let viewController = CardFormViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .ChangeTheme:
            let navigationController = UINavigationController(
                rootViewController: self.themeViewController)
            present(navigationController, animated: true, completion: nil)
        case .SwiftUICardFormViewController:
            if #available(iOS 13.0.0, *) {
                let controller = UIHostingController(rootView: SwiftUICardFormView())
                present(controller, animated: true, completion: nil)
            } else {
                // Fallback on earlier versions
                assertionFailure()
            }
        case .PaymentMethodMessagingView:
            let vc = PaymentMethodMessagingViewController()
            let navigationController = UINavigationController(rootViewController: vc)
            present(navigationController, animated: true, completion: nil)
        }
    }

    // MARK: STPAddCardViewControllerDelegate

    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        dismiss(animated: true, completion: nil)
    }

    func addCardViewController(
        _ addCardViewController: STPAddCardViewController,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        completion: @escaping STPErrorBlock
    ) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: STPPaymentOptionsViewControllerDelegate

    func paymentOptionsViewControllerDidCancel(
        _ paymentOptionsViewController: STPPaymentOptionsViewController
    ) {
        dismiss(animated: true, completion: nil)
    }

    func paymentOptionsViewControllerDidFinish(
        _ paymentOptionsViewController: STPPaymentOptionsViewController
    ) {
        dismiss(animated: true, completion: nil)
    }

    func paymentOptionsViewController(
        _ paymentOptionsViewController: STPPaymentOptionsViewController,
        didFailToLoadWithError error: Error
    ) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: STPShippingAddressViewControllerDelegate

    func shippingAddressViewControllerDidCancel(
        _ addressViewController: STPShippingAddressViewController
    ) {
        dismiss(animated: true, completion: nil)
    }

    func shippingAddressViewController(
        _ addressViewController: STPShippingAddressViewController,
        didFinishWith address: STPAddress,
        shippingMethod method: PKShippingMethod?
    ) {
        self.customerContext.updateCustomer(withShippingAddress: address, completion: nil)
        dismiss(animated: true, completion: nil)
    }

    func shippingAddressViewController(
        _ addressViewController: STPShippingAddressViewController,
        didEnter address: STPAddress,
        completion: @escaping STPShippingMethodsCompletionBlock
    ) {
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        let upsWorldwide = PKShippingMethod()
        upsWorldwide.amount = 10.99
        upsWorldwide.label = "UPS Worldwide Express"
        upsWorldwide.detail = "Arrives in 1-3 days"
        upsWorldwide.identifier = "ups_worldwide"
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if address.country == nil || address.country == "US" {
                completion(.valid, nil, [upsGround, fedEx], fedEx)
            } else if address.country == "AQ" {
                let error = NSError(
                    domain: "ShippingError", code: 123,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Invalid Shipping Address",
                        NSLocalizedFailureReasonErrorKey: "We can't ship to this country.",
                    ])
                completion(.invalid, error, nil, nil)
            } else {
                fedEx.amount = 20.99
                completion(.valid, nil, [upsWorldwide, fedEx], fedEx)
            }
        }
    }

}
