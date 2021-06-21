//
//  NSDirectionalEdgeInsets+Stripe.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension NSDirectionalEdgeInsets {
    static func insets(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> NSDirectionalEdgeInsets {
        return .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

