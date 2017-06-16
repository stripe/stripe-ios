//
//  LoginViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Tara Teich on 6/15/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class LoginViewController: UIViewController {
    
    let descriptionLabel = UILabel()
    let emailField = UITextField()
    let passwordField = UITextField()
    let loginButton = BuyButton(enabled: false, theme: STPTheme.default())
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    let rowHeight: CGFloat = 44
    let padding: CGFloat = 15
    
    let productsVC = BrowseProductsViewController()
    
    init() {
        MyAPIClient.sharedClient.baseURLString =  MyConfig.sharedConfig.backendBaseURL
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let theme = STPTheme.default()
        
        self.view.backgroundColor = theme.primaryBackgroundColor

        self.navigationItem.title = MyConfig.sharedConfig.companyName
        
        self.descriptionLabel.text = "Please Login to Continue"
        self.descriptionLabel.backgroundColor = UIColor.clear
        self.descriptionLabel.textAlignment = .center;
        self.view.addSubview(self.descriptionLabel)

        
        self.emailField.placeholder = "email"
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.view.addSubview(self.emailField)
        
        self.passwordField.placeholder = "password"
        self.passwordField.isSecureTextEntry = true
        self.view.addSubview(self.passwordField)
        
        self.loginButton.setTitle("Login", for: UIControlState())
        self.view.addSubview(self.loginButton)
        self.loginButton.isEnabled = false
        self.loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.alpha = 0
        
        // listen for textfield edits so we can enable the Login button when there's something in both fields
        emailField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.bounds.width - 2*padding
        
        self.descriptionLabel.frame = CGRect(x: padding, y: 2.0 * rowHeight,
                                       width: width, height: rowHeight)
        self.emailField.frame = CGRect(x: padding, y: self.descriptionLabel.frame.maxY,
                                        width: width, height: rowHeight)
        self.passwordField.frame = CGRect(x: padding, y: self.emailField.frame.maxY,
                                     width: width, height: rowHeight)
        self.loginButton.frame = CGRect(x: padding, y: self.passwordField.frame.maxY + rowHeight,
                                        width: width, height: rowHeight)
        self.activityIndicator.center = self.loginButton.center
    }
    
    func login() {
        self.activityIndicator.startAnimating()
        self.loginButton.alpha = 0.0
        self.activityIndicator.alpha = 1.0
        
        MyAPIClient.sharedClient.login(emailField.text!, password: passwordField.text!, completion: {(error: Error?) in
            self.activityIndicator.alpha = 0.0
            self.loginButton.alpha = 1.0
            self.activityIndicator.stopAnimating()
            
            if let err = error {
                let alertController = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            } else {
                let navController = UINavigationController(rootViewController: self.productsVC)
                self.present(navController, animated: true, completion: nil)
            }
        })
    }
    
    func editingChanged(_ textField: UITextField) {
        self.loginButton.isEnabled = (!self.emailField.text!.isEmpty && !self.passwordField.text!.isEmpty)
    }
}
