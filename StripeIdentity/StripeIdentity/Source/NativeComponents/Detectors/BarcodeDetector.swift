//
//  BarcodeDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/25/22.
//

import Foundation
import Vision

struct BarcodeDetectorOutput: Equatable {
    let hasBarcode: Bool
    let isTimedOut: Bool
    let symbology: VNBarcodeSymbology
    let timeTryingToFindBarcode: TimeInterval
}

extension BarcodeDetectorOutput: VisionBasedDetectorOutput {
    init(
        detector: BarcodeDetector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws {
        let barcodeObservations: [VNBarcodeObservation] = observations.compactMap {
            guard let observation = $0 as? VNBarcodeObservation,
                  detector.configuration.symbology == observation.symbology
            else {
                return nil
            }
            return observation
        }

        var timeTryingToFindBarcode: TimeInterval = -1
        if let firstScanTimestamp = detector.firstScanTimestamp {
            timeTryingToFindBarcode = Date().timeIntervalSince(firstScanTimestamp)
        }
        self.init(
            hasBarcode: !barcodeObservations.isEmpty,
            isTimedOut: false,
            symbology: detector.configuration.symbology,
            timeTryingToFindBarcode: timeTryingToFindBarcode
        )
    }
}

final class BarcodeDetector: VisionBasedDetector {

    struct Configuration {
        /// Which type of barcode symbology to scan for
        let symbology: VNBarcodeSymbology
        /// The amount of time to look for a barcode before accepting images without
        let timeout: TimeInterval
    }

    /// Wrap all instance property modifications in a serial queue
    private let serialQueue = DispatchQueue(label: "com.stripe.identity.barcode-detector")

    fileprivate var firstScanTimestamp: Date?

    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func visionBasedDetectorMakeRequest() -> VNImageBasedRequest {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [configuration.symbology]
        return request
    }

    func visionBasedDetectorOutputIfSkipping() -> BarcodeDetectorOutput? {
        let timeOfScanRequest = Date()
        var timeSinceScan: TimeInterval = 0
        serialQueue.sync { [weak self] in
            let firstScanTimestamp = self?.firstScanTimestamp ?? timeOfScanRequest
            self?.firstScanTimestamp = firstScanTimestamp
            timeSinceScan = timeOfScanRequest.timeIntervalSince(firstScanTimestamp)
        }

        guard timeSinceScan >= configuration.timeout else {
            return nil
        }

        return .init(
            hasBarcode: false,
            isTimedOut: true,
            symbology: configuration.symbology,
            timeTryingToFindBarcode: timeSinceScan
        )
    }

    func reset() {
        serialQueue.async { [weak self] in
            self?.firstScanTimestamp = nil
        }
    }
}
