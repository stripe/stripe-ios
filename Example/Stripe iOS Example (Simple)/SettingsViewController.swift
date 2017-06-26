//
//  SettingsViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 6/17/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class Settings {
    static let shared = Settings()

    var theme: STPTheme = STPTheme.default()
    var additionalPaymentMethods: STPPaymentMethodType = .all
    var requiredBillingAddressFields: STPBillingAddressFields = .none
    var requiredShippingAddressFields: PKAddressField = []
    var shippingType: STPShippingType = .shipping
    var smsAutofillEnabled: Bool = false
}

class SettingsViewController: UITableViewController {
    func updateSettings() {
        Settings.shared.theme = self.theme.stpTheme
        Settings.shared.additionalPaymentMethods = self.applePay.enabled ? .all : STPPaymentMethodType()
        Settings.shared.requiredBillingAddressFields = self.requiredBillingAddressFields.stpBillingAddressFields
        Settings.shared.requiredShippingAddressFields = self.requiredShippingAddressFields.pkAddressFields
        Settings.shared.shippingType = self.shippingType.stpShippingType
        Settings.shared.smsAutofillEnabled = self.smsAutofill.enabled
    }

    var theme: Theme = .Default
    var applePay: Switch = .Enabled
    var requiredBillingAddressFields: RequiredBillingAddressFields = .None
    var requiredShippingAddressFields: RequiredShippingAddressFields = .PostalAddressPhone
    var shippingType: ShippingType = .Shipping
    var smsAutofill: Switch = .Enabled

    enum Section: String {
        case Theme = "Theme"
        case ApplePay = "Apple Pay"
        case RequiredBillingAddressFields = "Required Billing Address Fields"
        case RequiredShippingAddressFields = "Required Shipping Address Fields"
        case ShippingType = "Shipping Type"
        case SMSAutofill = "SMS Autofill"
        case Session = "Session"

        init(section: Int) {
            switch section {
            case 0: self = .Theme
            case 1: self = .ApplePay
            case 2: self = .RequiredBillingAddressFields
            case 3: self = .RequiredShippingAddressFields
            case 4: self = .ShippingType
            case 5: self = .SMSAutofill
            default: self = .Session
            }
        }
    }

    enum Theme: String {
        case Default = "Default"
        case CustomLight = "Custom – Light"
        case CustomDark = "Custom – Dark"

        init(row: Int) {
            switch row {
            case 0: self = .Default
            case 1: self = .CustomLight
            default: self = .CustomDark
            }
        }

        var stpTheme: STPTheme {
            switch self {
            case .Default:
                return STPTheme.default()
            case .CustomLight:
                let theme = STPTheme()
                theme.primaryBackgroundColor = UIColor(red:0.96, green:0.96, blue:0.95, alpha:1.00)
                theme.secondaryBackgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
                theme.primaryForegroundColor = UIColor(red:0.35, green:0.35, blue:0.35, alpha:1.00)
                theme.secondaryForegroundColor = UIColor(red:0.66, green:0.66, blue:0.66, alpha:1.00)
                theme.accentColor = UIColor(red:0.09, green:0.81, blue:0.51, alpha:1.00)
                theme.errorColor = UIColor(red:0.87, green:0.18, blue:0.20, alpha:1.00)
                theme.font = UIFont(name: "ChalkboardSE-Light", size: 17)
                theme.emphasisFont = UIFont(name: "ChalkboardSE-Bold", size: 17)
                return theme
            case .CustomDark:
                let theme = STPTheme()
                theme.primaryBackgroundColor = UIColor(red:0.16, green:0.23, blue:0.31, alpha:1.00)
                theme.secondaryBackgroundColor = UIColor(red:0.22, green:0.29, blue:0.38, alpha:1.00)
                theme.primaryForegroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
                theme.secondaryForegroundColor = UIColor(red:0.60, green:0.64, blue:0.71, alpha:1.00)
                theme.accentColor = UIColor(red:0.98, green:0.80, blue:0.00, alpha:1.00)
                theme.errorColor = UIColor(red:0.85, green:0.48, blue:0.48, alpha:1.00)
                theme.font = UIFont(name: "GillSans", size: 17)
                theme.emphasisFont = UIFont(name: "GillSans", size: 17)
                return theme
            }
        }
    }

    enum Switch: String {
        case Enabled = "Enabled"
        case Disabled = "Disabled"

        init(row: Int) {
            self = (row == 0) ? .Enabled : .Disabled
        }

        var enabled: Bool {
            return self == .Enabled
        }
    }

    enum RequiredBillingAddressFields: String {
        case None = "None"
        case Zip = "Zip"
        case Full = "Full"

        init(row: Int) {
            switch row {
            case 0: self = .None
            case 1: self = .Zip
            default: self = .Full
            }
        }

        var stpBillingAddressFields: STPBillingAddressFields {
            switch self {
            case .None: return .none
            case .Zip: return .zip
            case .Full: return .full
            }
        }
    }

    enum RequiredShippingAddressFields: String {
        case None = "None"
        case Email = "Email"
        case PostalAddressPhone = "(PostalAddress|Phone)"
        case All = "All"

        init(row: Int) {
            switch row {
            case 0: self = .None
            case 1: self = .Email
            case 2: self = .PostalAddressPhone
            default: self = .All
            }
        }

        var pkAddressFields: PKAddressField {
            switch self {
            case .None: return []
            case .Email: return .email
            case .PostalAddressPhone: return [.postalAddress, .phone]
            case .All: return .all
            }
        }
    }

    enum ShippingType: String {
        case Shipping = "Shipping"
        case Delivery = "Delivery"

        init(row: Int) {
            switch row {
            case 0: self = .Shipping
            default: self = .Delivery
            }
        }

        var stpShippingType: STPShippingType {
            switch self {
            case .Shipping: return .shipping
            case .Delivery: return .delivery
            }
        }
    }

    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section: section) {
        case .Theme: return 3
        case .ApplePay: return 2
        case .RequiredBillingAddressFields: return 3
        case .RequiredShippingAddressFields: return 4
        case .ShippingType: return 2
        case .SMSAutofill: return 2
        case .Session: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(section: section).rawValue
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        switch Section(section: (indexPath as NSIndexPath).section) {
        case .Theme:
            let value = Theme(row: (indexPath as NSIndexPath).row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.theme ? .checkmark : .none
        case .ApplePay:
            let value = Switch(row: (indexPath as NSIndexPath).row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.applePay ? .checkmark : .none
        case .RequiredBillingAddressFields:
            let value = RequiredBillingAddressFields(row: (indexPath as NSIndexPath).row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.requiredBillingAddressFields ? .checkmark : .none
        case .RequiredShippingAddressFields:
            let value = RequiredShippingAddressFields(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.requiredShippingAddressFields ? .checkmark : .none
        case .ShippingType:
            let value = ShippingType(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.shippingType ? .checkmark : .none
        case .SMSAutofill:
            let value = Switch(row: (indexPath as NSIndexPath).row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.smsAutofill ? .checkmark : .none
        case .Session:
            cell.textLabel?.text = "Log out"
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(section: (indexPath as NSIndexPath).section) {
        case .Theme:
            self.theme = Theme(row: (indexPath as NSIndexPath).row)
        case .ApplePay:
            self.applePay = Switch(row: (indexPath as NSIndexPath).row)
        case .RequiredBillingAddressFields:
            self.requiredBillingAddressFields = RequiredBillingAddressFields(row: (indexPath as NSIndexPath).row)
        case .RequiredShippingAddressFields:
            self.requiredShippingAddressFields = RequiredShippingAddressFields(row: (indexPath as NSIndexPath).row)
        case .ShippingType:
            self.shippingType = ShippingType(row: (indexPath as NSIndexPath).row)
        case .SMSAutofill:
            self.smsAutofill = Switch(row: (indexPath as NSIndexPath).row)
        case .Session:
            MyAPIClient.shared.logout { error in
                if error == nil {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }
        self.updateSettings()
        tableView.reloadSections(IndexSet(integer: (indexPath as NSIndexPath).section), with: .automatic)
    }
}
