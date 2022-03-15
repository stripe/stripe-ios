//
//  DocumentScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/9/21.
//

import CoreVideo
import Vision
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

protocol DocumentScannerProtocol: AnyObject {
    typealias Completion = (DocumentScannerOutput?) -> Void

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    )

    func reset()
}

/// Scans a camera feed for a valid identity document.
@available(iOS 13, *)
final class DocumentScanner: DocumentScannerProtocol {

    static let defaultMaxConcurrentScans: Int = 2

    #if DEBUG
    /// Manages stateful properties used to log analytics
    private let analyticsQueue = DispatchQueue(label: "com.stripe.identity.document-scanner")

    private var firstScanStartTime: Date?
    private var lastScanEndTime: Date?
    private var processedFrames = 0
    #endif

    private let idDetector: IDDetector
    private let motionBlurDetector: MotionBlurDetector
    private let barcodeDetector: BarcodeDetector?

    /// Detectors will perform scans concurrently to optimize CPU and GPU overlap.
    /// No more than `maxConcurrentScans` tasks will run on this queue.
    let concurrentQueue = DispatchQueue(
        label: "com.stripe.identity.document-scanner",
        attributes: .concurrent
    )
    /// Semaphore used to block the current thread until detectors have completed
    private let semaphore: DispatchSemaphore

    /**
     Initializes a DocumentScanner with an `IDDetector`.

     - Parameters:
       - idDetector: The IDDetector to classify document images.
       - maxConcurrentScans: The maximum number of concurrent image processing requests.

     - Note:
     Increasing `maxConcurrentScans` can result in an overall faster frame rate
     of processed images per second, but usually at the cost of increasing the
     time of a single scan request since the CPU and GPU can each only handle
     one CoreML processing request at a time.

     On most devices, the optimal `maxConcurrentScans` value is 2 to take
     advantage of parallel processing when a CoreML request is handed from the
     CPU to GPU.
     */
    init(
        idDetector: IDDetector,
        motionBlurDetector: MotionBlurDetector,
        barcodeDetector: BarcodeDetector?,
        maxConcurrentScans: Int = defaultMaxConcurrentScans
    ) {
        self.idDetector = idDetector
        self.motionBlurDetector = motionBlurDetector
        self.barcodeDetector = barcodeDetector
        self.semaphore = DispatchSemaphore(value: maxConcurrentScans)
    }

    // TODO(mludowise|IDPROD-3269): Use configuration from API response
    convenience init(
        idDetectorModel: VNCoreMLModel,
        maxConcurrentScans: Int = defaultMaxConcurrentScans,
        configuration: Configuration = .default
    ) {
        self.init(
            idDetector: IDDetector(
                model: idDetectorModel,
                configuration: .init(
                    minScore: configuration.idDetectorMinScore,
                    minIOU: configuration.idDetectorMinIOU
                )
            ),
            motionBlurDetector: MotionBlurDetector(
                minIOU: configuration.motionBlurMinIOU,
                minTime: configuration.motionBlurMinDuration
            ),
            barcodeDetector: configuration.backIdCardBarcodeSymbology.map {
                BarcodeDetector(
                    configuration: .init(
                        symbology: $0,
                        timeout: configuration.backIdCardBarcodeTimeout
                    )
                )
            },
            maxConcurrentScans: maxConcurrentScans
        )
    }

    /**
     Scans a camera frame and calls a completion block with the scanned output

     - Note:
     This can potentially block the current thread until the scan is complete.

     If `scanImage` is called concurrently multiple times, it will block the
     caller thread until the previous calls have completed such that no more
     than `maxConcurrentScans` are performing concurrently.

     This method is meant to be called from a concurrent video capture thread
     (e.g. `AVCaptureVideoDataOutputSampleBufferDelegate.captureOutput`) so that
     camera frames are dropped while the scanner is blocking the video capture
     thread, ensuring only `maxConcurrentScans` number of pixel buffers are
     being retained.

     - Parameters:
       - pixelBuffer: Image to scan
       - cameraSession: The CameraSession that the image was captured from
       - completionQueue: DispatchQueue to call the completion block on
       - completion: Executed after the image has been analyzed
     */
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping Completion
    ) {
        assert(!Thread.isMainThread, "`scanImage` should not be called from the main thread")

        // Get camera session properties immediately before the camera state changes
        let cameraProperties = cameraSession.getCameraProperties()

        let wrappedCompletion: Completion = { output in
            completionQueue.async {
                completion(output)
            }
        }

        #if DEBUG
        let startScan = Date()
        analyticsQueue.async { [weak self] in
            self?.firstScanStartTime = self?.firstScanStartTime ?? startScan
        }
        #endif

        semaphore.wait()
        concurrentQueue.async { [weak self] in
            guard let self = self else { return }

            defer {
                self.semaphore.signal()
            }

            let lastScanEndTime: Date
            do {
                // Scan for ID Document Classification
                guard let idDetectorOutput = try self.idDetector.scanImage(pixelBuffer: pixelBuffer) else {
                    return wrappedCompletion(nil)
                }

                // Check for motion blur
                let motionBlurOutput = self.motionBlurDetector.determineMotionBlur(
                    documentBounds: idDetectorOutput.documentBounds
                )

                // If there's motion blur, reset the timer on the barcode detector.
                // Otherwise, scan for a barcode if this is the back of an ID.
                var barcodeOutput: BarcodeDetectorOutput? = nil
                if let barcodeDetector = self.barcodeDetector,
                   idDetectorOutput.classification == .idCardBack {
                    barcodeOutput = try barcodeDetector.scanImage(
                        pixelBuffer: pixelBuffer,
                        regionOfInterest: idDetectorOutput.documentBounds
                    )
                }

                // Capture metrics
                lastScanEndTime = Date()

                let output = DocumentScannerOutput(
                    idDetectorOutput: idDetectorOutput,
                    barcode: barcodeOutput,
                    motionBlur: motionBlurOutput,
                    cameraProperties: cameraProperties
                )

                wrappedCompletion(output)
            } catch {
                lastScanEndTime = Date()
                // TODO(mludowise|IDPROD-2816): log error
            }

            #if DEBUG
            // TODO(mludowise|IDPROD-3302): Log performance metrics instead of print
            let scanTime = lastScanEndTime.timeIntervalSince(startScan)
            print("ScanTime: \(scanTime)")

            // Update stateful properties on analyticsQueue
            self.analyticsQueue.async { [weak self] in
                self?.lastScanEndTime = lastScanEndTime
                self?.processedFrames += 1
            }
            #endif
        }
    }

    func reset() {
        #if DEBUG
        analyticsQueue.async { [weak self] in
            // TODO(IDPROD-3302): Log this as an analytic
            guard let self = self,
                  let firstScanStartTime = self.firstScanStartTime,
                  let lastScanEndTime = self.lastScanEndTime
            else {
                return
            }
            let framesPerSecond = Float(self.processedFrames) / Float(lastScanEndTime.timeIntervalSince(firstScanStartTime))
            print("Frames per second: \(framesPerSecond)")

            self.firstScanStartTime = nil
            self.lastScanEndTime = nil
            self.processedFrames = 0
        }
        #endif
        motionBlurDetector.reset()
        barcodeDetector?.reset()
    }
}

extension IDDetectorOutput.Classification {
    /**
     Determines if the classification output by the IDDetector matches the
     scanner's desired classification.

     - Parameters:
       - type: The desired document type
       - side: The desired document side

     - Returns: True if this classification matches the desired classification.
     */
    func matchesDocument(
        type: DocumentType,
        side: DocumentSide
    ) -> Bool {
        switch (type, side, self) {
        case (.drivingLicense, .front, .idCardFront),
            (.idCard, .front, .idCardFront),
            (.drivingLicense, .back, .idCardBack),
            (.idCard, .back, .idCardBack),
            (.passport, _, .passport):
            return true
        default:
            return false
        }
    }
}
