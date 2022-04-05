//
//  ScanStatsPayloadAPIBindingsTests.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 12/9/21.
//

@testable import StripeCardScan
@testable @_spi(STP) import StripeCore
import XCTest

/// This test will check that the json and url encoding of the scan stats payload is structured as expected
class ScanStatsPayloadAPIBindingsTests: XCTestCase {
    var startDate: Date!
    var startDateMs: Int!
    var nonRepeatingTasks: NonRepeatingTasks!
    var repeatingTasks: RepeatingTasks!
    var scanStatsTasks: ScanStatsTasks!

    override func setUp() {
        let date = Date()
        self.startDate = date
        self.startDateMs = date.millisecondsSince1970

        self.nonRepeatingTasks = .init(
            cameraPermissionTask: .init(
                result: ScanAnalyticsEvent.cameraPermissionSuccess.rawValue,
                startedAtMs: startDateMs,
                durationMs: -1
            ),
            torchSupportedTask: .init(
                result: ScanAnalyticsEvent.torchSupported.rawValue,
                startedAtMs: startDateMs,
                durationMs: -1
            ),
            scanActivityTasks: [
                .init(
                    result: ScanAnalyticsEvent.firstImageProcessed.rawValue,
                    startedAtMs: startDateMs,
                    durationMs: -1
                ),
                .init(
                    result: ScanAnalyticsEvent.ocrPanObserved.rawValue,
                    startedAtMs: startDateMs,
                    durationMs: -1
                )
            ]
        )
        self.repeatingTasks = .init(
            mainLoopImagesProcessed: .init(executions: -1)
        )
        self.scanStatsTasks = .init(
            repeatingTasks: repeatingTasks,
            tasks: nonRepeatingTasks
        )
    }

    /// Check that scan stats tasks is encoded properly
    func testScanStatsTasks() throws {
        /// Check that scan stats tasks is encoded properly
        let jsonDictionary = try scanStatsTasks.encodeJSONDictionary()
        let tasksDictionary = jsonDictionary["tasks"] as! [String: Any]
        let repeatingTaskDictionary = jsonDictionary["repeating_tasks"] as! [String: Any]

        XCTAssertEqual(tasksDictionary.count, 3)
        XCTAssertEqual(repeatingTaskDictionary.count, 1)
    }

    /// Check that non repeating tasks are encoded properly
    func testNonRepeatingTasks() throws {
        /// Check that the JSON dictionary is formed properly
        let jsonDictionary = try nonRepeatingTasks.encodeJSONDictionary()
        let jsonCameraPermissions = jsonDictionary["camera_permission"] as! [[String: Any]]
        XCTAssertEqual(jsonCameraPermissions.count, 1)
        XCTAssertEqual(jsonCameraPermissions[0]["result"] as! String, "success")
        XCTAssertEqual(jsonCameraPermissions[0]["started_at_ms"] as? Int, startDateMs)
        XCTAssertEqual(jsonCameraPermissions[0]["duration_ms"] as? Int, -1)

        let jsonTorchSupported = jsonDictionary["torch_supported"] as! [[String: Any]]
        XCTAssertEqual(jsonTorchSupported.count, 1)
        XCTAssertEqual(jsonTorchSupported[0]["result"] as! String, "supported")
        XCTAssertEqual(jsonTorchSupported[0]["started_at_ms"] as? Int, startDateMs)
        XCTAssertEqual(jsonTorchSupported[0]["duration_ms"] as? Int, -1)

        let jsonScanActivities = jsonDictionary["scan_activity"] as! [[String: Any]]
        XCTAssertEqual(jsonScanActivities.count, 2)
        XCTAssertEqual(jsonScanActivities[0]["result"] as! String, "first_image_processed")
        XCTAssertEqual(jsonScanActivities[0]["started_at_ms"] as? Int, startDateMs)
        XCTAssertEqual(jsonScanActivities[0]["duration_ms"] as? Int, -1)
        XCTAssertEqual(jsonScanActivities[1]["result"] as! String, "ocr_pan_observed")
        XCTAssertEqual(jsonScanActivities[1]["started_at_ms"] as? Int, startDateMs)
        XCTAssertEqual(jsonScanActivities[1]["duration_ms"] as? Int, -1)
    }

    /// Check that repeating tasks are encoded properly
    func testRepeatingTasks() throws {
        /// Check that the JSON dictionary is formed properly
        let jsonDictionary = try repeatingTasks.encodeJSONDictionary()
        let jsonMainLoop = jsonDictionary["main_loop_images_processed"] as! [String: Any]
        XCTAssertEqual(jsonMainLoop["executions"] as? Int, -1)
    }

    /// Check that the url encoded query string is structured properly
    func testScanStatsPayloadQueryString() throws {
        let scanStatsPayload: ScanStatsPayload = .init(
            clientSecret: CIVIntentMockData.clientSecret,
            payload: .init(
                configuration: .init(strictModeFrames: 5),
                scanStats: scanStatsTasks
            )
        )
        let jsonDictionary = try scanStatsPayload.encodeJSONDictionary()
        /// Create query string
        let queryString = URLEncoder.queryString(from: jsonDictionary)

        /// Check client secret
        XCTAssertTrue(queryString.contains("client_secret=civ_client_secret_1234"), "client secret in query string is incorrect")
        /// Check that instance id exists (can't compare string since uuid is random)
        XCTAssertTrue(queryString.contains("payload[instance_id]="), "instance id in query string dne")
        /// Check payload version
        XCTAssertTrue(queryString.contains("payload[payload_version]=2"), "payload version in query string dne/is incorrect")
        /// Check that scan id exists (can't compare string since uuid is random)
        XCTAssertTrue(queryString.contains("payload[scan_id]="), "scan id in query string dne")
        /// Check that all the app info exists
        XCTAssertTrue(queryString.contains("payload[app][app_package_name]=xctest"), "app: app package name in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[app][is_debug_build]=true"), "app: is debug build in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[app][build]="), "app: build in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[app][sdk_version]=\(StripeAPIConfiguration.STPSDKVersion)"), "app: sdk version in query string is incorrect")
        /// Check that all the device info exists
        XCTAssertTrue(queryString.contains("payload[configuration][strict_mode_frames]=5"), "configuration: strict mode frames is incorrect")
        /// Check that all the device info exists
        XCTAssertTrue(queryString.contains("payload[device][device_type]=x86_64"), "device: device type in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[device][device_id]=Redacted"), "device: device id in query string dne")
        XCTAssertTrue(queryString.contains("payload[device][os_version]="), "device: os version in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[device][platform]=iOS"), "device: platform in query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[device][vendor_id]=Redacted"), "device: vendor id in query string dne")
        /// Check that repeating tasks: main loop images processed exists
        XCTAssertTrue(queryString.contains("payload[scan_stats][repeating_tasks][main_loop_images_processed][executions]=-1"),
                      "repeating tasks: main loop image in query string is incorrect")
        /// Check that all the camera permissions info exists
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][camera_permission][0][duration_ms]=-1"), "Camera permission duration query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][camera_permission][0][result]=success"), "Camera permission result query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][camera_permission][0][started_at_ms]=\(startDateMs!)"), "Camera permission start time query string is incorrect")
        /// Check that all the torch supported info exists
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][torch_supported][0][duration_ms]=-1"), "Torch supported duration query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][torch_supported][0][result]=supported"), "Torch supported result query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][torch_supported][0][started_at_ms]=\(startDateMs!)"), "Torch supported start time query string is incorrect")
        /// Check that all scan activities exists
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][0][duration_ms]=-1"), "Scan activity[0] duration query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][0][result]=first_image_processed"), "Scan activity[0]  result query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][0][started_at_ms]=\(startDateMs!)"), "Scan activity[0]  start time query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][1][duration_ms]=-1"), "Scan activity[1]  duration query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][1][result]=ocr_pan_observed"), "Scan activity[1]  result query string is incorrect")
        XCTAssertTrue(queryString.contains("payload[scan_stats][tasks][scan_activity][1][started_at_ms]=\(startDateMs!)"), "Scan activity[1]  start time query string is incorrect")
    }
}
