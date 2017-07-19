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

    enum Demo: String {
        static let count = 5
        case STPPaymentCardTextField = "Card Field"
        case STPAddCardViewController = "Card Form"
        case STPPaymentMethodsViewController = "Payment Methods"
        case STPShippingInfoViewController = "Shipping Info"
        case ChangeTheme = "Change Theme"

        init?(row: Int) {
            switch row {
            case 0: self = .STPPaymentCardTextField
            case 1: self = .STPAddCardViewController
            case 2: self = .STPPaymentMethodsViewController
            case 3: self = .STPShippingInfoViewController
            case 4: self = .ChangeTheme
            default: return nil
            }
        }
    }

    let customerContext = MockCustomerContext()
    let themeViewController = ThemeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UI Examples"
        self.tableView.tableFooterView = UIView()
        self.navigationController?.navigationBar.isTranslucent = false
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
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if let example = Demo(row: indexPath.row) {
            cell.textLabel?.text = example.rawValue
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let example = Demo(row: indexPath.row) else { return }
        let theme = self.themeViewController.theme.stpTheme

        switch example {
        case .STPPaymentCardTextField:
            let viewController = CardFieldViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        case .STPAddCardViewController:
            let config = STPPaymentConfiguration()
            config.requiredBillingAddressFields = .full
            let viewController = STPAddCardViewController(configuration: config, theme: theme)
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.stp_theme = theme
            self.present(navigationController, animated: true, completion: nil)
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
            self.present(navigationController, animated: true, completion: nil)
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
            self.present(navigationController, animated: true, completion: nil)
        case .ChangeTheme:
            self.navigationController?.pushViewController(self.themeViewController, animated: true)
        }
    }

    // MARK: STPAddCardViewControllerDelegate

    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: STPPaymentMethodsViewControllerDelegate

    func paymentMethodsViewControllerDidCancel(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func paymentMethodsViewControllerDidFinish(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        paymentMethodsViewController.navigationController?.popViewController(animated: true)
    }

    func paymentMethodsViewController(_ paymentMethodsViewController: STPPaymentMethodsViewController, didFailToLoadWithError error: Error) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: STPShippingAddressViewControllerDelegate

    func shippingAddressViewControllerDidCancel(_ addressViewController: STPShippingAddressViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func shippingAddressViewController(_ addressViewController: STPShippingAddressViewController, didFinishWith address: STPAddress, shippingMethod method: PKShippingMethod?) {
        self.customerContext.updateCustomer(withShippingAddress: address, completion: nil)
        self.dismiss(animated: true, completion: nil)
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

