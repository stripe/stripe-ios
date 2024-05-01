//
//  Toast.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/1/24.
//

import UIKit

extension UIApplication {
    /// Helper to display an error message on top of the current window
    func showToast(message: String) {

        guard let window = windows.filter({ $0.isKeyWindow }).first else { return }

        let toastLabel = UILabel()
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = .preferredFont(forTextStyle: .body)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        window.addSubview(toastLabel)

        // Constraints
        toastLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        toastLabel.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -20).isActive = true
        toastLabel.widthAnchor.constraint(lessThanOrEqualToConstant: window.frame.size.width - 40).isActive = true

        UIView.animate(withDuration: 4.0, delay: 0.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }) { _ in
            toastLabel.removeFromSuperview()
        }
    }
}
