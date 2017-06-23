//
//  LoginViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Tara Teich on 6/15/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    let emailField = UITextField()
    let passwordField = UITextField()
    let loginButton = BuyButton(enabled: false, theme: Settings.shared.theme)
    let signupButton = UIButton(type: .system)
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
        self.navigationItem.title = "Login"

        self.emailField.placeholder = "Email"
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.addTarget(self, action: #selector(updateLoginButton), for: .editingChanged)
        self.emailField.delegate = self
        self.view.addSubview(self.emailField)

        self.passwordField.placeholder = "Password"
        self.passwordField.isSecureTextEntry = true
        self.passwordField.addTarget(self, action: #selector(updateLoginButton), for: .editingChanged)
        self.passwordField.delegate = self
        self.view.addSubview(self.passwordField)

        self.loginButton.setTitle("Log in", for: UIControlState())
        self.loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        self.view.addSubview(loginButton)

        self.signupButton.setTitle("Create an account", for: UIControlState())
        self.signupButton.addTarget(self, action: #selector(pushSignupViewController), for: .touchUpInside)
        self.view.addSubview(self.signupButton)
       
        self.activityIndicator.alpha = 0
        self.view.addSubview(self.activityIndicator)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateLoginButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emailField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rowHeight: CGFloat = 44
        let padding: CGFloat = 15
        let width = self.view.bounds.width - 2*padding

        self.emailField.frame = CGRect(x: padding, y: 2.0 * rowHeight,
                                       width: width, height: rowHeight)
        self.passwordField.frame = CGRect(x: padding, y: self.emailField.frame.maxY,
                                          width: width, height: rowHeight)
        self.loginButton.frame = CGRect(x: padding, y: self.passwordField.frame.maxY + rowHeight,
                                        width: width, height: rowHeight)
        self.signupButton.frame = CGRect(x: padding, y: self.loginButton.frame.maxY,
                                         width: width, height: rowHeight)
        self.activityIndicator.center = self.loginButton.center
    }
    
    func login() {
        guard let email = self.emailField.text, let password = self.passwordField.text else {
            return
        }

        self.activityIndicator.startAnimating()
        self.loginButton.alpha = 0.0
        self.signupButton.alpha = 0.0
        self.activityIndicator.alpha = 1.0
        
        MyAPIClient.shared.login(email: email, password: password) { error in
            DispatchQueue.main.async {
                self.activityIndicator.alpha = 0.0
                self.loginButton.alpha = 1.0
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
                    let rootVC = BrowseProductsViewController()
                    let navController = UINavigationController(rootViewController: rootVC)
                    self.present(navController, animated: true, completion: nil)
                }
            }
        }
    }

    func pushSignupViewController() {
        let signupVC = SignupViewController()
        self.navigationController?.pushViewController(signupVC, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField && self.loginButton.isEnabled {
            self.login()
        }
        return true
    }

    func updateLoginButton() {
        if let email = self.emailField.text,
            let password = self.passwordField.text,
            !email.isEmpty && !password.isEmpty
        {
            self.loginButton.isEnabled = true;
        } else {
            self.loginButton.isEnabled = false;
        }
    }
}
