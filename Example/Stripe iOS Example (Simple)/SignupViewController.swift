//
//  SignupViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Tara Teich on 6/16/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class SignupViewController: UIViewController, UITextFieldDelegate {

    let emailField = UITextField()
    let passwordField = UITextField()
    let signupButton = BuyButton(enabled: false, theme: STPTheme.default())
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Settings.shared.theme.primaryBackgroundColor
        self.navigationItem.title = "Create Account"

        self.emailField.placeholder = "Email"
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.addTarget(self, action: #selector(updateSignupButton), for: .editingChanged)
        self.emailField.delegate = self
        self.view.addSubview(self.emailField)
        
        self.passwordField.placeholder = "Password"
        self.passwordField.isSecureTextEntry = true
        self.passwordField.addTarget(self, action: #selector(updateSignupButton), for: .editingChanged)
        self.passwordField.delegate = self
        self.view.addSubview(self.passwordField)
        
        self.signupButton.setTitle("Create Account", for: UIControlState())
        self.signupButton.addTarget(self, action: #selector(createAccount), for: .touchUpInside)
        self.view.addSubview(self.signupButton)

        self.activityIndicator.alpha = 0
        self.view.addSubview(self.activityIndicator)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emailField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let padding: CGFloat = 15
        let width = self.view.bounds.width - 2*padding
        let rowHeight: CGFloat = 44
        
        self.emailField.frame = CGRect(x: padding, y: 2.0 * rowHeight,
                                       width: width, height: rowHeight)
        self.passwordField.frame = CGRect(x: padding, y: self.emailField.frame.maxY,
                                          width: width, height: rowHeight)
        self.signupButton.frame = CGRect(x: padding, y: self.passwordField.frame.maxY + rowHeight,
                                         width: width, height: rowHeight)
        self.activityIndicator.center = self.signupButton.center
    }

    func createAccount() {
        guard let email = self.emailField.text, let password = self.passwordField.text else {
            return
        }

        self.activityIndicator.startAnimating()
        self.signupButton.alpha = 0.0
        self.activityIndicator.alpha = 1.0
        
        MyAPIClient.shared.createUser(email: email, password: password) { error in
            DispatchQueue.main.async {
                self.activityIndicator.alpha = 0.0
                self.signupButton.alpha = 1.0
                self.activityIndicator.stopAnimating()

                if let e = error {
                    let alertController = UIAlertController(title: "Error",
                                                            message: e.localizedDescription,
                                                            preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.emailField.text = nil
                    self.passwordField.text = nil
                    if let loginVC = self.navigationController?.viewControllers.first as? LoginViewController {
                        loginVC.emailField.text = email
                        loginVC.passwordField.text = password
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField && self.signupButton.isEnabled {
            self.createAccount()
        }
        return true
    }

    func updateSignupButton() {
        if let email = self.emailField.text,
            let password = self.passwordField.text,
            !email.isEmpty && !password.isEmpty
        {
            self.signupButton.isEnabled = true;
        } else {
            self.signupButton.isEnabled = false;
        }
    }
}
