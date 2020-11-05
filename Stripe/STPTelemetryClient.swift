//
//  STPTelemetryClient.swift
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

final class STPTelemetryClient: NSObject {
  @objc(sharedInstance) static var shared: STPTelemetryClient = STPTelemetryClient(sessionConfiguration: STPAPIClient.sharedUrlSessionConfiguration)

  func addTelemetryFields(toParams params: inout [String: Any]) {
    params["muid"] = muid
  }

  @objc func paramsByAddingTelemetryFields(toParams params: [String: Any]) -> [String: Any] {
    var mutableParams = params
    mutableParams["muid"] = muid
    return mutableParams
  }

  func sendTelemetryData() {
    guard STPTelemetryClient.shouldSendTelemetry() else {
      return
    }
    let path = "ios-sdk-1"
    let url = URL(string: "https://m.stripe.com")!.appendingPathComponent(path)
    let request = NSMutableURLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let payload = self.payload
    var data: Data?
    do {
      data = try JSONSerialization.data(
        withJSONObject: payload, options: JSONSerialization.WritingOptions(rawValue: 0))
    } catch {
      return
    }
    request.httpBody = data
    let task = urlSession.dataTask(with: request as URLRequest)
    task.resume()
  }

  private let urlSession: URLSession

  class func shouldSendTelemetry() -> Bool {
    #if targetEnvironment(simulator)
      return false
    #else
      return StripeAPI.advancedFraudSignalsEnabled && NSClassFromString("XCTest") == nil
    #endif
  }

  init(sessionConfiguration config: URLSessionConfiguration) {
    urlSession = URLSession(configuration: config)
    super.init()
  }

  private var muid : String {
    get {
      let muid = UIDevice.current.identifierForVendor?.uuidString
      return muid ?? ""
    }
  }

  private var language = Locale.autoupdatingCurrent.identifier

  lazy private var platform = [deviceModel, osVersion].joined(separator: " ")

  private var deviceModel : String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let model = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        ptr in String.init(validatingUTF8: ptr)
      }
    }
    return model ?? "Unknown"
  }()

  private var osVersion = UIDevice.current.systemVersion

  private var screenSize : String {
    let screen = UIScreen.main
    let screenRect = screen.bounds
    let width = screenRect.size.width
    let height = screenRect.size.height
    let scale = screen.scale
    return String(format: "%.0fw_%.0fh_%.0fr", width, height, scale)
  }

  private var timeZoneOffset : String {
    let timeZone = NSTimeZone.local as NSTimeZone
    let hoursFromGMT = Double(timeZone.secondsFromGMT) / (60 * 60)
    return String(format: "%.0f", hoursFromGMT)
  }

  private func encodeValue(_ value: String?) -> [AnyHashable: Any]? {
    if let value = value {
      return [
        "v": value
      ]
    }
    return nil
  }

  private var payload : [AnyHashable: Any] {
    var payload: [AnyHashable: Any] = [:]
    var data: [AnyHashable: Any] = [:]
    if let encode = encodeValue(language) {
      data["c"] = encode
    }
    if let encode = encodeValue(platform) {
      data["d"] = encode
    }
    if let encode = encodeValue(screenSize) {
      data["f"] = encode
    }
    if let encode = encodeValue(timeZoneOffset) {
      data["g"] = encode
    }
    payload["a"] = data
    var otherData: [AnyHashable: Any] = [:]
    otherData["d"] = muid
    otherData["k"] = Bundle.stp_applicationName() ?? ""
    otherData["l"] = Bundle.stp_applicationVersion() ?? ""
    otherData["m"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
    otherData["o"] = osVersion
    otherData["s"] = deviceModel
    payload["b"] = otherData
    payload["tag"] = STPAPIClient.STPSDKVersion
    payload["src"] = "ios-sdk"
    payload["v2"] = NSNumber(value: 1)
    return payload
  }
}
