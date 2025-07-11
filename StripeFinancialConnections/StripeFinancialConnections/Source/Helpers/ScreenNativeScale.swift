//
//  ScreenNativeScale.swift
//  StripeFinancialConnections
//
//  Created by David Estes on 11/20/23.
//

import UIKit

var stp_screenNativeScale: CGFloat {
    #if os(visionOS)
    return 1.0
    #else
    return UIScreen.main.nativeScale
    #endif
}
