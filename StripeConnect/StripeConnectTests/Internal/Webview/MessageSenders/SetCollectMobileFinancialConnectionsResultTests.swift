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
                id: "1234",
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
        let payloadValue = sheetResult.toSenderValue(id: "1234", analyticsClient: mockAnalyticsClient)

        XCTAssertNotNil(payloadValue.financialConnectionsSession)
        XCTAssertNotNil(payloadValue.token)
        XCTAssertEqual(payloadValue.id, "1234")

        // No errors should be logged
        XCTAssertEqual(mockAnalyticsClient.loggedEvents, [])

        // Encode to JSON dictionary using Connect encoder
        let encodedJsonDict = try dictionary(
            fromJsonData: try SetCollectMobileFinancialConnectionsResult
                .sender(value: payloadValue)
                .jsonData()
        ) as NSDictionary

        // Load expected
        var expectedSessionJsonDict = try dictionary(
            fromJsonData: try Data(
                contentsOf: bundle.url(
                    forResource: "FinancialConnectionsSession_encodedJS",
                    withExtension: "json"
                )!
            )
        )
        expectedSessionJsonDict["id"] = "1234"

        // Cast Swift types to Objc types so CustomDump comparison passes
        expectNoDifference(encodedJsonDict, [
            "setter": "setCollectMobileFinancialConnectionsResult",
            "value": expectedSessionJsonDict,
        ])
    }

    func testPayloadValue_canceled() throws {
        let sheetResult = FinancialConnectionsSheet.TokenResult.canceled
        let payloadValue = sheetResult.toSenderValue(
            id: "1234",
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertEqual(payloadValue.id, "1234")
        XCTAssertEqual(payloadValue.financialConnectionsSession?.accounts, [])
        XCTAssertNil(payloadValue.token)
    }

    func testPayloadValue_error() throws {
        let sheetResult = FinancialConnectionsSheet.TokenResult.failed(error: NSError(domain: "mockError", code: 0))
        let payloadValue = sheetResult.toSenderValue(
            id: "1234",
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertEqual(payloadValue.id, "1234")
        XCTAssertNil(payloadValue.financialConnectionsSession)
        XCTAssertNil(payloadValue.token)
    }

    func testSenderSignature() throws {
        XCTAssertEqual(
            try SetCollectMobileFinancialConnectionsResult.sender(
                value: .init(
                    id: "1234",
                    financialConnectionsSession: .init(accounts: []),
                    token: nil
                )
            ).javascriptMessage(),
            """
            window.callSetterWithSerializableValue({"setter":"setCollectMobileFinancialConnectionsResult","value":{"financialConnectionsSession":{"accounts":[]},"id":"1234"}});
            """
        )
    }
}

private extension SetCollectMobileFinancialConnectionsResultTests {
    func dictionary(fromJsonData data: Data) throws -> [String: Any] {
        let json = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(json as? [String: Any])
    }
}
