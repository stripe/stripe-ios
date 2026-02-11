//
//  MPELatencyTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 1/8/26.
//
//  📣 These tests are special; they don't fail and aren't meant to run in normal CI jobs.
//  Instead, they measure MPE load times under various configurations and report the results under the `mpe.synthetic_latency` analytic
//  Seealso: The `StripePaymentSheet-LatencyTests` scheme.

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePaymentsTestUtils
import XCTest

/// Captures URLSession task metrics for a single request, including timing breakdown for DNS lookup, TCP/TLS connection, request send, and response receive.
struct RequestMetrics {
    let dict: [String: Codable]

    init(path: String, transactionMetric: URLSessionTaskTransactionMetrics) {
        func getDurationInMs(_ start: Date?, _ end: Date?) -> Double? {
            guard let start, let end else { return nil }
            return end.timeIntervalSince(start) * 1000.0
        }

        let dict: [String: Codable?] = [
            "path": path,
            "connection_reused": transactionMetric.isReusedConnection,
            "task_start_ms": getDurationInMs(transactionMetric.fetchStartDate, transactionMetric.domainLookupStartDate),
            "dns_ms": getDurationInMs(transactionMetric.domainLookupStartDate, transactionMetric.domainLookupEndDate),
            "tcp_ms": getDurationInMs(transactionMetric.connectStartDate, transactionMetric.secureConnectionStartDate),
            "tls_ms": getDurationInMs(transactionMetric.secureConnectionStartDate, transactionMetric.secureConnectionEndDate),
            "connection_ms": getDurationInMs(transactionMetric.connectStartDate, transactionMetric.connectEndDate),
            "request_ms": getDurationInMs(transactionMetric.requestStartDate, transactionMetric.requestEndDate),
            "request_inflight_ms": getDurationInMs(transactionMetric.requestEndDate, transactionMetric.responseStartDate),
            "response_ms": getDurationInMs(transactionMetric.responseStartDate, transactionMetric.responseEndDate),
            "total_ms": getDurationInMs(transactionMetric.fetchStartDate, transactionMetric.responseEndDate),
        ]
        self.dict = dict.compactMapValues { $0 }
    }
}

/// Analytic payload containing overall load duration and per-request timing breakdowns.
/// The `requests` array contains detailed metrics for each network request made during load.
struct LatencyAnalytic: Analytic {
    let event: StripeCore.STPAnalyticEvent = .mpeSyntheticLatency
    var params: [String: Any]

    init(
        test: String,
        duration: TimeInterval,
        requests: [RequestMetrics]
    ) {
        var analyticsParams: [String: Any] = [
            "test": test,
            "duration": duration,
            "requests": requests.map { $0.dict },
        ]
        if let commitHash = ProcessInfo.processInfo.environment["BITRISE_GIT_COMMIT"] {
            print("commitHash: ", commitHash)
            analyticsParams["commit_hash"] = commitHash
        }
        if let buildURL = ProcessInfo.processInfo.environment["BITRISE_BUILD_URL"] {
            print("buildURL: ", buildURL)
            analyticsParams["build_url"] = buildURL
        }

        params = analyticsParams
    }
}

final class MPELatencyTest: XCTestCase {
    // The `RECORD_LATENCY_TESTS` env variable should only be set in the `latency-tests` CI job
    let isCILatencyTestRun = ProcessInfo.processInfo.environment["RECORD_LATENCY_TESTS"] == "true"
    let urlSessionMetricsCollector = URLSessionMetricsCollector()
    lazy var apiClient: STPAPIClient = {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        apiClient.urlSession = URLSession(
            configuration: .default,
            delegate: urlSessionMetricsCollector,
            delegateQueue: nil
        )
        return apiClient
    }()

    // MARK: - Tests

    func test_default() async throws {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        try await _measureLoadLatency(configuration: configuration)

        XCTAssertFalse(didCallLinkLookupEndpoint, "Did not expect Link lookup endpoint to be called")
    }

    func test_customer_legacy() async throws {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        // Use a customer w/ saved card and bank account
        let testCustomerID = "cus_TZCcZWKC57HHmr"
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "us")
        configuration.customer = .init(id: testCustomerID, ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        try await _measureLoadLatency(configuration: configuration)
        XCTAssertFalse(didCallLinkLookupEndpoint, "Did not expect Link lookup endpoint to be called")
    }

    func test_customer_customersession() async throws {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        // Use a customer w/ saved card and bank account
        let testCustomerID = "cus_TZCcZWKC57HHmr"
        let customerAndCustomerSession = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(
            customerID: testCustomerID,
            merchantCountry: "us",
            paymentMethodSave: true,
            paymentMethodRemove: true,
            paymentMethodSetAsDefault: true
        )
        configuration.customer = .init(id: customerAndCustomerSession.customer, customerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret)

        try await _measureLoadLatency(configuration: configuration)
        XCTAssertFalse(didCallLinkLookupEndpoint, "Did not expect Link lookup endpoint to be called")
    }

    /// CustomerSession + Customer w/ an email, triggering link lookup
    func test_customer_customersession_and_link() async throws {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        // Use a customer w/ an email
        // Why email? It's very specific to the current link lookup logic. The slowest codepath is when there is (1) no defaultBillingDetails.email (2) customer has email because it retrieves the Customer before doing the link lookup
        let testCustomerID = "cus_TqanA973bOrpoP"

        let customerAndCustomerSession = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(
            customerID: testCustomerID,
            merchantCountry: "us",
            paymentMethodSave: true,
            paymentMethodRemove: true,
            paymentMethodSetAsDefault: true
        )
        configuration.customer = .init(id: customerAndCustomerSession.customer, customerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret)

        try await _measureLoadLatency(configuration: configuration)
        XCTAssertTrue(didCallLinkLookupEndpoint, "Expected Link lookup endpoint to be called")
    }
}

// MARK: - Helpers
extension MPELatencyTest {

    /// URLSession delegate that collects detailed timing metrics for each network request.
    /// Used to capture per-request breakdowns that are later sent to analytics.
    final class URLSessionMetricsCollector: NSObject, URLSessionTaskDelegate {
        var collectedMetrics: [RequestMetrics] = []

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didFinishCollecting metrics: URLSessionTaskMetrics
        ) {
            // Record metrics in `collectedMetrics`, to be sent to analytics later.
            let requestPath = task.currentRequest?.url?.path ?? task.originalRequest?.url?.path ?? "unknown"
            for metric in metrics.transactionMetrics {
                let requestMetric = RequestMetrics(path: requestPath, transactionMetric: metric)
                collectedMetrics.append(requestMetric)
                print(requestMetric.dict)
            }
        }
    }

    func _measureLoadLatency(configuration: PaymentSheet.Configuration) async throws {
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration
        )
        let mode = PaymentSheet.InitializationMode.deferredIntent(._testValue())

        // 1. Load
        let startDate = Date()
        _ = try await PaymentSheetLoader.load(
            mode: mode,
            configuration: configuration,
            analyticsHelper: analyticsHelper,
            integrationShape: .complete
        )
        let endDate = Date()

        // 2. Log load stats
        let duration = endDate.timeIntervalSince(startDate)
        let analyticsClient = STPTestingAnalyticsClient()
        // Only send analytics in the CI latency-tests job so that the environment is consistent.
        if isCILatencyTestRun {
            analyticsClient.forceAlwaysSendAnalytics = true
        }
        // `name` looks like "-[MPELatencyTest testFoo]" - grab "testFoo"
        let testName = name.split(separator: " ").last!.dropLast()
        // 2a. This print statement is used by the `measure_latency_difference` script
        print("SYNTHETIC_LATENCY_RESULT: \(testName): \(duration)")
        // 2b. Log a special analytic instead of using mc_load b/c it's easier to add extra information and simpler to identify in hubble.
        analyticsClient.log(
            analytic: LatencyAnalytic(
                test: String(testName),
                duration: duration,
                requests: urlSessionMetricsCollector.collectedMetrics
            )
        )
    }

    var didCallLinkLookupEndpoint: Bool {
        return urlSessionMetricsCollector.collectedMetrics.contains { metric in
            if let path = metric.dict["path"] as? String {
                return path.contains("consumers/sessions/lookup") || path.contains("consumers/mobile/sessions/lookup")
            }
            return false
        }
    }
}
