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
    private(set) var didCancel = false

    private var completion: ((CVPixelBuffer) -> Void)?

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DocumentScanner.Classification,
        completeOn queue: DispatchQueue,
        completion: @escaping (CVPixelBuffer) -> Void
    ) {
        self.completion = completion
        isScanningExp.fulfill()
    }

    func respondToScan(pixelBuffer: CVPixelBuffer) {
        completion?(pixelBuffer)
    }

    func cancelScan() {
        didCancel = true
    }
}
