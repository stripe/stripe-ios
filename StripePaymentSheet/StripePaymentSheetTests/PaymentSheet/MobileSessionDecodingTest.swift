//
//  MobileSessionDecodingTest.swift
//  StripePaymentSheetTests
//
//  Proves the generated mobile-session structs decode against the real StripeCore
//  StripeJSONDecoder / StripeJSONEncoder. Seeds the Mint endpoint contract:
//  PaymentSheetConfigV1 in, MobilePaymentElementV1 out.
//

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class MobileSessionDecodingTest: XCTestCase {
    func testGeneratedRequestGoldenFixturesDecodeAndReencode() throws {
        for fixture in [
            "minimum_request",
            "fully_populated_request",
            "omitted_optional_request_field",
            "explicit_null_request_field",
        ] {
            let decoded = try StripeJSONDecoder().decode(
                PaymentSheetConfigV1.self,
                from: fixtureData(fixture)
            )
            let reencoded = try StripeJSONEncoder().encode(decoded)
            XCTAssertEqual(
                try StripeJSONDecoder().decode(PaymentSheetConfigV1.self, from: reencoded),
                decoded,
                fixture
            )
        }
    }

    func testGeneratedResponseGoldenFixturesDecodeAndReencode() throws {
        for fixture in [
            "minimum_response",
            "fully_populated_response",
            "unknown_optional_response_field",
            "unknown_extensible_value_response",
        ] {
            let decoded = try StripeJSONDecoder().decode(
                MobilePaymentElementV1.self,
                from: fixtureData(fixture)
            )
            let reencoded = try StripeJSONEncoder().encode(decoded)
            XCTAssertEqual(
                try StripeJSONDecoder().decode(MobilePaymentElementV1.self, from: reencoded),
                decoded,
                fixture
            )
        }
    }

    func testGeneratedResponseRetainsUnknownOptionalFields() throws {
        let decoded = try StripeJSONDecoder().decode(
            MobilePaymentElementV1.self,
            from: fixtureData("unknown_optional_response_field")
        )

        XCTAssertEqual(decoded.allResponseFields["future_optional_field"] as? Bool, true)
    }

    func testGeneratedResponseDecodesServerRequiredFormScreen() throws {
        let decoded = try StripeJSONDecoder().decode(
            MobilePaymentElementV1.self,
            from: fixtureData("fully_populated_response")
        )

        XCTAssertEqual(decoded.formSpecs.first?.requiresFormScreen, true)
    }

    func testGeneratedInvalidRequiredFieldFixtureFails() throws {
        XCTAssertThrowsError(
            try StripeJSONDecoder().decode(
                MobilePaymentElementV1.self,
                from: fixtureData("invalid_required_response_field")
            )
        )
    }

    func testGeneratedManifestMatchesCompiledContract() throws {
        let manifest = try XCTUnwrap(
            JSONSerialization.jsonObject(with: manifestData()) as? [String: Any]
        )

        XCTAssertEqual(manifest["contract_major"] as? Int, MobileSessionContractV1.contractMajor)
        XCTAssertEqual(manifest["contract_revision"] as? String, MobileSessionContractV1.contractRevision)
        XCTAssertEqual(manifest["contract_digest"] as? String, MobileSessionContractV1.contractDigest)
        XCTAssertEqual(manifest["generator_digest"] as? String, MobileSessionContractV1.generatorDigest)
        XCTAssertEqual(manifest["mint_commit"] as? String, MobileSessionContractV1.mintCommit)
    }

    func testDecodesPaymentMethodAvailability() throws {
        let json = """
        {
          "contract": {
            "major": \(MobileSessionContractV1.contractMajor),
            "revision": "\(MobileSessionContractV1.contractRevision)"
          },
          "payment_method_availability": ["card", "link"]
        }
        """
        let response = try StripeJSONDecoder().decode(
            MobilePaymentElementV1.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(response.contract.major, MobileSessionContractV1.contractMajor)
        XCTAssertEqual(response.contract.revision, MobileSessionContractV1.contractRevision)
        XCTAssertEqual(response.paymentMethodAvailability, ["card", "link"])
    }

    /// The request the client sends up round-trips through the real encoder/decoder.
    func testPaymentSheetConfigRoundTrips() throws {
        let config = PaymentSheetConfigV1(
            merchantCountryCode: "GB",
            allowsDelayedPaymentMethods: true,
            paymentMethodOrder: ["card", "link"]
        )
        let data = try StripeJSONEncoder().encode(config)
        let decoded = try StripeJSONDecoder().decode(PaymentSheetConfigV1.self, from: data)
        XCTAssertEqual(decoded, config)
        // camelCase property serializes to the snake_case wire key.
        XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("merchant_country_code"))
    }

    func testV2FixturesDecodeIndependentlyFromV1() throws {
        for fixture in [
            "minimum_request",
            "fully_populated_request",
            "omitted_optional_request_field",
            "explicit_null_request_field",
        ] {
            let decoded = try StripeJSONDecoder().decode(
                PaymentSheetConfigV2.self,
                from: fixtureData(fixture, major: 2)
            )
            let reencoded = try StripeJSONEncoder().encode(decoded)
            XCTAssertEqual(
                try StripeJSONDecoder().decode(PaymentSheetConfigV2.self, from: reencoded),
                decoded,
                fixture
            )
        }

        for fixture in [
            "minimum_response",
            "fully_populated_response",
            "unknown_optional_response_field",
            "unknown_extensible_value_response",
        ] {
            let decoded = try StripeJSONDecoder().decode(
                MobilePaymentElementV2.self,
                from: fixtureData(fixture, major: 2)
            )
            let reencoded = try StripeJSONEncoder().encode(decoded)
            XCTAssertEqual(
                try StripeJSONDecoder().decode(MobilePaymentElementV2.self, from: reencoded),
                decoded,
                fixture
            )
        }

        let response = try StripeJSONDecoder().decode(
            MobilePaymentElementV2.self,
            from: fixtureData("fully_populated_response", major: 2)
        )

        XCTAssertEqual(response.contract.major, MobileSessionContractV2.contractMajor)
        XCTAssertFalse(response.paymentMethodAvailability.entries.isEmpty)

        let unknownFieldResponse = try StripeJSONDecoder().decode(
            MobilePaymentElementV2.self,
            from: fixtureData("unknown_optional_response_field", major: 2)
        )
        XCTAssertEqual(unknownFieldResponse.allResponseFields["future_optional_field"] as? Bool, true)

        XCTAssertThrowsError(
            try StripeJSONDecoder().decode(
                MobilePaymentElementV2.self,
                from: fixtureData("invalid_required_response_field", major: 2)
            )
        )

        let manifest = try XCTUnwrap(
            JSONSerialization.jsonObject(with: manifestData(major: 2)) as? [String: Any]
        )
        XCTAssertEqual(manifest["contract_major"] as? Int, MobileSessionContractV2.contractMajor)
        XCTAssertEqual(manifest["contract_revision"] as? String, MobileSessionContractV2.contractRevision)
        XCTAssertEqual(manifest["contract_digest"] as? String, MobileSessionContractV2.contractDigest)
        XCTAssertEqual(manifest["generator_digest"] as? String, MobileSessionContractV2.generatorDigest)
        XCTAssertEqual(manifest["mint_commit"] as? String, MobileSessionContractV2.mintCommit)
    }

    private func fixtureData(_ name: String, major: Int = 1) throws -> Data {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/MobileSession/v\(major)/\(name).json")
        return try Data(contentsOf: fixtureURL)
    }

    private func manifestData(major: Int = 1) throws -> Data {
        let manifestURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(
                "../../StripePaymentSheet/Source/Internal/API Bindings/" +
                    "v1-elements-sessions/MobileSessionV\(major).manifest.json"
            )
            .standardizedFileURL
        return try Data(contentsOf: manifestURL)
    }
}
