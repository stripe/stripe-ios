//
//  STPPaymentHandler+WeChatPay.swift
//  StripeiOS
//
//  Created by David Estes on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// This defines protocols from the WeChat SDK, so we can call them
// from AnyClass and AnyType objects.
@objc protocol STPWXAPI: NSObjectProtocol {
    @objc static func sendReq(_ req: AnyObject, completion: ((Bool) -> Void)?)
}

@objc protocol STPWXPayReq: NSObjectProtocol {
    @objc func setPartnerId(_ string: String)
    @objc func setPrepayId(_ string: String)
    @objc func setNonceStr(_ string: String)
    @objc func setTimeStamp(_ stamp: UInt32)
    @objc func setPackage(_ string: String)
    @objc func setSign(_ string: String)
}

/// Use this to determine if WeChat Pay should be presented to the user.
/// (For example, to determine if it should be shown in PaymentSheet.)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPPaymentHandler {
    static func isWeChatPayAvailable() -> Bool {
        return NSClassFromString("WXApi") != nil
    }
}
