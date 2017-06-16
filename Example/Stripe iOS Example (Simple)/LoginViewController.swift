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
    let signupButton = UIButton(type: .system)
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    let rowHeight: CGFloat = 44
    let padding: CGFloat = 15
    
    let productsVC = BrowseProductsViewController()
    var signupVC = SignupViewController()
    
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

        descriptionLabel.text = "Please Login to Continue"
        descriptionLabel.backgroundColor = UIColor.clear
        descriptionLabel.textAlignment = .center;
        self.view.addSubview(descriptionLabel)


        emailField.placeholder = "email"
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        self.view.addSubview(emailField)

        passwordField.placeholder = "password"
        passwordField.isSecureTextEntry = true
        self.view.addSubview(passwordField)

        loginButton.setTitle("Login", for: UIControlState())
        self.view.addSubview(loginButton)
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)

        signupButton.setTitle("Create an account", for: UIControlState())
        view.addSubview(signupButton)
        signupButton.addTarget(self, action: #selector(signup), for: .touchUpInside)
       
        self.view.addSubview(activityIndicator)
        activityIndicator.alpha = 0
        
        // listen for textfield edits so we can enable the Login button when there's something in both fields
        emailField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.bounds.width - 2*padding
        
        descriptionLabel.frame = CGRect(x: padding, y: 2.0 * rowHeight,
                                       width: width, height: rowHeight)
        emailField.frame = CGRect(x: padding, y: descriptionLabel.frame.maxY,
                                        width: width, height: rowHeight)
        passwordField.frame = CGRect(x: padding, y: emailField.frame.maxY,
                                     width: width, height: rowHeight)
        loginButton.frame = CGRect(x: padding, y: passwordField.frame.maxY + rowHeight,
                                        width: width, height: rowHeight)
        signupButton.frame = CGRect(x: padding, y: loginButton.frame.maxY,
                                    width: width, height: rowHeight)
        activityIndicator.center = loginButton.center
    }
    
    func login() {
        activityIndicator.startAnimating()
        loginButton.alpha = 0.0
        signupButton.alpha = 0.0
        activityIndicator.alpha = 1.0
        
        MyAPIClient.sharedClient.login(emailField.text!, password: passwordField.text!, completion: {(error: Error?) in
            self.activityIndicator.alpha = 0.0
            self.loginButton.alpha = 1.0
            self.signupButton.alpha = 1.0
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
    
    func signup() {
        self.navigationController?.pushViewController(self.signupVC, animated: true)
    }
    
    func editingChanged(_ textField: UITextField) {
        self.loginButton.isEnabled = (!self.emailField.text!.isEmpty && !self.passwordField.text!.isEmpty)
    }
}
