//
//  BrowseProductsViewController.swift
//  Basic Integration
//
//  Created by Jack Flintermann on 5/2/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit

struct Product {
    let emoji: String
    let price: Int
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
        Product(emoji: "👚", price: 2500)
    ]

    var shoppingCart = [Product]() {
        didSet {
            let price = shoppingCart.reduce(0) { result, product in result + product.price }
            buyButton.priceLabel.text = numberFormatter.string(from: NSNumber(value: Float(price)/100))!
            let enabled = price > 0
            if enabled == buyButton.isEnabled {
                return
            }
            buyButton.isEnabled = enabled
            // Order of operations is important to avoid conflicting constraints
            (enabled ? buyButtonBottomDisabledConstraint : buyButtonBottomEnabledConstraint).isActive = false
            (enabled ? buyButtonBottomEnabledConstraint : buyButtonBottomDisabledConstraint).isActive = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()

    let settingsVC = SettingsViewController()

    lazy var buyButton: BrowseBuyButton = {
        let buyButton = BrowseBuyButton(enabled: false)
        buyButton.addTarget(self, action: #selector(didSelectBuy), for: .touchUpInside)
        return buyButton
    }()

    var buyButtonBottomDisabledConstraint: NSLayoutConstraint!
    var buyButtonBottomEnabledConstraint: NSLayoutConstraint!

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
        collectionView?.backgroundColor = UIColor(red: 246/255, green: 249/255, blue: 252/255, alpha: 1)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            self.navigationController?.view.backgroundColor = .systemBackground
            collectionView?.backgroundColor = .systemGray6
        }
        #endif
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Products", style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))

        self.numberFormatter.locale = self.settingsVC.settings.currencyLocale

        collectionView?.register(EmojiCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView?.allowsMultipleSelection = true

        // Buy button
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buyButton)
        let bottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            bottomAnchor = view.bottomAnchor
        }
        buyButtonBottomEnabledConstraint = buyButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        buyButtonBottomDisabledConstraint = buyButton.topAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            buyButtonBottomDisabledConstraint,
            buyButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            buyButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            buyButton.heightAnchor.constraint(equalToConstant: BuyButton.defaultHeight)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let theme = self.settingsVC.settings.theme
        self.view.backgroundColor = theme.primaryBackgroundColor
        self.navigationController?.navigationBar.barTintColor = theme.secondaryBackgroundColor
        self.navigationController?.navigationBar.tintColor = theme.accentColor
        let titleAttributes = [
            NSAttributedString.Key.foregroundColor: theme.primaryForegroundColor,
            NSAttributedString.Key.font: theme.font
        ] as [NSAttributedString.Key: Any]
        let buttonAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: theme.font
        ] as [NSAttributedString.Key: Any]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControl.State())
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControl.State())

        self.numberFormatter.locale = self.settingsVC.settings.currencyLocale
        self.view.setNeedsLayout()
        let selectedItems = self.collectionView.indexPathsForSelectedItems ?? []
        self.collectionView.reloadData()
        for item in selectedItems {
            self.collectionView.selectItem(at: item, animated: false, scrollPosition: [])
        }
    }

    @objc func showSettings() {
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .fullScreen
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

    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productsAndPrices.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? EmojiCell else {
            return UICollectionViewCell()
        }

        let product = self.productsAndPrices[indexPath.item]

        cell.configure(with: product, numberFormatter: self.numberFormatter)
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

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.size.width * 0.45
        return CGSize(width: width, height: 230)
    }
}
