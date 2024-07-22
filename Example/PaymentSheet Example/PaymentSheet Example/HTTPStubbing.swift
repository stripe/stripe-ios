//
//  HTTPStubbing.swift
//  PaymentSheet Example
//
//  Created by David Estes on 7/19/24.
//

import Foundation
import OHHTTPStubs
@_spi(STP) import StripeCore

/// Test cases that subclass `STPNetworkStubbingTestCase` will automatically capture all network traffic when run with `recordingMode = YES` and save it to disk. When run with `recordingMode = NO`, they will use the persisted request/response pairs, and raise an exception if an unexpected HTTP request is made.
/// ⚠️ Warning: `STPAPIClient`s created before `setUp` is called are not recorded!
/// To write manual requests, try APIStubbedTestCase instead.
open class PaymentSheetNetworkRecorder: NSObject {
    /// Set this to YES to record all traffic during this test. The test will then fail, to remind you to set this back to NO before pushing.
    open var recordingMode = false

    /// If `true` (the default), URL parameters will be recorded in requests.
    /// Disable this if your test case sends paramters that may change (e.g. the time), as otherwise the requests may not match during playback.
    open var strictParamsEnforcement = true

    /// If `true` (the default), the recorder will always follow redirects.
    /// Otherwise, the recorder will record the body of the HTTP redirect request.
    /// Disable this when testing the STPPaymentHandler "UnredirectableSessionDelegate" behavior.
    open var followRedirects = true

    static let shared = PaymentSheetNetworkRecorder()
    open func beginMockingForTest(recordingMode: Bool, name: String) {

//        recordingMode = ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] != nil
        self.recordingMode = recordingMode
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
            } else {
                recorder?.urlRegexPatternBlock = nil
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
            let testDirectoryName = "stripe-ios/Example/PaymentSheet Example/PaymentSheet Example"
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
//            addTeardownBlock {
//                XCTFail(
//                    "Network traffic has been recorded - re-run with self.recordingMode = NO for this test to succeed"
//                )
//            }
        } else {
            // Stubs are evaluated in the reverse order that they are added, so if the network is hit and no other stub is matched, raise an exception
            HTTPStubs.stubRequests(
                passingTest: { _ in
                    return true
                },
                withStubResponse: { request in
                    assertionFailure("Attempted to hit the live network at \(request.url?.path ?? "")")
                    return HTTPStubsResponse()
                }
            )

            // Note: in order to make this work, the stub files (end in .tail) must be added to the test bundle during Build Phases/Copy Resources Step.
            let bundle = Bundle(for: PaymentSheetNetworkRecorder.self)
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
                    assertionFailure("Error stubbing requests: \(stubError)")
                }
            } else {
                print("No stubs found - all network access will raise an exception.")
            }
        }
    }

    open func stopMocking() {
        // Additional calls to `setFileNamingBlock` will be ignored if you don't do this
        SWHttpTrafficRecorder.shared().stopRecording()

        // Don't accidentally keep any stubs around during the next test run
        HTTPStubs.removeAllStubs()
    }
}
