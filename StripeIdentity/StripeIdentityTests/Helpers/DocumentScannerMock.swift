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

    private var completion: Completion?

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DesiredDocumentClassification,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    ) {
        self.completion = completion
        isScanningExp.fulfill()
    }

    func respondToScan(output: IDDetectorOutput) {
        completion?(output)
    }
}
