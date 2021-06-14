//
//  ApplePayHeaderView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/9/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import UIKit

extension PaymentSheetViewController {
    /// A view that looks like:
    ///
    /// [Apple Pay button]
    ///  --- or pay with ---
    ///
    class ApplePayHeaderView: UIView {
        private let didTap: () -> Void
        lazy var orPayWithLabel: UILabel = {
            let label = UILabel()
            label.textColor = CompatibleColor.secondaryLabel
            label.font = .preferredFont(forTextStyle: .subheadline)
            return label
        }()
        private lazy var applePayButton: PKPaymentButton = {
            let button = PKPaymentButton(
                paymentButtonType: .plain, paymentButtonStyle: .compatibleAutomatic)
            button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            return button
        }()

        init(didTap: @escaping () -> Void) {
            self.didTap = didTap
            super.init(frame: .zero)
            func makeLineView() -> UIView {
                let view = UIView()
                view.backgroundColor = CompatibleColor.opaqueSeparator
                return view
            }

            let leftLine = makeLineView()
            let rightLine = makeLineView()
            let views = [
                "applePayButton": applePayButton,
                "orPayWithLabel": orPayWithLabel,
                "leftLine": leftLine,
                "rightLine": rightLine,
            ]
            views.values.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
            NSLayoutConstraint.activate(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|[applePayButton]|", options: [], metrics: nil,
                    views: views)
                    + NSLayoutConstraint.constraints(
                        withVisualFormat:
                            "H:|[leftLine(>=0)]-(10)-[orPayWithLabel]-(10)-[rightLine(>=0)]|",
                        options: [.alignAllCenterY], metrics: nil, views: views)
                    + NSLayoutConstraint.constraints(
                        withVisualFormat: "V:|[applePayButton(44)]-(24)-[orPayWithLabel]|",
                        options: [], metrics: nil, views: views) + [
                        orPayWithLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                        leftLine.heightAnchor.constraint(equalToConstant: 1),
                        rightLine.heightAnchor.constraint(equalToConstant: 1),
                    ]
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func handleTap() {
            self.didTap()
        }
    }
}
