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
    private(set) var isScanningExp = XCTestExpectation(description: "scanImage called")

    private(set) var scanImagePromise = Promise<CVPixelBuffer>()

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DocumentScanner.Classification,
        completeOn queue: DispatchQueue
    ) -> Promise<CVPixelBuffer> {
        isScanningExp.fulfill()
        return scanImagePromise
    }
}
