//
//  StubbedBackend.swift
//  StripePaymentSheetTests
//

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class StubbedBackend {
    static func stubSessions(paymentMethods: String) {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": paymentMethods,
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
    }

    static func updatePaymentMethodDetail(data: Data, variables: [String: String]) -> Data {
        var template = String(data: data, encoding: .utf8)!
        for (templateKey, templateValue) in variables {
            let translated = template.replacingOccurrences(of: templateKey, with: templateValue)
            template = translated
        }
        return template.data(using: .utf8)!
    }
    static func stubSessions(fileMock: FileMock, responseCallback: ((Data) -> Data)? = nil) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }
    static func stubPaymentMethods(
        fileMock: FileMock,
        pmType: String
    ) {
        stub { urlRequest in
            let isPaymentMethodCall = urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
            let isPaymentMethodType = urlRequest.url?.absoluteString.contains("type=\(pmType)") ?? false
            return (isPaymentMethodCall && isPaymentMethodType)
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }
    }
}

public class ClassForBundle {}
@_spi(STP) public enum FileMock: String, MockData {
    public typealias ResponseType = StripeFile
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case saved_payment_methods_200 = "MockFiles/saved_payment_methods_200"
    case saved_payment_methods_withCard_200 = "MockFiles/saved_payment_methods_withCard_200"
    case saved_payment_methods_withUSBank_200 = "MockFiles/saved_payment_methods_withUSBank_200"
    case saved_payment_methods_withSepa_200 = "MockFiles/saved_payment_methods_withSepa_200"

    case elementsSessionsPaymentMethod_200 = "MockFiles/elements_sessions_paymentMethod_200"
    case elementsSessions_customerSessionsCustomerSheet_200 = "MockFiles/elements_sessions_customerSessionCustomerSheet_200"
    case elementsSessions_customerSessionsCustomerSheetWithSavedPM_200 = "MockFiles/elements_sessions_customerSessionCustomerSheetWithSavedPM_200"

    case elementsSessionsPaymentMethod_savedPM_200 = "MockFiles/elements_sessions_paymentMethod_savedPM_200"
    case elementsSessionsPaymentMethod_link_200 = "MockFiles/elements_sessions_paymentMethod_link_200"
    case elementsSessions_link_signup_disabled_200 = "MockFiles/elements_sessions_link_signup_disabled_200"

    case customers_200 = "MockFiles/customers_200"
    case consumers_lookup_200 = "MockFiles/consumers_lookup_200"
    case payment_intents_200 = "MockFiles/payment_intents_200"
    case setup_intents_200 = "MockFiles/setup_intents_200"
}
