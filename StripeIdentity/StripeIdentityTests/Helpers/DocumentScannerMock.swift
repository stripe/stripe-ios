//
//  DocumentScannerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//

import Foundation
import XCTest
import CoreVideo
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class DocumentScannerMock: DocumentScannerProtocol {
    let isScanningExp = XCTestExpectation(description: "scanImage called")
    private(set) var didReset = false

    private var completion: Completion?

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    ) {
        self.completion = completion
        isScanningExp.fulfill()
    }

    func respondToScan(output: IDDetectorOutput?) {
        completion?(output)
    }

    func reset() {
        didReset = true
    }
}
