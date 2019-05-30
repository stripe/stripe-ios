//
//  BrowseProductsViewController.swift
//  Standard Integration (Sources Only)
//
//  Created by Jack Flintermann on 5/2/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit

struct Product {
    let emoji: String
    let price: Int
    
    var priceString: String {
        return "$\(price/100).00"
    }
}

class BrowseProductsViewController: UICollectionViewController {

    let productsAndPrices = [
        Product(emoji: "👕", price: 2000),
        Product(emoji: "👖", price: 4000),
        Product(emoji: "👗", price: 3000),
        Product(emoji: "👞", price: 700),
        Product(emoji: "👟", price: 600),
        Product(emoji: "👠", price: 1000),
        Product(emoji: "👡", price: 2000),
        Product(emoji: "👢", price: 2500),
        Product(emoji: "👒", price: 800),
        Product(emoji: "👙", price: 3000),
        Product(emoji: "💄", price: 2000),
        Product(emoji: "🎩", price: 5000),
        Product(emoji: "👛", price: 5500),
        Product(emoji: "👜", price: 6000),
        Product(emoji: "🕶", price: 2000),
        Product(emoji: "👚", price: 2500),
    ]
    
    var shoppingCart = [Product]() {
        didSet {
            buyButton.isEnabled = shoppingCart.count > 0
        }
    }

    let settingsVC = SettingsViewController()
    
    lazy var buyButton: BuyButton = {
        let buyButton = BuyButton(enabled: false, theme: self.settingsVC.settings.theme)
        buyButton.addTarget(self, action: #selector(didSelectBuy), for: .touchUpInside)
        return buyButton
    }()
    
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        self.init(collectionViewLayout: layout)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Emoji Apparel"
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Products", style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        
        collectionView?.register(EmojiCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView?.allowsMultipleSelection = true
        collectionView?.backgroundColor = UIColor(red: 2462/255, green: 249/255, blue: 252/255, alpha: 1)
        
        // Buy button
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buyButton)
        let bottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            bottomAnchor = view.bottomAnchor
        }
        
        NSLayoutConstraint.activate([
            buyButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            buyButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            buyButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            buyButton.heightAnchor.constraint(equalToConstant: BuyButton.defaultHeight),
        ])
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
    }

    @objc func showSettings() {
        let navController = UINavigationController(rootViewController: settingsVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func didSelectBuy() {
        let checkoutViewController = CheckoutViewController(products: shoppingCart,
                                                            settings: self.settingsVC.settings)
        self.navigationController?.pushViewController(checkoutViewController, animated: true)
    }
    
    func addToCart(_ product: Product) {
        shoppingCart.append(product)
    }
    
    /// Removes at most one product from self.shoppingCart
    func removeFromCart(_ product: Product) {
        if let indexToRemove = shoppingCart.firstIndex(where: { candidate in
            product.emoji == candidate.emoji
        }) {
            shoppingCart.remove(at: indexToRemove)
        }
    }
}

extension BrowseProductsViewController: UICollectionViewDelegateFlowLayout {

    //MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productsAndPrices.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? EmojiCell else {
            return UICollectionViewCell()
        }
        
        let product = self.productsAndPrices[indexPath.item]
        cell.configure(with: EmojiCellViewModel(price: product.priceString, emoji: product.emoji))
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = productsAndPrices[indexPath.item]
        addToCart(product)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let product = productsAndPrices[indexPath.item]
        removeFromCart(product)
    }

    //MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.size.width * 0.45
        return CGSize(width: width, height: 230)
    }
}
