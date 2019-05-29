//
//  BrowseProductsViewController.swift
//  Standard Integration (Sources Only)
//
//  Created by Jack Flintermann on 5/2/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit

class BrowseProductsViewController: UICollectionViewController {

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
    
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        // TODO: This should depend on available width
        layout.itemSize = CGSize(width: 150, height: 200)
        self.init(collectionViewLayout: layout)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Emoji Apparel"
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Products", style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        
        collectionView!.register(EmojiCell.self, forCellWithReuseIdentifier: "Cell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let theme = self.settingsVC.settings.theme
        self.view.backgroundColor = theme.primaryBackgroundColor
        self.navigationController?.navigationBar.barTintColor = theme.secondaryBackgroundColor
        self.navigationController?.navigationBar.tintColor = theme.accentColor
        let titleAttributes = [
            NSAttributedStringKey.foregroundColor: theme.primaryForegroundColor,
            NSAttributedStringKey.font: theme.font,
        ] as [NSAttributedStringKey : Any]
        let buttonAttributes = [
            NSAttributedStringKey.foregroundColor: theme.accentColor,
            NSAttributedStringKey.font: theme.font,
        ] as [NSAttributedStringKey : Any]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControlState())
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControlState())
//        self.collectionView.separatorColor = theme.primaryBackgroundColor
//        self.tableView.reloadData()
    }

    @objc func showSettings() {
        let navController = UINavigationController(rootViewController: settingsVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productsAndPrices.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? EmojiCell else {
            return UICollectionViewCell()
        }
        
        let product = Array(self.productsAndPrices.keys)[(indexPath as NSIndexPath).row]
        let price = self.productsAndPrices[product]!
//        let theme = self.settingsVC.settings.theme
        cell.configure(with: EmojiCellViewModel(price: "$\(price/100).00", emoji: product))
//        cell.backgroundColor = theme.secondaryBackgroundColor
//        cell.textLabel?.text = product
//        cell.textLabel?.font = theme.font
//        cell.textLabel?.textColor = theme.primaryForegroundColor
//        cell.detailTextLabel?.text = "$\(price/100).00"
//        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let product = Array(self.productsAndPrices.keys)[(indexPath as NSIndexPath).row]
        let price = self.productsAndPrices[product]!
    }
    
    func didSelectBuy() {
        let checkoutViewController = CheckoutViewController(product: product,
                                                            price: price,
                                                            settings: self.settingsVC.settings)
        self.navigationController?.pushViewController(checkoutViewController, animated: true)
    }
}
