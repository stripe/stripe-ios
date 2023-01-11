//
//  NSDirectionalEdgeInsets+StripeUICore.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public extension NSDirectionalEdgeInsets {
    static func insets(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> Self {
        return .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }

    static func insets(amount: CGFloat) -> Self {
        return .init(top: amount, leading: amount, bottom: amount, trailing: amount)
    }
}
