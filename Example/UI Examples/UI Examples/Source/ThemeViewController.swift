//
//  ThemeViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/19/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Stripe
import UIKit

class ThemeViewController: UITableViewController {

    enum Theme: String {
        static let count = 2
        case Default = "Default"
        case Custom = "Custom"

        init?(row: Int) {
            switch row {
            case 0: self = .Default
            case 1: self = .Custom
            default: return nil
            }
        }

    }

    var theme: Theme = .Default

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Change Theme"
        tableView.tableFooterView = UIView()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Theme.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
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
        tableView.reloadSections(
            IndexSet(integer: (indexPath as NSIndexPath).section), with: .automatic)
        dismiss(animated: true, completion: nil)
    }

}
