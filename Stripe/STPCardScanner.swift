//
//  STPCardScanner.swift
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import Vision

enum STPCardScannerError: Int {
  /// Camera not available.
  case cameraNotAvailable
}

@available(iOS 13, *)
@objc protocol STPCardScannerDelegate: NSObjectProtocol {
  @objc(cardScanner:didFinishWithCardParams:error:) func cardScanner(
    _ scanner: STPCardScanner, didFinishWith cardParams: STPPaymentMethodCardParams?, error: Error?)
}

@available(iOS 13, *)
class STPCardScanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  // iOS will kill the app if it tries to request the camera without an NSCameraUsageDescription
  static let cardScanningAvailableCameraHasUsageDescription = {
    return (Bundle.main.infoDictionary?["NSCameraUsageDescription"] != nil)
  }()

  class func cardScanningAvailable() -> Bool {
    // Always allow in tests:
    if NSClassFromString("XCTest") != nil {
      return true
    }
    return cardScanningAvailableCameraHasUsageDescription
  }

  weak var cameraView: STPCameraView?

  @objc public var deviceOrientation: UIDeviceOrientation {
    get {
      return stp_deviceOrientation
    }
    set(newDeviceOrientation) {
      stp_deviceOrientation = newDeviceOrientation

      // This is an optimization for portrait mode: The card will be centered in the screen,
      // so we can ignore the top and bottom. We'll use the whole frame in landscape.
      let kSTPCardScanningScreenCenter = CGRect(
        x: 0, y: CGFloat(0.3), width: 1, height: CGFloat(0.4))

      // iOS camera image data is returned in LandcapeLeft orientation by default. We'll flip it as needed:
      switch newDeviceOrientation {
      case .portraitUpsideDown:
        videoOrientation = .portraitUpsideDown
        textOrientation = .left
        regionOfInterest = kSTPCardScanningScreenCenter
      case .landscapeLeft:
        videoOrientation = .landscapeRight
        textOrientation = .up
        regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
      case .landscapeRight:
        videoOrientation = .landscapeLeft
        textOrientation = .down
        regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
      case .portrait, .faceUp, .faceDown, .unknown:
        fallthrough
      default:
        videoOrientation = .portrait
        textOrientation = .right
        regionOfInterest = kSTPCardScanningScreenCenter
      }
      cameraView?.videoPreviewLayer.connection?.videoOrientation = videoOrientation
    }
  }

  override init() {
  }

  init(delegate: STPCardScannerDelegate?) {
    super.init()
    self.delegate = delegate
    captureSessionQueue = DispatchQueue(label: "com.stripe.CardScanning.CaptureSessionQueue")
    deviceOrientation = UIDevice.current.orientation
  }

  func start() {
    if isScanning {
      return
    }
    STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPCardScanner.self)
    startTime = Date()

    isScanning = true
    didTimeout = false
    timeoutStarted = false

    captureSessionQueue?.async(execute: {
      self.detectedNumbers = NSCountedSet()  // capacity: 5
      self.detectedExpirations = NSCountedSet()  // capacity: 5
      self.setupCamera()
      DispatchQueue.main.async(execute: {
        self.cameraView?.captureSession = self.captureSession
        self.cameraView?.videoPreviewLayer.connection?.videoOrientation = self.videoOrientation
      })
    })
  }

  func stop() {
    stopWithError(nil)
  }

  private weak var delegate: STPCardScannerDelegate?
  private var captureDevice: AVCaptureDevice?
  private var captureSession: AVCaptureSession?
  private var captureSessionQueue: DispatchQueue?
  private var videoDataOutput: AVCaptureVideoDataOutput?
  private var videoDataOutputQueue: DispatchQueue?
  private var textRequest: VNRecognizeTextRequest?
  private var isScanning = false
  private var didTimeout = false
  private var timeoutStarted = false
  private var stp_deviceOrientation: UIDeviceOrientation!
  private var videoOrientation: AVCaptureVideoOrientation!
  private var textOrientation: CGImagePropertyOrientation!
  private var regionOfInterest = CGRect.zero
  private var detectedNumbers: NSCountedSet?
  private var detectedExpirations: NSCountedSet?
  private var startTime: Date?

  // MARK: Public

  class func stp_cardScanningError() -> Error {
    let userInfo = [
      NSLocalizedDescriptionKey: STPLocalizedString(
        "To scan your card, you'll need to allow access to your camera in Settings.",
        "Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."
      ),
      STPError.errorMessageKey: "The camera couldn't be used.",
    ]
    return NSError(
      domain: STPCardScannerErrorDomain, code: STPCardScannerError.cameraNotAvailable.rawValue,
      userInfo: userInfo)
  }

  deinit {
    if isScanning {
      captureDevice?.unlockForConfiguration()
      captureSession?.stopRunning()
    }
  }

  func stopWithError(_ error: Error?) {
    if isScanning {
      finish(with: nil, error: error)
    }
  }

  // MARK: Setup
  func setupCamera() {
    weak var weakSelf = self
    textRequest = VNRecognizeTextRequest(completionHandler: { request, error in
      let strongSelf = weakSelf
      if !(strongSelf?.isScanning ?? false) {
        return
      }
      if error != nil {
        strongSelf?.stopWithError(STPCardScanner.stp_cardScanningError())
        return
      }
      strongSelf?.processVNRequest(request)
    })

    let captureDevice = AVCaptureDevice.default(
      .builtInWideAngleCamera, for: .video, position: .back)
    self.captureDevice = captureDevice

    captureSession = AVCaptureSession()
    captureSession?.sessionPreset = .hd1920x1080

    var deviceInput: AVCaptureDeviceInput?
    do {
      if let captureDevice = captureDevice {
        deviceInput = try AVCaptureDeviceInput(device: captureDevice)
      }
    } catch {
      stopWithError(STPCardScanner.stp_cardScanningError())
      return
    }

    if let deviceInput = deviceInput {
      if captureSession?.canAddInput(deviceInput) ?? false {
        captureSession?.addInput(deviceInput)
      } else {
        stopWithError(STPCardScanner.stp_cardScanningError())
        return
      }
    }

    videoDataOutputQueue = DispatchQueue(label: "com.stripe.CardScanning.VideoDataOutputQueue")
    videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput?.alwaysDiscardsLateVideoFrames = true
    videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

    // This is the recommended pixel buffer format for Vision:
    videoDataOutput?.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ]

    if let videoDataOutput = videoDataOutput {
      if captureSession?.canAddOutput(videoDataOutput) ?? false {
        captureSession?.addOutput(videoDataOutput)
      } else {
        stopWithError(STPCardScanner.stp_cardScanningError())
        return
      }
    }

    // This improves recognition quality, but means the VideoDataOutput buffers won't match what we're seeing on screen.
    videoDataOutput?.connection(with: .video)?.preferredVideoStabilizationMode = .auto

    captureSession?.startRunning()

    do {
      try self.captureDevice?.lockForConfiguration()
      self.captureDevice?.autoFocusRangeRestriction = .near
    } catch {
    }
  }

  // MARK: Processing
  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    if !isScanning {
      return
    }
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    if pixelBuffer == nil {
      return
    }
    textRequest?.recognitionLevel = .accurate
    textRequest?.usesLanguageCorrection = false
    textRequest?.regionOfInterest = regionOfInterest
    var handler: VNImageRequestHandler?
    if let pixelBuffer = pixelBuffer {
      handler = VNImageRequestHandler(
        cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
    }
    do {
      try handler?.perform([textRequest].compactMap { $0 })
    } catch {
    }
  }

  func processVNRequest(_ request: VNRequest) {
    var allNumbers: [String] = []
    for observation in request.results ?? [] {
      guard let observation = observation as? VNRecognizedTextObservation else {
        continue
      }
      let candidates = observation.topCandidates(5)
      let topCandidate = candidates.first?.string
      if STPCardValidator.sanitizedNumericString(for: topCandidate ?? "").count >= 4 {
        allNumbers.append(topCandidate ?? "")
      }
      for recognizedText in candidates {
        let possibleNumber = STPCardValidator.sanitizedNumericString(for: recognizedText.string)
        if possibleNumber.count < 4 {
          continue  // This probably isn't something we're interested in, so don't bother processing it.
        }

        // First strategy: We check if Vision sent us a number in a group on its own. If that fails, we'll try
        // to catch it later when we iterate over all the numbers.
        if STPCardValidator.validationState(forNumber: possibleNumber, validatingCardBrand: true)
          == .valid
        {
          addDetectedNumber(possibleNumber)
        } else if possibleNumber.count >= 4 && possibleNumber.count <= 6
          && STPStringUtils.stringMayContainExpirationDate(recognizedText.string)
        {
          // Try to parse anything that looks like an expiration date.
          let expirationString = STPStringUtils.expirationDateString(from: recognizedText.string)
          let sanitizedExpiration = STPCardValidator.sanitizedNumericString(
            for: expirationString ?? "")
          let month = (sanitizedExpiration as NSString).substring(to: 2)
          let year = (sanitizedExpiration as NSString).substring(from: 2)

          // Ignore expiration dates 10+ years in the future, as they're likely to be incorrect recognitions
          let calendar = Calendar(identifier: .gregorian)
          let presentYear = calendar.component(.year, from: Date())
          let maxYear = (presentYear % 100) + 10

          if STPCardValidator.validationState(forExpirationYear: year, inMonth: month) == .valid
            && Int(year) ?? 0 < maxYear
          {
            addDetectedExpiration(sanitizedExpiration)
          }
        }
      }
    }
    // Second strategy: We look for consecutive groups of 4/4/4/4 or 4/6/5
    // Vision is sending us groups like ["1234 565", "1234 1"], so we'll normalize these into groups with spaces:
    let allGroups = allNumbers.joined(separator: " ").components(separatedBy: " ")
    if allGroups.count < 3 {
      return
    }
    for i in 0..<(allGroups.count - 3) {
      let string1 = allGroups[i]
      let string2 = allGroups[i + 1]
      let string3 = allGroups[i + 2]
      var string4 = ""
      if i + 3 < allGroups.count {
        string4 = allGroups[i + 3]
      }
      // Then we'll go through each group and build a potential match:
      let potentialCardString = "\(string1)\(string2)\(string3)\(string4)"
      let potentialAmexString = "\(string1)\(string2)\(string3)"

      // Then we'll add valid matches. It's okay if we add a number a second time after doing so above, as the success of that first pass means it's more likely to be a good match.
      if STPCardValidator.validationState(forNumber: potentialCardString, validatingCardBrand: true)
        == .valid
      {
        addDetectedNumber(potentialCardString)
      } else if STPCardValidator.validationState(
        forNumber: potentialAmexString, validatingCardBrand: true) == .valid
      {
        addDetectedNumber(potentialAmexString)
      }
    }
  }

  func addDetectedNumber(_ number: String) {
    detectedNumbers?.add(number)

    // Set a timeout: If we don't get enough scans in the next 1 second, we'll use the best option we have.
    if !timeoutStarted {
      timeoutStarted = true
      weak var weakSelf = self
      DispatchQueue.main.async(execute: {
        let strongSelf = weakSelf
        strongSelf?.cameraView?.playSnapshotAnimation()
      })
      videoDataOutputQueue?.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(kSTPCardScanningTimeout * Double(NSEC_PER_SEC)))
          / Double(NSEC_PER_SEC),
        execute: {
          let strongSelf = weakSelf
          if strongSelf?.isScanning ?? false {
            strongSelf?.didTimeout = true
            strongSelf?.finishIfReady()
          }
        })
    }

    if (detectedNumbers?.count(for: number) ?? 0) >= kSTPCardScanningMinimumValidScans {
      finishIfReady()
    }
  }

  func addDetectedExpiration(_ expiration: String) {
    detectedExpirations?.add(expiration)
    if (detectedExpirations?.count(for: expiration) ?? 0) >= kSTPCardScanningMinimumValidScans {
      finishIfReady()
    }
  }

  // MARK: Completion
  func finishIfReady() {
    if !isScanning {
      return
    }
    let detectedNumbers = self.detectedNumbers
    let detectedExpirations = self.detectedExpirations

    let topNumber = (detectedNumbers?.allObjects as NSArray?)?.sortedArray(comparator: {
      obj1, obj2 in
      let c1 = detectedNumbers?.count(for: obj1) ?? 0
      let c2 = detectedNumbers?.count(for: obj2) ?? 0
      if c1 < c2 {
        return .orderedAscending
      } else if c1 > c2 {
        return .orderedDescending
      } else {
        return .orderedSame
      }
    }).last
    let topExpiration = (detectedExpirations?.allObjects as NSArray?)?.sortedArray(comparator: {
      obj1, obj2 in
      let c1 = detectedExpirations?.count(for: obj1) ?? 0
      let c2 = detectedExpirations?.count(for: obj2) ?? 0
      if c1 < c2 {
        return .orderedAscending
      } else if c1 > c2 {
        return .orderedDescending
      } else {
        return .orderedSame
      }
    }).last

    if didTimeout
      || (((detectedNumbers?.count(for: topNumber ?? 0) ?? 0) >= kSTPCardScanningMinimumValidScans)
        && ((detectedExpirations?.count(for: topExpiration ?? 0) ?? 0)
          >= kSTPCardScanningMinimumValidScans))
      || ((detectedNumbers?.count(for: topNumber ?? 0) ?? 0) >= kSTPCardScanningMaxValidScans)
    {
      let params = STPPaymentMethodCardParams()
      params.number = topNumber as? String
      if let topExpiration = topExpiration {
        params.expMonth = NSNumber(value: Int((topExpiration as! NSString).substring(to: 2)) ?? 0)
        params.expYear = NSNumber(value: Int((topExpiration as! NSString).substring(from: 2)) ?? 0)
      }
      finish(with: params, error: nil)
    }
  }

  func finish(with params: STPPaymentMethodCardParams?, error: Error?) {
    var duration: TimeInterval?
    if let startTime = startTime {
      duration = Date().timeIntervalSince(startTime)
    }
    isScanning = false
    captureDevice?.unlockForConfiguration()
    captureSession?.stopRunning()

    DispatchQueue.main.async(execute: {
      if params == nil {
        STPAnalyticsClient.sharedClient.logCardScanCancelled(withDuration: duration ?? 0.0)
      } else {
        STPAnalyticsClient.sharedClient.logCardScanSucceeded(withDuration: duration ?? 0.0)
      }

      self.cameraView?.captureSession = nil
      self.delegate?.cardScanner(self, didFinishWith: params, error: error)
    })
  }

  // MARK: Orientation
}

// The number of successful scans required for both card number and expiration date before returning a result.
private let kSTPCardScanningMinimumValidScans = 2
// If no expiration date is found, we'll return a result after this many successful scans.
private let kSTPCardScanningMaxValidScans = 3
// Once one successful scan is found, we'll stop scanning after this many seconds.
private let kSTPCardScanningTimeout: TimeInterval = 1.0
let STPCardScannerErrorDomain = "STPCardScannerErrorDomain"
