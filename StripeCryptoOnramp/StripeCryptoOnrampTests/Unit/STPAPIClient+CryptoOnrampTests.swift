//
//  STPAPIClient+CryptoOnrampTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/17/25.
//

import StripeCore
import StripeCoreTestUtils
@testable @_spi(CryptoOnrampSDKPreview) import StripeCryptoOnramp
@_spi(STP) import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

final class STPAPIClientCryptoOnrampTests: APIStubbedTestCase {

    private enum Constant {
        // Common
        static let requestSecret = "cscs_12345"
        static let errorDomain = "STPAPIClientCryptoOnrampTests.Error"

        // /v1/crypto/internal/customers
        static let grantPartnerMerchantPermissionsAPIPath = "/v1/crypto/internal/customers"
        static let responseID = "crc_12345"
        static let validLinkAccountInfo = LinkAccountInfo(
            email: "test@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: requestSecret
        )

        // /v1/crypto/internal/kyc_data_collection
        static let collectKycInfoAPIPath = "/v1/crypto/internal/kyc_data_collection"
        static let validKycInfo = KycInfo(
            firstName: "John",
            lastName: "Smith",
            idNumber: "123456789",
            address: .init(
                city: "Brooklyn",
                country: "US",
                line1: "123 Fake Street",
                line2: "APT 2",
                postalCode: "11201",
                state: "New York"
            ),
            dateOfBirth: Date(timeIntervalSince1970: 0),
            birthCountry: "US",
            birthCity: "Pittsburgh"
        )
        static let kycMockResponseObject = KYCDataCollectionResponse(
            personId: "person_1A2BcD345EFg6HiJ",
            firstName: "John",
            lastName: "Smith",
            nationalities: [],
            residenceCountry: "US"
        )
    }

    private struct LinkAccountInfo: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        var sessionState: StripePaymentSheet.PaymentSheetLinkAccount.SessionState
        var consumerSessionClientSecret: String?
    }

    func testGrantPartnerMerchantPermissionsSuccess() async throws {
        let mockResponseData = try JSONEncoder().encode(CustomerResponse(id: Constant.responseID))

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.grantPartnerMerchantPermissionsAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "credentials[consumer_session_client_secret]=\(Constant.requestSecret)")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        do {
            let response = try await apiClient.grantPartnerMerchantPermissions(with: Constant.validLinkAccountInfo)
            XCTAssertEqual(response.id, Constant.responseID)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testGrantPartnerMerchantPermissionsFailure() async {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.grantPartnerMerchantPermissionsAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.grantPartnerMerchantPermissions(with: Constant.validLinkAccountInfo)
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testGrantPartnerMerchantPermissionsThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.grantPartnerMerchantPermissions(with: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.grantPartnerMerchantPermissions(with: unverifiedLinkAccountInfo))
    }

    func testCollectKycInfoSuccess() async throws {
        let mockResponseData = try JSONEncoder().encode(Constant.kycMockResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.collectKycInfoAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPBodyDictionary ?? [:]

            XCTAssertEqual(parameters.count, 16)
            XCTAssertEqual(parameters["credentials[consumer_session_client_secret]"], Constant.requestSecret)
            XCTAssertEqual(parameters["first_name"], "John")
            XCTAssertEqual(parameters["last_name"], "Smith")
            XCTAssertEqual(parameters["id_number"], "123456789")
            XCTAssertEqual(parameters["id_type"], "social_security_number")
            XCTAssertEqual(parameters["line1"], "123%20Fake%20Street")
            XCTAssertEqual(parameters["line2"], "APT%202")
            XCTAssertEqual(parameters["city"], "Brooklyn")
            XCTAssertEqual(parameters["state"], "New%20York")
            XCTAssertEqual(parameters["zip"], "11201")
            XCTAssertEqual(parameters["country"], "US")
            XCTAssertEqual(parameters["birth_country"], "US")
            XCTAssertEqual(parameters["birth_city"], "Pittsburgh")
            XCTAssertEqual(parameters["dob[day]"], "1")
            XCTAssertEqual(parameters["dob[month]"], "1")
            XCTAssertEqual(parameters["dob[year]"], "1970")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        guard let fixedGMTCalendar = Calendar.makeFixedTimeZoneCalendar(hoursFromGMT: 0) else {
            XCTFail("Failed to create a fixed-timezone calendar.")
            return
        }

        do {
            let response = try await apiClient.collectKycInfo(info: Constant.validKycInfo, linkAccountInfo: Constant.validLinkAccountInfo, calendar: fixedGMTCalendar)
            XCTAssertEqual(response.personId, "person_1A2BcD345EFg6HiJ")
            XCTAssertEqual(response.firstName, "John")
            XCTAssertEqual(response.lastName, "Smith")
            XCTAssertEqual(response.nationalities, [])
            XCTAssertEqual(response.residenceCountry, "US")
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testCollectKycInfoConsidersTimeZone() async throws {
        let mockResponseData = try JSONEncoder().encode(Constant.kycMockResponseObject)

        stub { request in
            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPBodyDictionary ?? [:]
            XCTAssertEqual(parameters["dob[day]"], "31")
            XCTAssertEqual(parameters["dob[month]"], "12")
            XCTAssertEqual(parameters["dob[year]"], "1969")
            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        // Adjust the calendar to use a time zone one hour before GMT. This makes the reference timestamp
        // fall into the prior calendar date. Above we assert that the serialized date is 12/31/1969 instead of 1/1/1970.
        guard let fixedEDTCalendar = Calendar.makeFixedTimeZoneCalendar(hoursFromGMT: -1) else {
            XCTFail("Failed to create a fixed-timezone calendar.")
            return
        }

        do {
            _ = try await apiClient.collectKycInfo(info: Constant.validKycInfo, linkAccountInfo: Constant.validLinkAccountInfo, calendar: fixedEDTCalendar)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testCollectKycInfoThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.collectKycInfo(info: Constant.validKycInfo, linkAccountInfo: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.collectKycInfo(info: Constant.validKycInfo, linkAccountInfo: unverifiedLinkAccountInfo))
    }
}

private extension String {
    var parsedHTTPBodyDictionary: [String: String] {
        let pairs = components(separatedBy: "&")
        return pairs.reduce(into: [:]) { result, pair in
            let splitPair = pair.components(separatedBy: "=")
            guard splitPair.count == 2 else { return }
            result[splitPair[0]] = splitPair[1]
        }
    }
}

private extension Calendar {
    static func makeFixedTimeZoneCalendar(hoursFromGMT: Int) -> Calendar? {
        guard let timeZone = TimeZone(secondsFromGMT: hoursFromGMT * 3600) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
