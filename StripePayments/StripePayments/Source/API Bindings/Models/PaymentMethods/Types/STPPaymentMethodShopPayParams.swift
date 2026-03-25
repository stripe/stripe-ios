//
//  STPPaymentMethodShopPayParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a ShopPay Payment Method
@_spi(STP) public class STPPaymentMethodShopPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Corresponding externalSourceId. Required.
    @objc public var externalSourceId: String?

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "shop_pay"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
       return [
            NSStringFromSelector(#selector(getter: externalSourceId)): "external_source_id"
            ]
    }
}
