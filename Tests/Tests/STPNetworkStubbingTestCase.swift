//
//  STPNetworkStubbingTestCase.swift
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/24/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import SWHttpTrafficRecorder

@testable import Stripe

/// Test cases that subclass `STPNetworkStubbingTestCase` will automatically capture all network traffic when run with `recordingMode = YES` and save it to disk. When run with `recordingMode = NO`, they will use the persisted request/response pairs, and raise an exception if an unexpected HTTP request is made.
class STPNetworkStubbingTestCase: XCTestCase {
  /// Set this to YES to record all traffic during this test. The test will then fail, to remind you to set this back to NO before pushing.
  var recordingMode = false

  override func setUp() {
    super.setUp()

    // [self name] returns a string like `-[STPMyTestCase testThing]` - this transforms it into the recorded path `recorded_network_traffic/STPMyTestCase/testThing`.
    let rawComponents = name.components(separatedBy: " ")
    assert(rawComponents.count == 2, "Invalid format received from XCTest#name: \(name)")
    var components: [AnyHashable] = []
    (rawComponents as NSArray).enumerateObjects({ component, _, _ in
      components.append(
        (component as! NSString).components(separatedBy: CharacterSet.alphanumerics.inverted)
          .joined())
    })

    let testClass = components[0] as! NSString
    let testMethod = components[1] as! String
    let relativePath = ("recorded_network_traffic" as NSString).appendingPathComponent(
      testClass.appendingPathComponent(testMethod))

    if recordingMode {
      #if targetEnvironment(simulator)
      #else
        // Must be in the simulator, so that we can write recorded traffic into the repo.
        assert(false, "Tests executed in recording mode must be run in the simulator.")
      #endif
      let config = STPAPIClient.sharedUrlSessionConfiguration
      let recorder = SWHttpTrafficRecorder.shared()

      // Creates filenames like `post_v1_tokens_0.tail`.
      var count = 0
      recorder?.fileNamingBlock = { request, response, defaultName in
        let method = request!.httpMethod?.lowercased()
        let urlPath = request!.url?.path.replacingOccurrences(of: "/", with: "_")
        var fileName = "\(method ?? "")\(urlPath ?? "")_\(count)"
        fileName = URL(fileURLWithPath: fileName).appendingPathExtension("tail").path
        count += 1
        return fileName
      }

      // The goal is for `basePath` to be e.g. `~/stripe/stripe-ios/Tests`
      // A little gross/hardcoded (but it works fine); feel free to improve this...
      let testDirectoryName = "stripe-ios/Tests"
      var basePath = "\(#file)"
      while !basePath.hasSuffix(testDirectoryName) {
        assert(
          basePath.contains(testDirectoryName),
          "Not in a subdirectory of \(testDirectoryName): \(#file)")
        basePath = URL(fileURLWithPath: basePath).deletingLastPathComponent().path
      }

      let recordingPath = URL(fileURLWithPath: basePath).appendingPathComponent(relativePath).path
      // Delete existing stubs
      do {
        try FileManager.default.removeItem(atPath: recordingPath)
      } catch {
      }
      guard
        let _ = try? SWHttpTrafficRecorder.shared().startRecording(
          atPath: recordingPath, for: config)
      else {
        assert(false, "Error recording requests")
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
        passingTest: { request in
          return true
        },
        withStubResponse: { request in
          XCTFail("Attempted to hit the live network at \(request.url?.path ?? "")")
          return HTTPStubsResponse()
        })

      // Note: in order to make this work, the stub files (end in .tail) must be added to the test bundle during Build Phases/Copy Resources Step.
      let bundle = Bundle(for: STPNetworkStubbingTestCase.self)
      let url = bundle.url(forResource: relativePath, withExtension: nil)
      if url != nil {
        var stubError: NSError?
        HTTPStubs.stubRequestsUsingMocktails(atPath: relativePath, in: bundle, error: &stubError)
        if let stubError = stubError {
          XCTFail("Error stubbing requests: \(stubError)")
        }
      } else {
        print("No stubs found - all network access will raise an exception.")
      }
    }
  }

  override func tearDown() {
    super.tearDown()
    // Additional calls to `setFileNamingBlock` will be ignored if you don't do this
    SWHttpTrafficRecorder.shared().stopRecording()

    // Don't accidentally keep any stubs around during the next test run
    HTTPStubs.removeAllStubs()
  }
}
