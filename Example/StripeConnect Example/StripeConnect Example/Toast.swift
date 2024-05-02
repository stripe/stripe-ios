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
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.font = .preferredFont(forTextStyle: .body)
        toastLabel.text = message

        let toastView = UIView()
        toastView.translatesAutoresizingMaskIntoConstraints = false
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastView.alpha = 0.0
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true

        toastView.addSubview(toastLabel)
        window.addSubview(toastView)

        // Constraints
        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
            toastLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8),
            toastLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: toastView.widthAnchor, constant: -16),

            toastView.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            toastView.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            toastLabel.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])

        UIView.animateKeyframes(withDuration: 4.0, delay: 0.0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.125) {
                toastView.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                toastView.alpha = 0.0
            }
        } completion: { _ in
            toastView.removeFromSuperview()
        }
    }
}
