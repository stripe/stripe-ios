//
//  ThemeViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/19/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class ThemeViewController: UITableViewController {

    enum Theme: String {
        static let count = 3
        case Default = "Default"
        case CustomDark = "Custom - Dark"
        case CustomLight = "Custom - Light"

        init?(row: Int) {
            switch row {
            case 0: self = .Default
            case 1: self = .CustomDark
            case 2: self = .CustomLight
            default: return nil
            }
        }

        var stpTheme: STPTheme {
            switch self {
            case .Default:
                return STPTheme.default()
            case .CustomDark:
                let theme = STPTheme.default()
                theme.primaryBackgroundColor = UIColor(red:66.0/255.0, green:69.0/255.0, blue:112.0/255.0, alpha:255.0/255.0)
                theme.secondaryBackgroundColor = theme.primaryBackgroundColor
                theme.primaryForegroundColor = UIColor.white
                theme.secondaryForegroundColor = UIColor(red:130.0/255.0, green:147.0/255.0, blue:168.0/255.0, alpha:255.0/255.0)
                theme.accentColor = UIColor(red:14.0/255.0, green:211.0/255.0, blue:140.0/255.0, alpha:255.0/255.0)
                theme.errorColor = UIColor(red:237.0/255.0, green:83.0/255.0, blue:69.0/255.0, alpha:255.0/255.0)
                return theme
            case .CustomLight:
                let theme = STPTheme.default()
                theme.primaryBackgroundColor = UIColor(red:230.0/255.0, green:235.0/255.0, blue:241.0/255.0, alpha:255.0/255.0)
                theme.secondaryBackgroundColor = UIColor.white
                theme.primaryForegroundColor = UIColor(red:55.0/255.0, green:53.0/255.0, blue:100.0/255.0, alpha:255.0/255.0)
                theme.secondaryForegroundColor = UIColor(red:148.0/255.0, green:163.0/255.0, blue:179.0/255.0, alpha:255.0/255.0)
                theme.accentColor = UIColor(red:101.0/255.0, green:101.0/255.0, blue:232.0/255.0, alpha:255.0/255.0)
                theme.errorColor = UIColor(red:240.0/255.0, green:2.0/255.0, blue:36.0/255.0, alpha:255.0/255.0)
                return theme
            }
        }
    }

    var theme: Theme = .Default

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Change Theme"
        tableView.tableFooterView = UIView()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }

    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Theme.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        guard let theme = Theme(row: indexPath.row) else { return cell }
        cell.textLabel?.text = theme.rawValue
        cell.accessoryType = theme == self.theme ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let theme = Theme(row: indexPath.row) else { return }
        self.theme = theme
        tableView.reloadSections(IndexSet(integer: (indexPath as NSIndexPath).section), with: .automatic)
        dismiss(animated: true, completion: nil)
    }


}
