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
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Products", style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let theme = Settings.shared.theme
        self.view.backgroundColor = theme.primaryBackgroundColor
        self.navigationController?.navigationBar.barTintColor = theme.secondaryBackgroundColor
        self.navigationController?.navigationBar.tintColor = theme.accentColor
        let titleAttributes = [
            NSForegroundColorAttributeName: theme.primaryForegroundColor,
            NSFontAttributeName: theme.font,
        ] as [String : Any]
        let buttonAttributes = [
            NSForegroundColorAttributeName: theme.accentColor,
            NSFontAttributeName: theme.font,
        ] as [String : Any]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControlState())
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControlState())
        self.tableView.separatorColor = theme.primaryBackgroundColor
        self.tableView.reloadData()
    }

    func showSettings() {
        self.navigationController?.pushViewController(self.settingsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsAndPrices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let product = Array(self.productsAndPrices.keys)[(indexPath as NSIndexPath).row]
        let price = self.productsAndPrices[product]!
        let theme = Settings.shared.theme
        cell.backgroundColor = theme.secondaryBackgroundColor
        cell.textLabel?.text = product
        cell.textLabel?.font = theme.font
        cell.textLabel?.textColor = theme.primaryForegroundColor
        cell.detailTextLabel?.text = "$\(price/100).00"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = Array(self.productsAndPrices.keys)[(indexPath as NSIndexPath).row]
        let price = self.productsAndPrices[product]!
        let checkoutViewController = CheckoutViewController(product: product,
                                                            price: price,
                                                            settings: Settings.shared)
        self.navigationController?.pushViewController(checkoutViewController, animated: true)
    }
}
