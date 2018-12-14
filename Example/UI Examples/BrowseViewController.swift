//
//  BrowseViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class BrowseViewController: UITableViewController, STPAddCardViewControllerDelegate, STPPaymentMethodsViewControllerDelegate, STPShippingAddressViewControllerDelegate {

    enum Demo {
        static let count = 7
        case STPPaymentCardTextField
        enum AddCardViewControllerState {
            case standard
            case prefilledShipping
            case prefilledDelivery
        }
        case STPAddCardViewController(AddCardViewControllerState)
        case STPPaymentMethodsViewController
        case STPShippingInfoViewController
        case ChangeTheme

        init?(row: Int) {
            switch row {
            case 0:
                self = .STPPaymentCardTextField
            case 1:
                self = .STPAddCardViewController(.standard)
            case 2:
                self = .STPAddCardViewController(.prefilledShipping)
            case 3:
                self = .STPAddCardViewController(.prefilledDelivery)
            case 4:
                self = .STPPaymentMethodsViewController
            case 5:
                self = .STPShippingInfoViewController
            case 6:
                self = .ChangeTheme
            default:
                return nil
            }
        }

        var title: String {
            switch self {
            case .STPPaymentCardTextField: return "Card Field"
            case .STPAddCardViewController(let state):
                switch state {
                case .standard:
                    return "Card Form with Billing Address"
                case .prefilledShipping:
                    return "Card Form with Prefilled Shipping Address"
                case .prefilledDelivery:
                    return "Card Form with Prefilled Delivery Address"
                }
            case .STPPaymentMethodsViewController: return "Payment Method Picker"
            case .STPShippingInfoViewController: return "Shipping Info Form"
            case .ChangeTheme: return "Change Theme"
            }
        }

        var detail: String {
            switch self {
            case .STPPaymentCardTextField: return "STPPaymentCardTextField"
            case .STPAddCardViewController: return "STPAddCardViewController"
            case .STPPaymentMethodsViewController: return "STPPaymentMethodsViewController"
            case .STPShippingInfoViewController: return "STPShippingInfoViewController"
            case .ChangeTheme: return ""
            }
        }
    }

    let customerContext = MockCustomerContext()
    let themeViewController = ThemeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stripe UI Examples"
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        navigationController?.navigationBar.isTranslucent = false
        STPAddCardViewController.startMockingAPIClient()
    }

    // MARK: UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Demo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        if let example = Demo(row: indexPath.row) {
            cell.textLabel?.text = example.title
            cell.detailTextLabel?.text = example.detail
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let example = Demo(row: indexPath.row) else { return }
        let theme = themeViewController.theme.stpTheme

        switch example {
        case .STPPaymentCardTextField:
            let viewController = CardFieldViewController()
            viewController.theme = theme
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPAddCardViewController(let state):
            // TODO : Use state
            let config = STPPaymentConfiguration()
            config.requiredBillingAddressFields = .full
            let viewController: STPAddCardViewController = {
            switch state {
            case .standard:
                return STPAddCardViewController(configuration: config, theme: theme)
            case .prefilledShipping:
                config.shippingType = STPShippingType.shipping
                let viewController = STPAddCardViewController(configuration: config, theme: theme)
                viewController.shippingAddress = STPAddress()
                viewController.shippingAddress.line1 = "1"; // trigger "use shipping address" button
                return viewController
            case .prefilledDelivery:
                config.shippingType = STPShippingType.delivery
                let viewController = STPAddCardViewController(configuration: config, theme: theme)
                viewController.shippingAddress = STPAddress()
                viewController.shippingAddress.line1 = "1"; // trigger "use delivery address" button
                return viewController

            }
            }()
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPPaymentMethodsViewController:
            let config = STPPaymentConfiguration()
            config.additionalPaymentMethods = .all
            config.requiredBillingAddressFields = .none
            config.appleMerchantIdentifier = "dummy-merchant-id"
            let viewController = STPPaymentMethodsViewController(configuration: config,
                                                                 theme: theme,
                                                                 customerContext: self.customerContext,
                                                                 delegate: self)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .STPShippingInfoViewController:
            let config = STPPaymentConfiguration()
            config.requiredShippingAddressFields = [.postalAddress]
            let viewController = STPShippingAddressViewController(configuration: config,
                                                                  theme: theme,
                                                                  currency: "usd",
                                                                  shippingAddress: nil,
                                                                  selectedShippingMethod: nil,
                                                                  prefilledInformation: nil)
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            present(navigationController, animated: true, completion: nil)
        case .ChangeTheme:
            let navigationController = UINavigationController(rootViewController: self.themeViewController)
            present(navigationController, animated: true, completion: nil)
        }
    }

    // MARK: STPAddCardViewControllerDelegate

    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        dismiss(animated: true, completion: nil)
    }

    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: STPPaymentMethodsViewControllerDelegate

    func paymentMethodsViewControllerDidCancel(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        dismiss(animated: true, completion: nil)
    }

    func paymentMethodsViewControllerDidFinish(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        paymentMethodsViewController.navigationController?.popViewController(animated: true)
    }

    func paymentMethodsViewController(_ paymentMethodsViewController: STPPaymentMethodsViewController, didFailToLoadWithError error: Error) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: STPShippingAddressViewControllerDelegate

    func shippingAddressViewControllerDidCancel(_ addressViewController: STPShippingAddressViewController) {
        dismiss(animated: true, completion: nil)
    }

    func shippingAddressViewController(_ addressViewController: STPShippingAddressViewController, didFinishWith address: STPAddress, shippingMethod method: PKShippingMethod?) {
        self.customerContext.updateCustomer(withShippingAddress: address, completion: nil)
        dismiss(animated: true, completion: nil)
    }

    func shippingAddressViewController(_ addressViewController: STPShippingAddressViewController, didEnter address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
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
            }
            else if address.country == "AQ" {
                let error = NSError(domain: "ShippingError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Invalid Shipping Address",
                                                                                   NSLocalizedFailureReasonErrorKey: "We can't ship to this country."])
                completion(.invalid, error, nil, nil)
            }
            else {
                fedEx.amount = 20.99
                completion(.valid, nil, [upsWorldwide, fedEx], fedEx)
            }
        }       
    }

}

