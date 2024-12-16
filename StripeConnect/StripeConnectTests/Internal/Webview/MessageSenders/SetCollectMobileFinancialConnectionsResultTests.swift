//
//  SetCollectMobileFinancialConnectionsResultTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

import CustomDump
@testable import StripeConnect
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

enum FinancialConnectionsSessionMock: String, MockData {
    typealias ResponseType = StripeAPI.FinancialConnectionsSession
    var bundle: Bundle { return Bundle(for: SetCollectMobileFinancialConnectionsResultTests.self) }

    case `default` = "FinancialConnectionsSession"
}

class SetCollectMobileFinancialConnectionsResultTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: SetCollectMobileFinancialConnectionsResult.sender(
            value: .init(
                financialConnectionsSession: .init(accounts: []),
                token: nil,
                error: nil
            )
        ))
    }

    let mockAnalyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
    let bundle = Bundle(for: SetCollectMobileFinancialConnectionsResultTests.self)

    func testEncodingValue() throws {
        let session = try FinancialConnectionsSessionMock.default.make()
        let sheetResult = FinancialConnectionsSheet.TokenResult.completed(session: session)
        let payloadValue = sheetResult.toSenderValue(analyticsClient: mockAnalyticsClient)

        XCTAssertNotNil(payloadValue.financialConnectionsSession)
        XCTAssertNotNil(payloadValue.token)
        XCTAssertNil(payloadValue.error)

        // No errors should be logged
        XCTAssertEqual(mockAnalyticsClient.loggedClientErrors.count, 0)

        // Encode to JSON dictionary using Connect encoder
        let encodedJsonDict = try dictionary(
            fromJsonData: try SetCollectMobileFinancialConnectionsResult
                .sender(value: payloadValue)
                .jsonData()
        )

        // Load expected
        let expectedSessionJsonDict = try dictionary(
            fromJsonData: try Data(
                contentsOf: bundle.url(
                    forResource: "FinancialConnectionsSession_encodedJS",
                    withExtension: "json"
                )!
            )
        )

        // Cast Swift types to Objc types so CustomDump comparison passes
        expectNoDifference(encodedJsonDict, [
            "setter": "setCollectMobileFinancialConnectionsResult",
            "value": expectedSessionJsonDict,
        ])
    }

    func testPayloadValue_canceled() throws {
        let sheetResult = FinancialConnectionsSheet.TokenResult.canceled
        let payloadValue = sheetResult.toSenderValue(analyticsClient: mockAnalyticsClient)
        XCTAssertEqual(payloadValue.financialConnectionsSession?.accounts, [])
        XCTAssertNil(payloadValue.token)
        XCTAssertNil(payloadValue.error)
        XCTAssertEqual(mockAnalyticsClient.loggedClientErrors.count, 0)
    }

    func testPayloadValue_clientError() throws {
        let sheetResult = FinancialConnectionsSheet.TokenResult.failed(error: NSError(domain: "MockError", code: 5))
        let payloadValue = sheetResult.toSenderValue(analyticsClient: mockAnalyticsClient)
        XCTAssertNil(payloadValue.financialConnectionsSession)
        XCTAssertNil(payloadValue.token)
        XCTAssertNil(payloadValue.error)
        XCTAssertEqual(mockAnalyticsClient.loggedClientErrors.count, 1)

        let error = try XCTUnwrap(mockAnalyticsClient.loggedClientErrors.first)
        XCTAssertEqual(error.domain, "MockError")
        XCTAssertEqual(error.code, 5)
    }

    func testPayloadValue_apiError() throws {
        let apiError = try StripeJSONDecoder().decode(
            StripeAPIError.self,
            from: try Data(
                contentsOf: bundle.url(
                    forResource: "StripeAPIError",
                    withExtension: "json"
                )!
            )
        )
        let sheetResult = FinancialConnectionsSheet.TokenResult.failed(error: StripeError.apiError(apiError))
        let payloadValue = sheetResult.toSenderValue(analyticsClient: mockAnalyticsClient)
        XCTAssertNil(payloadValue.financialConnectionsSession)
        XCTAssertNil(payloadValue.token)
        XCTAssertEqual(payloadValue.error, apiError)
        XCTAssertEqual(mockAnalyticsClient.loggedClientErrors.count, 0)
    }

    func testSenderSignature() throws {
        XCTAssertEqual(
            try SetCollectMobileFinancialConnectionsResult.sender(
                value: .init(
                    financialConnectionsSession: .init(accounts: []),
                    token: nil,
                    error: nil
                )
            ).javascriptMessage(),
            """
            window.callSetterWithSerializableValue({"setter":"setCollectMobileFinancialConnectionsResult","value":{"financialConnectionsSession":{"accounts":[]}}});
            """
        )
    }
}

private extension SetCollectMobileFinancialConnectionsResultTests {
    func dictionary(fromJsonData data: Data) throws -> NSDictionary {
        let json = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(json as? NSDictionary)
    }
}
