//
//  UIAlertController+Extensions.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {

    static func showAlert(
        title: String? = nil,
        message: String? = nil
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )
        UIViewController
            .topMostViewController()!
            .present(alertController, animated: true)
    }
}
