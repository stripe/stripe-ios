//
//  BrowseProductsViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Jack Flintermann on 5/2/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit

class BrowseProductsViewController: UITableViewController {

    let productsAndPrices = [
        "👕": 2000,
        "👖": 4000,
        "👗": 3000,
        "👞": 700,
        "👟": 600,
        "👠": 1000,
        "👡": 2000,
        "👢": 2500,
        "👒": 800,
        "👙": 3000,
        "💄": 2000,
        "🎩": 5000,
        "👛": 5500,
        "👜": 6000,
        "🕶": 2000,
        "👚": 2500,
    ]

    let settingsVC = SettingsViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Emoji Apparel"
        self.navigationController?.navigationBar.translucent = false
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Products", style: .Plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .Plain, target: self, action: #selector(showSettings))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let theme = self.settingsVC.settings.theme
        self.view.backgroundColor = theme.primaryBackgroundColor
        self.navigationController?.navigationBar.barTintColor = theme.primaryBackgroundColor
        self.navigationController?.navigationBar.tintColor = theme.accentColor
        let titleAttributes = [
            NSForegroundColorAttributeName: theme.primaryForegroundColor,
            NSFontAttributeName: theme.font,
        ]
        let buttonAttributes = [
            NSForegroundColorAttributeName: theme.accentColor,
            NSFontAttributeName: theme.font,
        ]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(buttonAttributes, forState: .Normal)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes(buttonAttributes, forState: .Normal)
        self.tableView.separatorColor = theme.primaryBackgroundColor
        self.tableView.reloadData()
    }

    func showSettings() {
        let navController = UINavigationController(rootViewController: settingsVC)
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsAndPrices.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") ?? UITableViewCell(style: .Value1, reuseIdentifier: "Cell")
        let product = Array(self.productsAndPrices.keys)[indexPath.row]
        let price = self.productsAndPrices[product]!
        let theme = self.settingsVC.settings.theme
        cell.backgroundColor = theme.secondaryBackgroundColor
        cell.textLabel?.text = product
        cell.textLabel?.font = theme.font
        cell.textLabel?.textColor = theme.primaryForegroundColor
        cell.detailTextLabel?.text = "$\(price/100).00"
        cell.accessoryType = .DisclosureIndicator
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let product = Array(self.productsAndPrices.keys)[indexPath.row]
        let price = self.productsAndPrices[product]!
        let checkoutViewController = CheckoutViewController(product: product,
                                                            price: price,
                                                            settings: self.settingsVC.settings)
        self.navigationController?.pushViewController(checkoutViewController, animated: true)
    }
}
