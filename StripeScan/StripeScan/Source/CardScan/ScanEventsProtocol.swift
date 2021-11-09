//
// This protocol provides extensibility for inspecting scanning results as they
// happen. As the model detects a cc number it will invoke `onNumberRecognized`
// and when it's done it notifies via `onScanComplete`.
//
// Both of these methods will always be invoked on the machineLearningQueue
// serial dispatch queue.
//

import CoreGraphics

@available(iOS 11.2, *)
public protocol ScanEvents {
    mutating func onNumberRecognized(number: String, expiry: Expiry?, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?, croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?, uxFrameConfidenceValues: UxFrameConfidenceValues?, flashForcedOn: Bool, numberBoxesInFullImageFrame: [CGRect])
    mutating func onScanComplete(scanStats: ScanStats)
    mutating func onFrameDetected(croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?, uxFrameConfidenceValues: UxFrameConfidenceValues?, flashForcedOn: Bool)
}
