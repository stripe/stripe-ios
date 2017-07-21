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

    enum Demo: Int {
        static let count = 5
        case STPPaymentCardTextField
        case STPAddCardViewController
        case STPPaymentMethodsViewController
        case STPShippingInfoViewController
        case ChangeTheme

        var title: String {
            switch self {
            case .STPPaymentCardTextField: return "Card Field"
            case .STPAddCardViewController: return "Card Form with Billing Address"
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
            config.requiredBillingAddressFields = .full
            let viewController = STPAddCardViewController(configuration: config, theme: theme)
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

