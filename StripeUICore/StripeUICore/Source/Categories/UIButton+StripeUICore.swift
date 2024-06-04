//
//  UIButton+StripeUICore.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 2/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public extension UIButton {
    static let minimumTapSize: CGSize = CGSize(width: 44, height: 44)

    class var doneButtonTitle: String {
        return STPLocalizedString("Done", "Done button title")
    }

    class var editButtonTitle: String {
        return .Localized.edit
    }

    /// A helper method that returns a UIButton that:
    /// 1. Retains the provided `didTap` closure and calls it when the button is tapped.
    /// 2. Expands the tap target area to be 44x44
    class func make(type buttonType: UIButton.ButtonType, didTap: @escaping () -> Void) -> UIButton {
        class ClosureButton: UIButton {
            var didTap: () -> Void = {}
            public override init(frame: CGRect) {
                super.init(frame: frame)
                addTarget(self, action: #selector(didTapSelector), for: .touchUpInside)
            }
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
                let newArea = bounds.insetBy(
                    dx: -(Self.minimumTapSize.width - bounds.width) / 2,
                    dy: -(Self.minimumTapSize.height - bounds.height) / 2)
                return newArea.contains(point)
            }
            @objc func didTapSelector() {
               didTap()
            }
        }

        let button = ClosureButton(type: buttonType)
        button.didTap = didTap
        return button
    }
}
