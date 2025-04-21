//
//  STPNetworkStubbingTestCase.swift
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/24/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
@testable@_spi(STP) import StripeCore
import XCTest

/// Test cases that subclass `STPNetworkStubbingTestCase` will automatically capture all network traffic when run with `recordingMode = YES` and save it to disk. When run with `recordingMode = NO`, they will use the persisted request/response pairs, and raise an exception if an unexpected HTTP request is made.
/// ⚠️ Warning: `STPAPIClient`s created before `setUp` is called are not recorded!
/// To write manual requests, try APIStubbedTestCase instead.
@objc(STPNetworkStubbingTestCase) open class STPNetworkStubbingTestCase: XCTestCase {
    /// Set this to YES to record all traffic during this test. The test will then fail, to remind you to set this back to NO before pushing.
    open var recordingMode = false

    /// Set this to YES to disable network mocking entirely (e.g. in a nightly test)
    open var disableMocking = false

    /// If `true` (the default), URL parameters will be recorded in requests.
    /// Disable this if your test case sends paramters that may change (e.g. the time), as otherwise the requests may not match during playback.
    open var strictParamsEnforcement = true

    /// If `true` (the default), the recorder will always follow redirects.
    /// Otherwise, the recorder will record the body of the HTTP redirect request.
    /// Disable this when testing the STPPaymentHandler "UnredirectableSessionDelegate" behavior.
    open var followRedirects = true

    open override func setUp() {
        super.setUp()

        recordingMode = ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] != nil
        disableMocking = ProcessInfo.processInfo.environment["STP_NO_NETWORK_MOCKS"] != nil

        if disableMocking {
            // Don't set this up
            return
        }

        // Set some default FraudDetectionData
        FraudDetectionData.shared.sid = "00000000-0000-0000-0000-000000000000"
        FraudDetectionData.shared.muid = "00000000-0000-0000-0000-000000000000"
        FraudDetectionData.shared.guid = "00000000-0000-0000-0000-000000000000"
        FraudDetectionData.shared.sidCreationDate = Date()

        // Set the STPTestingAPIClient to use the sharedURLSessionConfig so that we can intercept requests from it too
        STPTestingAPIClient.shared.sessionConfig =
            StripeAPIConfiguration.sharedUrlSessionConfiguration

        // Enable the Debug Params headers. We'll record these and include them in the header list.
        StripeAPIConfiguration.includeDebugParamsHeader = true

        // [self name] returns a string like `-[STPMyTestCase testThing]` - this transforms it into the recorded path `recorded_network_traffic/STPMyTestCase/testThing`.
        let rawComponents = name.components(separatedBy: " ")
        assert(rawComponents.count == 2, "Invalid format received from XCTest#name: \(name)")
        var components: [AnyHashable] = []
        (rawComponents as NSArray).enumerateObjects({ component, _, _ in
            components.append(
                (component as! NSString).components(
                    separatedBy: CharacterSet.alphanumerics.inverted
                )
                .joined()
            )
        })

        let testClass = components[0] as! NSString
        let testMethod = components[1] as! String
        let relativePath = ("recorded_network_traffic" as NSString).appendingPathComponent(
            testClass.appendingPathComponent(testMethod)
        )

        if recordingMode {
            #if targetEnvironment(simulator)
            #else
                // Must be in the simulator, so that we can write recorded traffic into the repo.
                assert(false, "Tests executed in recording mode must be run in the simulator.")
            #endif
            let config = StripeAPIConfiguration.sharedUrlSessionConfiguration
            let recorder = SWHttpTrafficRecorder.shared()

            // Creates filenames like `post_v1_tokens_0.tail`.
            var count = 0
            if strictParamsEnforcement {
                // Just record the full URL, don't try to strip out params
                recorder?.urlRegexPatternBlock = { request, _ in
                    // Need to escape this to fit in a regex (e.g. \? instead of ? before the query)
                    return NSRegularExpression.escapedPattern(for: request?.url?.absoluteString ?? "")
                }
                recorder?.postBodyTransformBlock = { _, postBody in
                    // Regex filter these:
                    let escapedBody = NSRegularExpression.escapedPattern(for: postBody ?? "")
                    // Then remove any params that may contain UUIDs or other random data
                    return replaceNondeterministicParams(escapedBody)
                }
            } else {
                recorder?.urlRegexPatternBlock = nil
                recorder?.postBodyTransformBlock = { _, _ in
                    return ""
                }
            }
            recorder?.followRedirects = followRedirects
            recorder?.fileNamingBlock = { request, _, _ in
                let method = request!.httpMethod?.lowercased()
                let urlPath = request!.url?.path.replacingOccurrences(of: "/", with: "_")
                var fileName = "\(String(format: "%04d", count))_\(method ?? "")\(urlPath ?? "")"
                fileName =
                    URL(fileURLWithPath: fileName).appendingPathExtension("tail").lastPathComponent
                count += 1
                return fileName
            }

            // The goal is for `basePath` to be e.g. `~/stripe-ios/Stripe/StripeiOSTests`
            // A little gross/hardcoded (but it works fine); feel free to improve this...
            let testDirectoryName = "stripe-ios/StripePayments/StripePaymentsTestUtils"
            var basePath = "\(#file)"
            while !basePath.hasSuffix(testDirectoryName) {
                assert(
                    basePath.contains(testDirectoryName),
                    "Not in a subdirectory of \(testDirectoryName): \(#file)"
                )
                basePath = URL(fileURLWithPath: basePath).deletingLastPathComponent().path
            }

            let recordingPath = URL(fileURLWithPath: basePath)
                .appendingPathComponent("Resources")
                .appendingPathComponent(relativePath)
                .path
            // Delete existing stubs
            do {
                try FileManager.default.removeItem(atPath: recordingPath)
            } catch {
            }
            guard
                (try? SWHttpTrafficRecorder.shared().startRecording(
                    atPath: recordingPath,
                    for: config
                )) != nil
            else {
                assert(false, "Error recording requests")
                return
            }

            // Make sure to fail, to remind ourselves to turn this off
            addTeardownBlock {
                XCTFail(
                    "Network traffic has been recorded - re-run with self.recordingMode = NO for this test to succeed"
                )
            }
        } else {
            // Stubs are evaluated in the reverse order that they are added, so if the network is hit and no other stub is matched, raise an exception
            HTTPStubs.stubRequests(
                passingTest: { _ in
                    return true
                },
                withStubResponse: { request in
                    XCTFail("Attempted to hit the live network at \(request.url?.path ?? "")")
                    return HTTPStubsResponse()
                }
            )

            // Note: in order to make this work, the stub files (end in .tail) must be added to the test bundle during Build Phases/Copy Resources Step.
            let bundle = Bundle(for: STPNetworkStubbingTestCase.self)
            let url = bundle.url(forResource: relativePath, withExtension: nil)
            if url != nil {
                var stubError: NSError?
                HTTPStubs.stubRequestsUsingMocktails(
                    atPath: relativePath,
                    in: bundle,
                    error: &stubError,
                    removeAfterUse: true
                )
                if let stubError = stubError {
                    XCTFail("Error stubbing requests: \(stubError)")
                }
            } else {
                print("No stubs found - all network access will raise an exception.")
            }
        }
    }

    open override func tearDown() {
        super.tearDown()

        if disableMocking {
            // No teardown needed
            return
        }

        // Additional calls to `setFileNamingBlock` will be ignored if you don't do this
        SWHttpTrafficRecorder.shared().stopRecording()

        // Don't accidentally keep any stubs around during the next test run
        HTTPStubs.removeAllStubs()
    }
}

// Function to filter out some common UUIDs or other request parameters that may change
private func replaceNondeterministicParams(_ input: String) -> String {
    let componentsToFilter = [
        "guid=", // Fraud detection data
        "muid=",
        "sid=",
        "[guid]=",
        "[muid]=",
        "[sid]=",
        "app_version_key", // Current version of Xcode, for Alipay

        "payment_user_agent", // Contains the SDK version number
        "pk_token_transaction_id", // Random string
    ]
    var components = input.components(separatedBy: "&")

    for (index, component) in components.enumerated() {
        if componentsToFilter.first(where: { component.contains($0) }) != nil {
            let parts = component.components(separatedBy: "=")
            XCTAssertEqual(parts.count, 2, "Invalid portion of query string: index\(index), component: \(component)")
            components[index] = "\(parts[0])=.*"
        }
    }

    return components.joined(separator: "&")
}
