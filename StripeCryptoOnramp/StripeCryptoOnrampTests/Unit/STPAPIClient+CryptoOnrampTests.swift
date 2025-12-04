//
//  STPAPIClient+CryptoOnrampTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/17/25.
//

import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripeCryptoOnramp
@_spi(STP) import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

final class STPAPIClientCryptoOnrampTests: APIStubbedTestCase {

    private enum Constant {
        // Common
        static let requestSecret = "cscs_12345"
        static let errorDomain = "STPAPIClientCryptoOnrampTests.Error"
        static let validCustomerId = "crc_12345"

        // /v1/crypto/internal/customers
        static let createCryptoCustomerAPIPath = "/v1/crypto/internal/customers"
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
            dateOfBirth: .init(
                day: 31,
                month: 3,
                year: 1975
            )
        )
        static let kycMockResponseObject = KYCDataCollectionResponse(
            personId: "person_1A2BcD345EFg6HiJ",
            firstName: "John",
            lastName: "Smith",
            nationalities: [],
            residenceCountry: "US"
        )

        // /v1/crypto/internal/kyc_data_retrieve
        static let retrieveKYCInfoAPIPath = "/v1/crypto/internal/kyc_data_retrieve"

        // /v1/crypto/internal/refresh_consumer_person
        static let refreshKYCInfoAPIPath = "/v1/crypto/internal/refresh_consumer_person"
        static let validKycRefreshInfo = KYCRefreshInfo(
            firstName: validKycInfo.firstName,
            lastName: validKycInfo.lastName,
            dateOfBirth: validKycInfo.dateOfBirth,
            address: validKycInfo.address,
            idNumberLast4: String(validKycInfo.idNumber.suffix(4)),
            idType: .socialSecurityNumber
        )

        // /v1/crypto/internal/start_identity_verification
        static let startIdentityVerificationAPIPath = "/v1/crypto/internal/start_identity_verification"
        static let startIdentityVerificationMockResponseObject = StartIdentityVerificationResponse(
            id: "vs_1AbcdEF23gH4IJ5klMNoPqRs",
            url: URL(string: "https://verify.stripe.com/start/test_12345")!,
            ephemeralKey: "ek_test_12345"
        )

        // /v1/crypto/internal/wallet
        static let collectWalletAddressAPIPath = "/v1/crypto/internal/wallet"
        static let validWalletAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
        static let validNetwork = CryptoNetwork.bitcoin
        static let registerWalletMockResponseObject = RegisterWalletResponse(
            id: "ccw_12345"
        )

        // /v1/crypto/internal/onramp_session
        static let getOnrampSessionAPIPath = "/v1/crypto/internal/onramp_session"
        static let validOnrampSessionId = "cos_12345"
        static let validOnrampSessionClientSecret = "cos_12345_secret_12345"
        static let validPaymentIntentClientSecret = "pi_12345_secret_12345"
        static let validOnrampSessionResponseObject = OnrampSessionResponse(
            id: validOnrampSessionId,
            clientSecret: validOnrampSessionClientSecret,
            paymentIntentClientSecret: validPaymentIntentClientSecret
        )

        // /v1/crypto/internal/payment_token
        static let createPaymentTokenAPIPath = "/v1/crypto/internal/payment_token"
        static let validPaymentId = "pm_12345"
        static let validPaymentTokenId = "cpt_12345"
        static let validCreatePaymentTokenResponseObject = CreatePaymentTokenResponse(id: validPaymentTokenId)

        // /v1/crypto/internal/platform_settings
        static let getPlatformSettingsAPIPath = "/v1/crypto/internal/platform_settings"
        static let validPublishableKey = "pk_test_12345"
        static let validPlatformSettingsResponseObject = PlatformSettingsResponse(publishableKey: validPublishableKey)
    }

    private struct LinkAccountInfo: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        var sessionState: StripePaymentSheet.PaymentSheetLinkAccount.SessionState
        var consumerSessionClientSecret: String?
    }

    private let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        return jsonEncoder
    }()

    func testcreateCryptoCustomerSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(CustomerResponse(id: Constant.validCustomerId))

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.createCryptoCustomerAPIPath)
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
            let response = try await apiClient.createCryptoCustomer(with: Constant.validLinkAccountInfo)
            XCTAssertEqual(response.id, Constant.validCustomerId)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testcreateCryptoCustomerFailure() async {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.createCryptoCustomerAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.createCryptoCustomer(with: Constant.validLinkAccountInfo)
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testcreateCryptoCustomerThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.createCryptoCustomer(with: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.createCryptoCustomer(with: unverifiedLinkAccountInfo))
    }

    func testCollectKycInfoSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.kycMockResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.collectKycInfoAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 14)
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
            XCTAssertEqual(parameters["dob[day]"], "31")
            XCTAssertEqual(parameters["dob[month]"], "3")
            XCTAssertEqual(parameters["dob[year]"], "1975")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.collectKycInfo(info: Constant.validKycInfo, linkAccountInfo: Constant.validLinkAccountInfo)
            XCTAssertEqual(response.personId, "person_1A2BcD345EFg6HiJ")
            XCTAssertEqual(response.firstName, "John")
            XCTAssertEqual(response.lastName, "Smith")
            XCTAssertEqual(response.nationalities, [])
            XCTAssertEqual(response.residenceCountry, "US")
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

    func testRefreshKycInfoSuccess() async throws {
        let mockResponseData = try RefreshKYCInfoResponseMock.refreshKYCInfoResponse_200.data()

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.refreshKYCInfoAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 14)
            XCTAssertEqual(parameters["credentials[consumer_session_client_secret]"], Constant.requestSecret)
            XCTAssertEqual(parameters["first_name"], "John")
            XCTAssertEqual(parameters["last_name"], "Smith")
            XCTAssertEqual(parameters["id_number_last4"], "6789")
            XCTAssertEqual(parameters["id_type"], "social_security_number")
            XCTAssertEqual(parameters["line1"], "123%20Fake%20Street")
            XCTAssertEqual(parameters["line2"], "APT%202")
            XCTAssertEqual(parameters["city"], "Brooklyn")
            XCTAssertEqual(parameters["state"], "New%20York")
            XCTAssertEqual(parameters["zip"], "11201")
            XCTAssertEqual(parameters["country"], "US")
            XCTAssertEqual(parameters["dob[day]"], "31")
            XCTAssertEqual(parameters["dob[month]"], "3")
            XCTAssertEqual(parameters["dob[year]"], "1975")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.refreshKycInfo(
                info: Constant.validKycRefreshInfo,
                linkAccountInfo: Constant.validLinkAccountInfo
            )
            XCTAssertTrue(response.allResponseFields.isEmpty)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }

    }

    func testRefreshKycInfoThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(
            _ = try await apiClient.refreshKycInfo(
                info: Constant.validKycRefreshInfo,
                linkAccountInfo: noSecretLinkAccountInfo
            )
        )

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(
            _ = try await apiClient.refreshKycInfo(
                info: Constant.validKycRefreshInfo,
                linkAccountInfo: unverifiedLinkAccountInfo
            )
        )
    }

    func testRetrieveKycInfoSuccess() async throws {
        let mockResponseData = try RetrieveKYCInfoResponseMock.retrieveKYCInfoResponse_200.data()

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.retrieveKYCInfoAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 1)
            XCTAssertEqual(parameters["credentials[consumer_session_client_secret]"], Constant.requestSecret)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.retrieveKycInfo(linkAccountInfo: Constant.validLinkAccountInfo)
            let kycInfo = response.kycInfo
            XCTAssertEqual(kycInfo.firstName, "John")
            XCTAssertEqual(kycInfo.lastName, "Smith")

            let dateOfBirth = kycInfo.dateOfBirth
            XCTAssertEqual(dateOfBirth.day, 31)
            XCTAssertEqual(dateOfBirth.month, 3)
            XCTAssertEqual(dateOfBirth.year, 1975)

            let address = kycInfo.address
            XCTAssertEqual(address.line1, "123 Fake Street")
            XCTAssertEqual(address.line2, "APT 2")
            XCTAssertEqual(address.city, "Brooklyn")
            XCTAssertEqual(address.state, "New York")
            XCTAssertEqual(address.postalCode, "11201")
            XCTAssertEqual(address.country, "US")
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testRetrieveKycInfoThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.retrieveKycInfo(linkAccountInfo: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.retrieveKycInfo(linkAccountInfo: unverifiedLinkAccountInfo))
    }

    func testStartIdentityVerificationSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.startIdentityVerificationMockResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.startIdentityVerificationAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 2)
            XCTAssertEqual(parameters["credentials[consumer_session_client_secret]"], Constant.requestSecret)
            XCTAssertEqual(parameters["is_mobile"], "true")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.startIdentityVerification(linkAccountInfo: Constant.validLinkAccountInfo)
            XCTAssertEqual(response.id, "vs_1AbcdEF23gH4IJ5klMNoPqRs")
            XCTAssertEqual(response.url, URL(string: "https://verify.stripe.com/start/test_12345"))
            XCTAssertEqual(response.ephemeralKey, "ek_test_12345")
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }

    }

    func testStartIdentityVerificationThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.startIdentityVerification(linkAccountInfo: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.startIdentityVerification(linkAccountInfo: unverifiedLinkAccountInfo))
    }

    func testCollectWalletAddressSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.registerWalletMockResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.collectWalletAddressAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 3)
            XCTAssertEqual(parameters["credentials[consumer_session_client_secret]"], Constant.requestSecret)
            XCTAssertEqual(parameters["wallet_address"], Constant.validWalletAddress)
            XCTAssertEqual(parameters["network"], Constant.validNetwork.rawValue)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.collectWalletAddress(
                walletAddress: Constant.validWalletAddress,
                network: Constant.validNetwork,
                linkAccountInfo: Constant.validLinkAccountInfo
            )
            XCTAssertEqual(response.id, Constant.registerWalletMockResponseObject.id)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testCollectWalletAddressFailure() async {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.collectWalletAddressAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.collectWalletAddress(
                walletAddress: Constant.validWalletAddress,
                network: Constant.validNetwork,
                linkAccountInfo: Constant.validLinkAccountInfo
            )
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testCollectWalletAddressThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(
            _ = try await apiClient.collectWalletAddress(
                walletAddress: Constant.validWalletAddress,
                network: Constant.validNetwork,
                linkAccountInfo: noSecretLinkAccountInfo
            )
        )

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(
            _ = try await apiClient.collectWalletAddress(
                walletAddress: Constant.validWalletAddress,
                network: Constant.validNetwork,
                linkAccountInfo: unverifiedLinkAccountInfo
            )
        )
    }

    func testGetOnrampSessionSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.validOnrampSessionResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.getOnrampSessionAPIPath)
            XCTAssertEqual(request.httpMethod, "GET")

            guard let queryParametersString = request.url?.query else {
                XCTFail("Expected query parameters but found none.")
                return false
            }

            let parameters = queryParametersString.parsedHTTPParametersDictionary
            XCTAssertEqual(parameters.count, 2)
            XCTAssertEqual(parameters["crypto_onramp_session"], Constant.validOnrampSessionId)
            XCTAssertEqual(parameters["client_secret"], Constant.validOnrampSessionClientSecret)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.getOnrampSession(
                sessionId: Constant.validOnrampSessionId,
                sessionClientSecret: Constant.validOnrampSessionClientSecret
            )
            XCTAssertEqual(response.id, Constant.validOnrampSessionId)
            XCTAssertEqual(response.clientSecret, Constant.validOnrampSessionClientSecret)
            XCTAssertEqual(response.paymentIntentClientSecret, Constant.validPaymentIntentClientSecret)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }

    }

    func testGetOnrampSessionFailure() async throws {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.getOnrampSessionAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.getOnrampSession(
                sessionId: Constant.validOnrampSessionId,
                sessionClientSecret: Constant.validOnrampSessionClientSecret
            )
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testCreatePaymentTokenSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.validCreatePaymentTokenResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.createPaymentTokenAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            let parameters = String(data: httpBody, encoding: .utf8)?.parsedHTTPParametersDictionary ?? [:]

            XCTAssertEqual(parameters.count, 2)
            XCTAssertEqual(parameters["payment_method"], Constant.validPaymentId)
            XCTAssertEqual(parameters["crypto_customer_id"], Constant.validCustomerId)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.createPaymentToken(for: Constant.validPaymentId, cryptoCustomerId: Constant.validCustomerId)
            XCTAssertEqual(response.id, Constant.validPaymentTokenId)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testCreatePaymentTokenFailure() async throws {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.createPaymentTokenAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.createPaymentToken(
                for: Constant.validPaymentId,
                cryptoCustomerId: Constant.validCustomerId
            )
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testGetPlatformSettingsSuccess() async throws {
        let mockResponseData = try jsonEncoder.encode(Constant.validPlatformSettingsResponseObject)

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.getPlatformSettingsAPIPath)
            XCTAssertEqual(request.httpMethod, "GET")

            guard let queryParametersString = request.url?.query else {
                XCTFail("Expected query parameters but found none.")
                return false
            }

            let parameters = queryParametersString.parsedHTTPParametersDictionary

            XCTAssertEqual(parameters.count, 1)
            XCTAssertEqual(parameters["crypto_customer_id"], Constant.validCustomerId)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()

        do {
            let response = try await apiClient.getPlatformSettings(cryptoCustomerId: Constant.validCustomerId)
            XCTAssertEqual(response.publishableKey, Constant.validPublishableKey)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }
    }

    func testGetPlatformSettingsFailure() async throws {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.getPlatformSettingsAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.getPlatformSettings(cryptoCustomerId: Constant.validCustomerId)
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }
}

private extension String {
    var parsedHTTPParametersDictionary: [String: String] {
        let pairs = components(separatedBy: "&")
        return pairs.reduce(into: [:]) { result, pair in
            let splitPair = pair.components(separatedBy: "=")
            guard splitPair.count == 2 else { return }
            result[splitPair[0]] = splitPair[1]
        }
    }
}
