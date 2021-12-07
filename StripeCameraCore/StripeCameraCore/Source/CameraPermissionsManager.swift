//
//  CameraPermissionsManager.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/3/21.
//

import Foundation
import AVKit

@_spi(STP) public protocol CameraPermissionsManagerProtocol {
    /**
     Completion block called when done requesting permissions.

     - Parameter granted: If camera permissions are granted for the app.
       Value is `nil` if the authorization status cannot be determined.
     */
    typealias CompletionBlock = (_ granted: Bool?) -> Void

    var hasCameraAccess: Bool { get }
    func requestCameraAccess(
        completeOnQueue queue: DispatchQueue,
        completion: @escaping CompletionBlock
    )
}

/// Dependency-injectable class to assist with accessing and requesting camera authorization
@_spi(STP) public final class CameraPermissionsManager: CameraPermissionsManagerProtocol {

    public static let shared = CameraPermissionsManager()

    /// If this app currently has authorization to access the device's camera
    public var hasCameraAccess: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private init() {
        // Use shared instance instead of init
    }

    /**
     Requests camera permissions and calls completion block with result after retrieving them.

     - Parameters:
       - completion:
       - queue: DispatchQueue to complete the

     - Note:
     If the user has already granted or denied camera permissions to the app,
     this callback will respond immediately after `requestCameraAccess` is
     called on the video feed and `showedPrompt` will be false.

     If the user has not yet granted or denied camera permissions to the app,
     they will be prompted to do so. This callback will respond after the user
     selects a response and `showedPrompt` will be true.

     */
    public func requestCameraAccess(
        completeOnQueue queue: DispatchQueue = .main,
        completion: @escaping CompletionBlock
    ) {
        let wrappedCompletion: CompletionBlock = { granted in
            queue.async {
                completion(granted)
            }
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            wrappedCompletion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                wrappedCompletion(granted)
            })

        case .restricted,
             .denied:
            wrappedCompletion(false)

        default:
            wrappedCompletion(nil)
        }
    }
}
