//
//  SheetNavigationButton.swift
//  StripeiOS
//
//  Created by Nick Porter on 4/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// A simple button that increases the tap target for small buttons used in the navigation bar of PaymentSheet
/// /// For internal SDK use only
@objc(STP_Internal_SheetNavigationButton)
class SheetNavigationButton: UIButton {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = self.bounds.size
        let widthToAdd = max(PaymentSheetUI.minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(PaymentSheetUI.minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return largerFrame.contains(point)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
