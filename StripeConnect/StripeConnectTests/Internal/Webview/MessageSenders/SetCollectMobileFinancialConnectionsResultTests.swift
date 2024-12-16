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
                token: nil
            )
        ))
    }

    let mockAnalyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
    let bundle = Bundle(for: SetCollectMobileFinancialConnectionsResultTests.self)

    func testEncodingValue() throws {
        let session = try FinancialConnectionsSessionMock.default.make()
        let sheetResult = FinancialConnectionsSheet.TokenResult.completed(session: session)
        let payloadValue = sheetResult.toSenderValue(sessionId: "fcsess_testststststm", analyticsClient: mockAnalyticsClient)

        XCTAssertNotNil(payloadValue?.financialConnectionsSession)
        XCTAssertNotNil(payloadValue?.token)

        // No errors should be logged
        XCTAssertEqual(mockAnalyticsClient.loggedEvents, [])

        // Encode to JSON dictionary using Connect encoder
        let encodedJsonDict = try dictionary(
            fromJsonData: try SetCollectMobileFinancialConnectionsResult
                .sender(value: payloadValue)
                .jsonData()
        )

        // Load expected
        var expectedSessionJsonDict = try dictionary(
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
        let payloadValue = sheetResult.toSenderValue(
            sessionId: "fcsess_testststststm",
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertEqual(payloadValue?.financialConnectionsSession.accounts, [])
        XCTAssertNil(payloadValue?.token)
        XCTAssertEqual(mockAnalyticsClient.loggedEvents, [])
    }

    func testPayloadValue_error() throws {
        let sheetResult = FinancialConnectionsSheet.TokenResult.failed(error: NSError(domain: "MockError", code: 0, userInfo: [NSDebugDescriptionErrorKey: "description"]))
        let payloadValue = sheetResult.toSenderValue(
            sessionId: "fcsess_123",
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertNil(payloadValue)
        XCTAssertEqual(mockAnalyticsClient.loggedEvents.count, 1)

        let event = try XCTUnwrap(mockAnalyticsClient.loggedEvents.first as? FinancialConnectionsErrorEvent)
        XCTAssertEqual(event.metadata.error, "MockError:0")
        XCTAssertEqual(event.metadata.errorDescription, "description")
        XCTAssertEqual(event.metadata.sessionId, "fcsess_123")
    }

    func testSenderSignature() throws {
        XCTAssertEqual(
            try SetCollectMobileFinancialConnectionsResult.sender(
                value: .init(
                    financialConnectionsSession: .init(accounts: []),
                    token: nil
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
