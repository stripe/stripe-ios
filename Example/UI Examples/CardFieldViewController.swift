//
//  CardFieldViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/19/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import SafariServices
import Stripe
import PanModal

class CardFieldViewController: UIViewController {

    let cardField = STPPaymentCardTextField()
    let pushButton = UIButton(type: .roundedRect)
    let expandButton = UIButton(type: .roundedRect)
    let webviewButton = UIButton(type: .roundedRect)
    var theme = STPTheme.default()
    var heightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Field"
        view.backgroundColor = UIColor.white
        view.addSubview(cardField)
        edgesForExtendedLayout = []
        view.backgroundColor = theme.primaryBackgroundColor
        cardField.backgroundColor = theme.secondaryBackgroundColor
        cardField.textColor = theme.primaryForegroundColor
        cardField.placeholderColor = theme.secondaryForegroundColor
        cardField.borderColor = theme.accentColor
        cardField.borderWidth = 1.0
        cardField.textErrorColor = theme.errorColor
        cardField.postalCodeEntryEnabled = true
        
        pushButton.setTitle("Push", for: .normal)
        pushButton.addTarget(self, action: #selector(push), for: .touchUpInside)
        view.addSubview(pushButton)
        
        expandButton.setTitle("Expand", for: .normal)
        expandButton.addTarget(self, action: #selector(expand), for: .touchUpInside)
        view.addSubview(expandButton)
        
        webviewButton.setTitle("Webview", for: .normal)
        webviewButton.addTarget(self, action: #selector(webview), for: .touchUpInside)
        view.addSubview(webviewButton)
            
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationController?.navigationBar.stp_theme = theme
        
        for v in [cardField, pushButton, expandButton, webviewButton] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 356)

        NSLayoutConstraint.activate([
            cardField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15),
            cardField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15),
            cardField.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            cardField.heightAnchor.constraint(equalToConstant: 50),
            
            pushButton.topAnchor.constraint(equalTo: cardField.bottomAnchor, constant: 15),
            pushButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            pushButton.heightAnchor.constraint(equalToConstant: 20),
//            pushButton.widthAnchor.constraint(equalToConstant: 50)
            
            expandButton.topAnchor.constraint(equalTo: pushButton.bottomAnchor, constant: 15),
            expandButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            webviewButton.topAnchor.constraint(equalTo: expandButton.bottomAnchor, constant: 1),
            webviewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            webviewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            heightConstraint
        ])
    }
    
    @objc func webview() {
        let vc = SFSafariViewController(url: URL(string: "https://stripe.com")!)
        present(vc, animated: true, completion: nil)
    }
    
    @objc func expand() {
        print(view.intrinsicContentSize)
        print(view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize))
        heightConstraint.constant += 100
    }

    @objc func push() {
        let vc = CardFieldViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func done() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cardField.becomeFirstResponder()
    }

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        let padding: CGFloat = 15
//        cardField.frame = CGRect(x: padding,
//                                 y: padding,
//                                 width: view.bounds.width - (padding * 2),
//                                 height: 50)
//    }
}

extension CardFieldViewController: PanModalPresentable {

    var panScrollable: UIScrollView? {
        return nil
    }
}

extension UINavigationController: PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }
    
    public var shortFormHeight: PanModalHeight {
        guard let vc = visibleViewController else {
            return longFormHeight
        }
        let intrinsicContentSize = vc.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
//        let huh = vc.view.intrinsicContentSize // This is -1, -1
        return PanModalHeight.contentHeight(intrinsicContentSize.height)
    }
}
