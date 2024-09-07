//
//  UIStackView+Separator.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import UIKit

extension UIStackView {
    func addSeparators(color: UIColor, backgroundColor: UIColor, thickness: CGFloat = 1, inset: UIEdgeInsets, addTopSeparator: Bool = true, addBottomSeparator: Bool = true) {
        let numberOfSeparators = arrangedSubviews.count - 1

        for i in 1...numberOfSeparators {
            addSeparator(color: color, backgroundColor: backgroundColor, thickness: thickness, inset: inset, at: i * 2 - 1)
        }

        if addTopSeparator {
            addSeparator(color: color, backgroundColor: backgroundColor, thickness: thickness, inset: inset, at: 0)
        }

        if addBottomSeparator {
            addSeparator(color: color, backgroundColor: backgroundColor, thickness: thickness, inset: inset, at: arrangedSubviews.count)
        }
    }

    private func addSeparator(color: UIColor, backgroundColor: UIColor, thickness: CGFloat, inset: UIEdgeInsets, at index: Int) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = backgroundColor

        let separator = UIView()
        separator.backgroundColor = color
        separator.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(separator)

        insertArrangedSubview(containerView, at: index)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: thickness),

            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: inset.left),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -inset.right),
            separator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            separator.heightAnchor.constraint(equalTo: containerView.heightAnchor),
        ])
    }
}
