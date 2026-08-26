//
//  NetworkedIdentityAPIClientTest.swift
//  StripeIdentityTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity
import XCTest

final class NetworkedIdentityAPIClientTest: APIStubbedTestCase {
    private static let merchantPublishableKey = "pk_test_merchant"
    private static let consumerPublishableKey = "pk_test_consumer"
    private static let clientVersion = "identity-client-version"
    private static let requestSurface = "web_identity_product"
    private static let consumerSessionClientSecret = "css_123"

    private static let consumerSessionJSON = """
        {
          "client_secret": "css_123",
          "email_address": "person@example.com",
          "redacted_phone_number": "******1234",
          "redacted_formatted_phone_number": "(***) ***-1234",
          "unredacted_phone_number": null,
          "phone_number_country": "US",
          "verification_sessions": [
            {
              "id": "cvs_123",
              "state": "VERIFIED",
              "type": "SMS",
              "verification_token": null
            }
          ]
        }
        """

    private var backingAPIClient: STPAPIClient!
    private var apiClient: NetworkedIdentityAPIClientImpl!

    override func setUp() {
        super.setUp()
        backingAPIClient = STPAPIClient(publishableKey: Self.merchantPublishableKey)
        let configuration = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: configuration)
        backingAPIClient.urlSession = URLSession(configuration: configuration)
        apiClient = makeAPIClient()
    }

    func testLookupConsumer() {
        let expectedParameters: [String: Any] = [
            "email_address": "person@example.com",
            "request_surface": Self.requestSurface,
            "cookies": [
                "verification_session_client_secrets": ["auth_1", "auth_2"],
            ],
        ]
        stubRequest(
            path: "/v1/consumers/sessions/lookup",
            authorizationKey: Self.merchantPublishableKey,
            expectedParameters: expectedParameters,
            responseJSON: """
                {
                  "exists": true,
                  "consumer_session": \(Self.consumerSessionJSON),
                  "publishable_key": "pk_test_consumer",
                  "account_id": "acct_123",
                  "auth_session_client_secret": null,
                  "email_otp_requires_additional_info": true,
                  "email_otp_verify_phone_despite_sms_otp": false,
                  "experiments": [
                    {
                      "experiment_name": "networked_identity",
                      "variant": "treatment",
                      "response_id": "response_123"
                    }
                  ]
                }
                """
        )

        assertSuccess(
            apiClient.lookupConsumer(
                emailAddress: "person@example.com",
                verificationSessionClientSecrets: ["auth_1", "auth_2"]
            )
        ) { response in
            guard case .found(let found) = response else {
                return XCTFail("Expected a found lookup response")
            }
            XCTAssertEqual(found.consumerSession.clientSecret, Self.consumerSessionClientSecret)
            XCTAssertEqual(found.publishableKey, Self.consumerPublishableKey)
            XCTAssertEqual(found.accountID, "acct_123")
            XCTAssertEqual(found.emailOTPRequiresAdditionalInfo, true)
            XCTAssertEqual(found.emailOTPVerifyPhoneDespiteSMSOTP, false)
            XCTAssertEqual(found.experiments.first?.responseID, "response_123")
        }
    }

    func testLookupConsumerNotFound() {
        stubRequest(
            path: "/v1/consumers/sessions/lookup",
            authorizationKey: Self.merchantPublishableKey,
            expectedParameters: [
                "email_address": "missing@example.com",
                "request_surface": Self.requestSurface,
            ],
            responseJSON: """
                {
                  "exists": false,
                  "error_message": "No account found"
                }
                """
        )

        assertSuccess(apiClient.lookupConsumer(emailAddress: "missing@example.com")) { response in
            guard case .notFound(let notFound) = response else {
                return XCTFail("Expected a not-found lookup response")
            }
            XCTAssertEqual(notFound.errorMessage, "No account found")
        }
    }

    func testSignUp() {
        let request = NetworkedIdentitySignUpRequest(
            emailAddress: "person@example.com",
            phoneNumber: "+15555551234",
            country: "US",
            countryInferringMethod: .phoneNumber,
            locale: "en-US",
            defaultOptInEnabled: true,
            changedPhoneNumber: false,
            checkedOptInBox: true,
            legalName: "Jenny Rosen",
            hcaptchaResponse: "captcha_response",
            hcaptchaKey: "captcha_key",
            sessionID: "session_123",
            verificationSessionClientSecrets: ["auth_1"]
        )
        stubRequest(
            path: "/v1/consumers/accounts/sign_up",
            authorizationKey: Self.merchantPublishableKey,
            expectedParameters: [
                "email_address": request.emailAddress,
                "phone_number": request.phoneNumber,
                "country": request.country,
                "country_inferring_method": "PHONE_NUMBER",
                "locale": request.locale,
                "consent_action": "entered_phone_number_email_clicked_save_with_link_identity",
                "request_surface": Self.requestSurface,
                "default_opt_in_enabled": true,
                "changed_phone_number": false,
                "checked_opt_in_box": true,
                "legal_name": "Jenny Rosen",
                "hcaptcha_response": "captcha_response",
                "hcaptcha_key": "captcha_key",
                "session_id": "session_123",
                "cookies": ["verification_session_client_secrets": ["auth_1"]],
            ],
            responseJSON: """
                {
                  "publishable_key": "pk_test_consumer",
                  "account_id": "acct_123",
                  "auth_session_client_secret": "auth_123",
                  "consumer_session": \(Self.consumerSessionJSON)
                }
                """
        )

        assertSuccess(apiClient.signUp(request: request)) { response in
            XCTAssertEqual(response.publishableKey, Self.consumerPublishableKey)
            XCTAssertEqual(response.accountID, "acct_123")
            XCTAssertEqual(response.authSessionClientSecret, "auth_123")
        }
    }

    func testStartVerification() {
        let request = NetworkedIdentityStartVerificationRequest(
            consumerSessionClientSecret: Self.consumerSessionClientSecret,
            type: .sms,
            locale: "en-US",
            accountPhoneNumber: "+15555551234",
            verificationSessionClientSecrets: ["auth_1"]
        )
        stubRequest(
            path: "/v1/consumers/sessions/start_verification",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: [
                    "type": "SMS",
                    "locale": "en-US",
                    "account_phone_number": "+15555551234",
                    "cookies": ["verification_session_client_secrets": ["auth_1"]],
                ]
            ),
            responseJSON: consumerSessionResponseJSON
        )

        assertSuccess(
            apiClient.startVerification(
                request: request,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.consumerSession.emailAddress, "person@example.com")
        }
    }

    func testConfirmVerification() {
        let request = NetworkedIdentityConfirmVerificationRequest(
            consumerSessionClientSecret: Self.consumerSessionClientSecret,
            code: "123456",
            type: .sms,
            verificationSessionClientSecrets: ["auth_1"]
        )
        stubRequest(
            path: "/v1/consumers/sessions/confirm_verification",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: [
                    "type": "SMS",
                    "code": "123456",
                    "cookies": ["verification_session_client_secrets": ["auth_1"]],
                ]
            ),
            responseJSON: consumerSessionResponseJSON
        )

        assertSuccess(
            apiClient.confirmVerification(
                request: request,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.consumerSession.verificationSessions.first?.state, .verified)
        }
    }

    func testListIdentityDocumentsRetriesOneServerError() {
        var requestCount = 0
        var retryDelay: TimeInterval?
        apiClient = makeAPIClient { delay, action in
            retryDelay = delay
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                if requestCount == 1 {
                    return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
                }
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "data": [
                            {
                              "id": "id_doc_123",
                              "document_type": "driving_license",
                              "created": 1700000000,
                              "country": "US",
                              "region": "NY",
                              "redacted_document_number": "******1234",
                              "expiration_date": 1800000000,
                              "live_captured": true
                            },
                            {
                              "id": "id_doc_future",
                              "document_type": "future_document_type",
                              "created": 1700000001
                            }
                          ]
                        }
                        """.utf8
                    ),
                    statusCode: 200,
                    headers: nil
                )
            }
        )

        assertSuccess(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(requestCount, 2)
            XCTAssertEqual(retryDelay, 0.25)
            XCTAssertEqual(response.data.first?.documentType, .drivingLicense)
            XCTAssertEqual(response.data.first?.expirationDate, 1_800_000_000)
            XCTAssertEqual(response.data.last?.documentType, .unparsable)
        }
    }

    func testListIdentityDocumentsStopsAfterTwoServerErrors() {
        var requestCount = 0
        var retryDelays: [TimeInterval] = []
        apiClient = makeAPIClient { delay, action in
            retryDelays.append(delay)
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "error": {
                            "type": "api_error",
                            "code": "server_error",
                            "message": "Server error"
                          }
                        }
                        """.utf8
                    ),
                    statusCode: 500,
                    headers: nil
                )
            }
        )

        assertFailure(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { _ in
            XCTAssertEqual(requestCount, 2)
            XCTAssertEqual(retryDelays, [0.25])
        }
    }

    func testListIdentityDocumentsDoesNotRetryClientError() {
        var requestCount = 0
        var didScheduleRetry = false
        apiClient = makeAPIClient { _, action in
            didScheduleRetry = true
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "error": {
                            "type": "invalid_request_error",
                            "code": "invalid_request",
                            "message": "Invalid request"
                          }
                        }
                        """.utf8
                    ),
                    statusCode: 400,
                    headers: nil
                )
            }
        )

        assertFailure(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { _ in
            XCTAssertEqual(requestCount, 1)
            XCTAssertFalse(didScheduleRetry)
        }
    }

    func testCreateAssociationToken() {
        stubRequest(
            path: "/v1/consumers/identity_documents/id_doc_123/association_token",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            responseJSON: """
                { "association_token": "assoc_123" }
                """
        )

        assertSuccess(
            apiClient.createAssociationToken(
                identityDocumentID: "id_doc_123",
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.associationToken, "assoc_123")
        }
    }

    func testLogOut() {
        stubRequest(
            path: "/v1/consumers/sessions/log_out",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: [
                    "cookies": ["verification_session_client_secrets": ["auth_1"]],
                ]
            ),
            responseJSON: consumerSessionResponseJSON
        )

        assertSuccess(
            apiClient.logOut(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                verificationSessionClientSecrets: ["auth_1"],
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.consumerSession.clientSecret, Self.consumerSessionClientSecret)
        }
    }

    func testExtendSession() {
        stubRequest(
            path: "/v1/consumers/sessions/extend",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            responseJSON: """
                { "consumer_session_client_secret": "css_rotated" }
                """
        )

        assertSuccess(
            apiClient.extendSession(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.consumerSessionClientSecret, "css_rotated")
        }
    }

    private var consumerSessionResponseJSON: String {
        return """
            {
              "consumer_session": \(Self.consumerSessionJSON),
              "auth_session_client_secret": null
            }
            """
    }

    private func makeAPIClient(
        retryScheduler: @escaping NetworkedIdentityAPIClientImpl.RetryScheduler = { delay, action in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                action()
            }
        }
    ) -> NetworkedIdentityAPIClientImpl {
        return NetworkedIdentityAPIClientImpl(
            apiClient: backingAPIClient,
            merchantPublishableKey: Self.merchantPublishableKey,
            clientVersion: Self.clientVersion,
            retryScheduler: retryScheduler
        )
    }

    private func consumerParameters(
        additionalParameters: [String: Any] = [:]
    ) -> [String: Any] {
        var parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": Self.consumerSessionClientSecret,
            ],
            "request_surface": Self.requestSurface,
        ]
        parameters.merge(additionalParameters) { _, new in new }
        return parameters
    }

    private func stubRequest(
        path: String,
        authorizationKey: String,
        expectedParameters: [String: Any],
        responseJSON: String
    ) {
        stubRequest(
            path: path,
            authorizationKey: authorizationKey,
            expectedParameters: expectedParameters
        ) { _ in
            HTTPStubsResponse(
                data: Data(responseJSON.utf8),
                statusCode: 200,
                headers: nil
            )
        }
    }

    private func stubRequest(
        path: String,
        authorizationKey: String,
        expectedParameters: [String: Any],
        response: @escaping (URLRequest) -> HTTPStubsResponse
    ) {
        stub { request in
            XCTAssertEqual(request.url?.path, path)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(authorizationKey)")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "X-Stripe-Identity-Client-Version"),
                Self.clientVersion
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Requested-With"), "fetch")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Content-Type"),
                "application/x-www-form-urlencoded"
            )
            XCTAssertEqual(
                request.ohhttpStubs_httpBody.flatMap { String(data: $0, encoding: .utf8) },
                URLEncoder.queryString(from: expectedParameters)
            )
            return true
        } response: { request in
            response(request)
        }
    }

    private func assertSuccess<Value>(
        _ promise: Promise<Value>,
        assertions: @escaping (Value) -> Void
    ) {
        let expectation = expectation(description: "Request completed")
        promise.observe { result in
            switch result {
            case .success(let value):
                assertions(value)
            case .failure(let error):
                XCTFail("Request failed: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    private func assertFailure<Value>(
        _ promise: Promise<Value>,
        assertions: @escaping (Error) -> Void
    ) {
        let expectation = expectation(description: "Request failed")
        promise.observe { result in
            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case .failure(let error):
                assertions(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}
