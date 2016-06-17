//
//  SettingsViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 6/17/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

struct Settings {
    let theme: STPTheme
    let additionalPaymentMethods: STPPaymentMethodType
    let requiredBillingAddressFields: STPBillingAddressFields
    let smsAutofillEnabled: Bool
}

class SettingsViewController: UITableViewController {
    var settings: Settings {
        return Settings(theme: self.theme.stpTheme,
                        additionalPaymentMethods: self.applePay.enabled ? .All : .None,
                        requiredBillingAddressFields: self.requiredBillingAddressFields.stpBillingAddressFields,
                        smsAutofillEnabled: self.smsAutofill.enabled)
    }

    private var theme: Theme = .Default
    private var applePay: Switch = .Enabled
    private var requiredBillingAddressFields: RequiredBillingAddressFields = .None
    private var smsAutofill: Switch = .Enabled

    private enum Section: String {
        case Theme = "Theme"
        case ApplePay = "Apple Pay"
        case RequiredBillingAddressFields = "Required Billing Address Fields"
        case SMSAutofill = "SMS Autofill"

        init(section: Int) {
            switch section {
            case 0: self = Theme
            case 1: self = ApplePay
            case 2: self = RequiredBillingAddressFields
            default: self = SMSAutofill
            }
        }
    }

    private enum Theme: String {
        case Default = "Default"
        case CustomLight = "Custom – Light"
        case CustomDark = "Custom – Dark"

        init(row: Int) {
            switch row {
            case 0: self = Default
            case 1: self = CustomLight
            default: self = CustomDark
            }
        }

        var stpTheme: STPTheme {
            switch self {
            case .Default:
                return STPTheme.defaultTheme()
            case .CustomLight:
                let theme = STPTheme()
                theme.primaryBackgroundColor = UIColor(red:0.96, green:0.93, blue:0.87, alpha:1.00)
                theme.secondaryBackgroundColor = UIColor(red:0.98, green:0.95, blue:0.88, alpha:1.00)
                theme.primaryForegroundColor = UIColor(red:0.42, green:0.44, blue:0.76, alpha:1.00)
                theme.secondaryForegroundColor = UIColor(red:0.64, green:0.66, blue:0.68, alpha:1.00)
                theme.accentColor = UIColor(red:0.84, green:0.18, blue:0.51, alpha:1.00)
                theme.errorColor = UIColor(red:0.87, green:0.18, blue:0.20, alpha:1.00)
                theme.font = UIFont(name: "Noteworthy-Light", size: 17)
                theme.emphasisFont = UIFont(name: "Noteworthy-Bold", size: 17)
                return theme
            case .CustomDark:
                let theme = STPTheme()
                theme.primaryBackgroundColor = UIColor(red:0.13, green:0.14, blue:0.15, alpha:1.00)
                theme.secondaryBackgroundColor = UIColor(red:0.14, green:0.15, blue:0.16, alpha:1.00)
                theme.primaryForegroundColor = UIColor(white:0.9, alpha:1.00)
                theme.secondaryForegroundColor = UIColor(white:0.7, alpha:1.00)
                theme.accentColor = UIColor(red:0.91, green:0.64, blue:0.46, alpha:1.00)
                theme.errorColor = UIColor(red:0.85, green:0.48, blue:0.48, alpha:1.00)
                theme.font = UIFont(name: "Palatino-Roman", size: 17)
                theme.emphasisFont = UIFont(name: "Palatino-Bold", size: 17)
                return theme
            }
        }
    }

    private enum Switch: String {
        case Enabled = "Enabled"
        case Disabled = "Disabled"

        init(row: Int) {
            self = (row == 0) ? Enabled : Disabled
        }

        var enabled: Bool {
            return self == .Enabled
        }
    }

    private enum RequiredBillingAddressFields: String {
        case None = "None"
        case Zip = "Zip"
        case Full = "Full"

        init(row: Int) {
            switch row {
            case 0: self = None
            case 1: self = Zip
            default: self = Full
            }
        }

        var stpBillingAddressFields: STPBillingAddressFields {
            switch self {
            case .None: return .None
            case .Zip: return .Zip
            case .Full: return .Full
            }
        }
    }

    convenience init() {
        self.init(style: .Grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(dismiss))
    }

    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section: section) {
        case .Theme: return 3
        case .ApplePay: return 2
        case .RequiredBillingAddressFields: return 3
        case .SMSAutofill: return 2
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(section: section).rawValue
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        switch Section(section: indexPath.section) {
        case .Theme:
            let value = Theme(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.theme ? .Checkmark : .None
        case .ApplePay:
            let value = Switch(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.applePay ? .Checkmark : .None
        case .RequiredBillingAddressFields:
            let value = RequiredBillingAddressFields(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.requiredBillingAddressFields ? .Checkmark : .None
        case .SMSAutofill:
            let value = Switch(row: indexPath.row)
            cell.textLabel?.text = value.rawValue
            cell.accessoryType = value == self.smsAutofill ? .Checkmark : .None
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch Section(section: indexPath.section) {
        case .Theme:
            self.theme = Theme(row: indexPath.row)
        case .ApplePay:
            self.applePay = Switch(row: indexPath.row)
        case .RequiredBillingAddressFields:
            self.requiredBillingAddressFields = RequiredBillingAddressFields(row: indexPath.row)
        case .SMSAutofill:
            self.smsAutofill = Switch(row: indexPath.row)
        }
        tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
    }
}
