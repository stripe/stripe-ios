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
        
        self.view.backgroundColor = UIColor.white

        self.navigationItem.title = "Login"
        
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
        
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.alpha = 0
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(login))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
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
        self.activityIndicator.center = CGPoint(x: padding, y: self.passwordField.frame.maxY + rowHeight*1.5)
    }
    
    func login() {
        self.activityIndicator.alpha = 1.0
        
        MyAPIClient.sharedClient.login(emailField.text!, password: passwordField.text!, completion: {(error: Error?) in
            self.activityIndicator.alpha = 0.0
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
        self.navigationItem.rightBarButtonItem?.isEnabled = (!self.emailField.text!.isEmpty && !self.passwordField.text!.isEmpty)
    }
}
