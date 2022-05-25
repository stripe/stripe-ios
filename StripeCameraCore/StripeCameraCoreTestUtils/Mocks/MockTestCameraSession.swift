//
//  MockTestCameraSession.swift
//  StripeCameraCoreTestUtils
//
//  Created by Mel Ludowise on 1/21/22.
//

import Foundation
import AVKit
@_spi(STP) @testable import StripeCameraCore
import XCTest

@_spi(STP) public final class MockTestCameraSession: CameraSessionProtocol {

    /// Mock image to display in previewView. Should be used for snapshot tests
    public var mockImage: UIImage? {
        didSet {
            setPreviewViewToMockImage()
        }
    }

    public var previewView: CameraPreviewView? {
        didSet {
            setPreviewViewToMockImage()
        }
    }

    public var mockDeviceProperties = CameraSession.DeviceProperties(
        exposureDuration: CMTime(),
        cameraDeviceType: .builtInDualCamera,
        isVirtualDevice: nil,
        lensPosition: 0,
        exposureISO: 0,
        isAdjustingFocus: false
    )

    public init() {
        // no-op
    }

    // MARK: configureSession

    private var configureCompletion: ((CameraSession.SetupResult) -> Void)?
    public private(set) var configureSessionCompletionExp = XCTestExpectation(description: "configureSession completion block called")

    public private(set) var sessionPreset: AVCaptureSession.Preset?
    public private(set) var outputSettings: [String: Any]?

    public func configureSession(
        configuration: CameraSession.Configuration,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        cameraPosition = configuration.initialCameraPosition
        videoOrientation = configuration.initialOrientation
        sessionPreset = configuration.sessionPreset
        outputSettings = configuration.outputSettings
        configureCompletion = { setupResult in
            queue.async { [weak self] in
                self?.configureSessionCompletionExp.fulfill()
                completion(setupResult)
            }
        }
    }

    public func respondToConfigureSession(setupResult: CameraSession.SetupResult) {
        configureCompletion?(setupResult)
    }

    // MARK: setVideoOrientation

    public private(set) var videoOrientation: AVCaptureVideoOrientation?

    public func setVideoOrientation(orientation: AVCaptureVideoOrientation) {
        self.videoOrientation = orientation
    }

    // MARK: toggleCamera

    private var toggleCameraCompletion: ((CameraSession.SetupResult) -> Void)?
    public private(set) var cameraPosition: CameraSession.CameraPosition?

    public func toggleCamera(
        to position: CameraSession.CameraPosition,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        toggleCameraCompletion = { setupResult in
            queue.async {
                completion(setupResult)
            }
        }
        cameraPosition = position
    }

    public func respondToToggleCamera(setupResult: CameraSession.SetupResult) {
        toggleCameraCompletion?(setupResult)
    }

    // MARK: toggleTorch

    public private(set) var didToggleTorch = false

    public func toggleTorch() {
        didToggleTorch = true
    }

    // MARK: getCameraProperties

    public func getCameraProperties() -> CameraSession.DeviceProperties? {
        return mockDeviceProperties
    }


    // MARK: startSession

    private var startSessionCompletion: (() -> Void)?
    public private(set) var startSessionCompletionExp = XCTestExpectation(description: "startSession completion block called")

    public func startSession(
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        startSessionCompletion = {
            queue.async { [weak self] in
                self?.startSessionCompletionExp.fulfill()
                completion()
            }
        }
    }

    public func respondToStartSession() {
        startSessionCompletion?()
    }

    // MARK: stopSession

    public private(set) var didStopSession = false

    public func stopSession() {
        didStopSession = true
    }

    // MARK: previewView

    func setPreviewViewToMockImage() {
        let block = { [weak self] in
            guard let self = self else { return }
            self.previewView?.layer.contents = self.mockImage?.cgImage
            self.previewView?.layer.contentsGravity = .resizeAspectFill
        }

        // Only dispatch to main async if necessary so this can run
        // synchronously for snapshot tests.
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
