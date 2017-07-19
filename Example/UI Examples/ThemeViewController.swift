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
        static let count = 2
        case Default = "Default"
        case CustomDark = "Custom"

        init?(row: Int) {
            switch row {
            case 0: self = .Default
            case 1: self = .CustomDark
            default: return nil
            }
        }

        var stpTheme: STPTheme {
            switch self {
            case .Default:
                return STPTheme.default()
            case .CustomDark:
                let theme = STPTheme.default()
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

    var theme: Theme = .Default

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Change Theme"
        self.tableView.tableFooterView = UIView()
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
    }


}
