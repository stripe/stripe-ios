//
//  MockCameraPermissionsManager.swift
//  StripeCameraCoreTestUtils
//
//  Created by Mel Ludowise on 12/3/21.
//

import Foundation
import XCTest
@_spi(STP) import StripeCameraCore

@_spi(STP) public class MockCameraPermissionsManager: CameraPermissionsManagerProtocol {

    public var hasCameraAccess = false

    public private(set) var didRequestCameraAccess = false
    public let didCompleteExpectation = XCTestExpectation(description: "MockCameraPermissionsManager completion did finish")

    private var completion: CompletionBlock = { _ in }

    public init() { }

    public func requestCameraAccess(
        completeOnQueue queue: DispatchQueue,
        completion: @escaping CompletionBlock
    ) {
        self.completion = { granted in
            queue.async { [weak self] in
                completion(granted)
                self?.didCompleteExpectation.fulfill()
            }
        }
        didRequestCameraAccess = true
    }

    public func respondToRequest(granted: Bool?) {
        completion(granted)
    }
}
