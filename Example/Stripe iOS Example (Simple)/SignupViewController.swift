//
//  SignupViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Tara Teich on 6/16/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class SignupViewController: UIViewController {

    let descriptionLabel = UILabel()

    let firstNameField = UITextField()
    let lastNameField = UITextField()
    let emailField = UITextField()
    let passwordField = UITextField()
    let signupButton = BuyButton(enabled: false, theme: STPTheme.default())
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    let rowHeight: CGFloat = 44
    let padding: CGFloat = 15
    
    init() {
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
        
        descriptionLabel.text = "Create Account"
        descriptionLabel.backgroundColor = UIColor.clear
        descriptionLabel.textAlignment = .center;
        self.view.addSubview(descriptionLabel)
        
        firstNameField.placeholder = "First name"
        firstNameField.autocorrectionType = .no
        self.view.addSubview(firstNameField)
        
        lastNameField.placeholder = "Last name"
        lastNameField.autocorrectionType = .no
        self.view.addSubview(lastNameField)
        
        self.emailField.placeholder = "email"
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.view.addSubview(self.emailField)
        
        self.passwordField.placeholder = "password"
        self.passwordField.isSecureTextEntry = true
        self.view.addSubview(self.passwordField)
        
        self.signupButton.setTitle("Create Account", for: UIControlState())
        self.view.addSubview(self.signupButton)
        self.signupButton.isEnabled = false
        self.signupButton.addTarget(self, action: #selector(createAccount), for: .touchUpInside)
        
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.alpha = 0
        
        // listen for textfield edits so we can enable the Login button when there's something in both fields
        emailField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.bounds.width - 2*padding
        
        descriptionLabel.frame = CGRect(x: padding, y: 2.0 * rowHeight,
                                             width: width, height: rowHeight)
        firstNameField.frame = CGRect(x: padding, y: descriptionLabel.frame.maxY,
                                      width: width, height: rowHeight)
        lastNameField.frame = CGRect(x: padding, y: firstNameField.frame.maxY,
                                      width: width, height: rowHeight)
        emailField.frame = CGRect(x: padding, y: lastNameField.frame.maxY,
                                       width: width, height: rowHeight)
        passwordField.frame = CGRect(x: padding, y: emailField.frame.maxY,
                                          width: width, height: rowHeight)
        signupButton.frame = CGRect(x: padding, y: passwordField.frame.maxY + rowHeight,
                                        width: width, height: rowHeight)
        self.activityIndicator.center = signupButton.center
    }
    
    func createAccount() {
        self.activityIndicator.startAnimating()
        self.signupButton.alpha = 0.0
        self.activityIndicator.alpha = 1.0
        
        MyAPIClient.sharedClient.createUser(email: emailField.text!, password: passwordField.text!, firstName: firstNameField.text, lastName: lastNameField.text, completion:  {(error: Error?) in
            self.activityIndicator.alpha = 0.0
            self.signupButton.alpha = 1.0
            self.activityIndicator.stopAnimating()
            
            if let err = error {
                let alertController = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    func editingChanged(_ textField: UITextField) {
        self.signupButton.isEnabled = (!self.emailField.text!.isEmpty && !self.passwordField.text!.isEmpty)
    }
}
