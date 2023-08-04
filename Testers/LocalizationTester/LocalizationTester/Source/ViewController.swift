//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  ViewController.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import PassKit
@testable import Stripe

enum LocalizedScreen : Int {
    case paymentCardTextField = 0
    case addCardVCStandard
    case addCardVCPrefilledShipping
    case addCardPrefilledDelivery
    case paymentOptionsVC
    case paymentOptionsVCLoading
    case shippingAddressVC
    case shippingAddressVCBadAddress
    case shippingAddressVCCountryOutsideAvailable
    case shippingAddressVCDelivery
    case shippingAddressVCContact
}

private func TitleForLocalizedScreen(_ screen: LocalizedScreen) -> String? {
    switch screen {
    case .paymentCardTextField:
        return "Payment Card Text Field"
    case .addCardVCStandard:
        return "Add Card VC Standard"
    case .addCardVCPrefilledShipping:
        return "Add Card VC Prefilled Shipping"
    case .addCardPrefilledDelivery:
        return "Add Card VC Prefilled Delivery"
    case .paymentOptionsVC:
        return "Payment Options VC"
    case .paymentOptionsVCLoading:
        return "Payment Options VC Loading"
    case .shippingAddressVC:
        return "Shipping Address VC"
    case .shippingAddressVCBadAddress:
        return "Shipping Address VC Bad Address"
    case .shippingAddressVCCountryOutsideAvailable:
        return "Shipping Address VC Country Outside Available"
    case .shippingAddressVCDelivery:
        return "Shipping Address VC for Delivery"
    case .shippingAddressVCContact:
        return "Shipping Address VC for Contact"
    }
}

class ViewController: UITableViewController, STPAddCardViewControllerDelegate, STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate {
    private var screenTypes: [NSNumber]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        screenTypes = [
            NSNumber(value: LocalizedScreen.paymentCardTextField.rawValue),
            NSNumber(value: LocalizedScreen.addCardVCStandard.rawValue),
            NSNumber(value: LocalizedScreen.addCardVCPrefilledShipping.rawValue),
            NSNumber(value: LocalizedScreen.addCardPrefilledDelivery.rawValue),
            NSNumber(value: LocalizedScreen.paymentOptionsVC.rawValue),
            NSNumber(value: LocalizedScreen.paymentOptionsVCLoading.rawValue),
            NSNumber(value: LocalizedScreen.shippingAddressVC.rawValue),
            NSNumber(value: LocalizedScreen.shippingAddressVCBadAddress.rawValue),
            NSNumber(value: LocalizedScreen.shippingAddressVCCountryOutsideAvailable.rawValue),
            NSNumber(value: LocalizedScreen.shippingAddressVCDelivery.rawValue),
            NSNumber(value: LocalizedScreen.shippingAddressVCContact.rawValue),
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenTypes?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }

        let screenType = LocalizedScreen(rawValue: screenTypes?[indexPath.row].intValue ?? 0)

        if let screenType {
            cell?.textLabel?.text = TitleForLocalizedScreen(screenType)
        }
        return cell!
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let screenType = LocalizedScreen(rawValue: screenTypes?[indexPath.row].intValue ?? 0)
        var vc: UIViewController = UIViewController()
        switch screenType {
        case .paymentCardTextField:
            let cardTextField = STPPaymentCardTextField()
            cardTextField.postalCodeEntryEnabled = true
            cardTextField.translatesAutoresizingMaskIntoConstraints = false
            let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cardTextFieldViewControllerDidSelectDone))
            doneItem.accessibilityIdentifier = "CardFieldViewControllerDoneButtonIdentifier"
            vc.navigationItem.leftBarButtonItem = doneItem
            vc.view.backgroundColor = .white
            vc.view.addSubview(cardTextField)
            NSLayoutConstraint.activate(
                [
                    cardTextField.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
                    cardTextField.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 15),
                    cardTextField.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -15),
                    cardTextField.heightAnchor.constraint(equalToConstant: 50),
                ])
        case .addCardVCStandard:
            let configuration = STPPaymentConfiguration()
            configuration.requiredBillingAddressFields = .full
            let addCardVC = STPAddCardViewController(configuration: configuration, theme: STPTheme.default())
            addCardVC.alwaysEnableDoneButton = true
            addCardVC.delegate = self
            vc = addCardVC
        case .addCardVCPrefilledShipping:
            let configuration = STPPaymentConfiguration()
            configuration.shippingType = .shipping
            configuration.requiredBillingAddressFields = .full
            let addCardVC = STPAddCardViewController(configuration: configuration, theme: STPTheme.default())
            addCardVC.shippingAddress = STPAddress()
            addCardVC.shippingAddress!.line1 = "1" // trigger "use shipping address" button
            addCardVC.delegate = self
            vc = addCardVC
        case .addCardPrefilledDelivery:
            let configuration = STPPaymentConfiguration()
            configuration.shippingType = .delivery
            configuration.requiredBillingAddressFields = .full
            let addCardVC = STPAddCardViewController(configuration: configuration, theme: STPTheme.default())
            addCardVC.shippingAddress = STPAddress()
            addCardVC.shippingAddress!.line1 = "1" // trigger "use delivery address" button
            addCardVC.delegate = self
            vc = addCardVC
        case .paymentOptionsVC:
            let configuration = STPPaymentConfiguration()
            configuration.requiredBillingAddressFields = .full
            configuration.appleMerchantIdentifier = "dummy-merchant-id"
            vc = STPPaymentOptionsViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                apiAdapter: MockCustomerContext(),
                delegate: self)
        case .paymentOptionsVCLoading:
            let configuration = STPPaymentConfiguration()
            configuration.requiredBillingAddressFields = .full
            configuration.appleMerchantIdentifier = "dummy-merchant-id"
            let customerContext = MockCustomerContext()
            customerContext.neverRetrieveCustomer = true
            vc = STPPaymentOptionsViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                apiAdapter: customerContext,
                delegate: self)
        case .shippingAddressVC:
            let configuration = STPPaymentConfiguration()
            configuration.requiredShippingAddressFields = Set([STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name])
            let prefilledInfo = STPUserInformation()
            let billingAddress = STPAddress()
            billingAddress.name = "Test"
            billingAddress.email = "test@test.com"
            billingAddress.phone = "9311111111"
            billingAddress.line1 = "Test"
            billingAddress.line2 = "Test"
            billingAddress.postalCode = "1001"
            billingAddress.city = "Kabul"
            billingAddress.state = "Kabul"
            billingAddress.country = "AF"
            prefilledInfo.billingAddress = billingAddress

            let shippingAddressVC = STPShippingAddressViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: prefilledInfo)
            shippingAddressVC.delegate = self
            vc = shippingAddressVC
        case .shippingAddressVCBadAddress:
            let configuration = STPPaymentConfiguration()
            configuration.requiredShippingAddressFields = Set([STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name])
            let prefilledInfo = STPUserInformation()
            let billingAddress = STPAddress()
            billingAddress.name = "Test"
            billingAddress.email = "test@test.com"
            billingAddress.phone = "9311111111"
            billingAddress.line1 = "Test"
            billingAddress.line2 = "Test"
            billingAddress.postalCode = "90026"
            billingAddress.city = "Kabul"
            billingAddress.state = "Kabul"
            billingAddress.country = "US" // We're just going to hard code that "US" country triggers failure below
            prefilledInfo.billingAddress = billingAddress

            let shippingAddressVC = STPShippingAddressViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: prefilledInfo)
            shippingAddressVC.delegate = self
            vc = shippingAddressVC
        case .shippingAddressVCCountryOutsideAvailable:
            let configuration = STPPaymentConfiguration()
            configuration.requiredShippingAddressFields = Set([STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name])
            configuration.availableCountries = Set(["BT"])
            let prefilledInfo = STPUserInformation()
            let billingAddress = STPAddress()
            billingAddress.name = "Test"
            billingAddress.country = "GB"
            prefilledInfo.billingAddress = billingAddress

            let shippingAddressVC = STPShippingAddressViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: prefilledInfo)
            shippingAddressVC.delegate = self
            vc = shippingAddressVC
        case .shippingAddressVCDelivery:
            let configuration = STPPaymentConfiguration()
            configuration.shippingType = .delivery
            configuration.requiredShippingAddressFields = Set([STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name])

            let shippingAddressVC = STPShippingAddressViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: nil)
            shippingAddressVC.delegate = self
            vc = shippingAddressVC
        case .shippingAddressVCContact:
            let configuration = STPPaymentConfiguration()
            configuration.requiredShippingAddressFields = Set([STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name])

            let shippingAddressVC = STPShippingAddressViewController(
                configuration: configuration,
                theme: STPTheme.default(),
                currency: "usd",
                shippingAddress: nil,
                selectedShippingMethod: nil,
                prefilledInformation: nil)
            shippingAddressVC.delegate = self
            vc = shippingAddressVC
        case .none:
            assertionFailure()
        }
        navigationController!.pushViewController(vc, animated: false)
    }

    // MARK: - Card Text Field

    @objc func cardTextFieldViewControllerDidSelectDone() {
        navigationController!.popToRootViewController(animated: false)
    }

    // MARK: - STPAddCardViewControllerDelegate

    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController?) {
        navigationController!.popToRootViewController(animated: false)
    }

    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping (Error?) -> Void) {
        navigationController!.popToRootViewController(animated: false)
    }

    // MARK: - STPPaymentOptionssViewControllerDelegate

    func paymentOptionsViewController(
        _ paymentOptionsViewController: STPPaymentOptionsViewController?,
        didFailToLoadWithError error: Error?
    ) {
        navigationController!.popToRootViewController(animated: false)
    }

    func paymentOptionsViewControllerDidFinish(_ paymentOptionsViewController: STPPaymentOptionsViewController?) {
        navigationController!.popToRootViewController(animated: false)
    }

    func paymentOptionsViewControllerDidCancel(_ paymentOptionsViewController: STPPaymentOptionsViewController?) {
        navigationController!.popToRootViewController(animated: false)
    }

    // MARK: - STPShippingAddressViewControllerDelegate

    func shippingAddressViewControllerDidCancel(_ addressViewController: STPShippingAddressViewController?) {
        navigationController!.popToRootViewController(animated: false)
    }

    func shippingAddressViewController(_ addressViewController: STPShippingAddressViewController, didEnter address: STPAddress, completion: @escaping (STPShippingStatus, Error?, [PKShippingMethod]?, PKShippingMethod?) -> Void) {
        let upsGround = PKShippingMethod()
        upsGround.amount = NSDecimalNumber(string: "0")
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        let upsWorldwide = PKShippingMethod()
        upsWorldwide.amount = NSDecimalNumber(string: "10.99")
        upsWorldwide.label = "UPS Worldwide Express"
        upsWorldwide.detail = "Arrives in 1-3 days"
        upsWorldwide.identifier = "ups_worldwide"
        let fedEx = PKShippingMethod()
        fedEx.amount = NSDecimalNumber(string: "5.99")
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"

        if address.country == nil || (address.country == "US") {
            completion(.invalid, nil, nil, nil)
        }
    }

    func shippingAddressViewController(
        _ addressViewController: STPShippingAddressViewController?,
        didFinishWith address: STPAddress?,
        shippingMethod method: PKShippingMethod?
    ) {
        navigationController!.popToRootViewController(animated: false)
    }
}
