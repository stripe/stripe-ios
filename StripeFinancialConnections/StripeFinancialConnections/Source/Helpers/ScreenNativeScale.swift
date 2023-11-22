//
//  ScreenNativeScale.swift
//  StripeFinancialConnections
//
//  Created by David Estes on 11/20/23.
//

import UIKit

var stp_screenNativeScale: CGFloat {
    #if STP_BUILD_FOR_VISION
    return 1.0
    #else
    return UIScreen.main.nativeScale
    #endif
}
