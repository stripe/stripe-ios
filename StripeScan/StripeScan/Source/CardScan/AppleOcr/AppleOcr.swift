import Vision
import UIKit

@available(iOS 13.0, *)
struct AppleOcr {
    static func configure() {
        // warm up the model eventually
    }
    
    static func convertToImageRect(boundingBox: VNRectangleObservation, imageSize: CGSize) -> CGRect {
        let topLeft = VNImagePointForNormalizedPoint(boundingBox.topLeft,
                                                     Int(imageSize.width),
                                                     Int(imageSize.height))
        let bottomRight = VNImagePointForNormalizedPoint(boundingBox.bottomRight,
                                                         Int(imageSize.width),
                                                         Int(imageSize.height))
        // flip it for top left (0,0) image coordinates
        return CGRect(x: topLeft.x, y: imageSize.height - topLeft.y,
                      width: abs(bottomRight.x - topLeft.x),
                      height: abs(topLeft.y - bottomRight.y))
        
    }
    
    static func performOcr(image: CGImage, completion: @escaping ([OcrObject]) -> Void) {
        let textRequest = VNRecognizeTextRequest() { request, error in
            let imageSize = CGSize(width: image.width, height: image.height)

            guard let results = request.results as? [VNRecognizedTextObservation], !results.isEmpty else {
                completion([])
                return
            }
            let outputObjects: [OcrObject] = results.compactMap { result in
                guard let candidate = result.topCandidates(1).first,
                    let box = try? candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex) else {
                    return nil
                }
                
                #if swift(>=5.0)
                let unwrappedBox: VNRectangleObservation = box
                #else
                guard let unwrappedBox: VNRectangleObservation = box else { return nil }
                #endif
                
                let boxRect = convertToImageRect(boundingBox: unwrappedBox, imageSize: imageSize)
                let confidence: Float = candidate.confidence
                return OcrObject(text: candidate.string, conf: confidence, textBox: boxRect, imageSize: imageSize)
            }
            
            completion(outputObjects)
        }
       
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = false
       
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            completion([])
        }
    }
    
    static func recognizeText(in image: CGImage, complete: @escaping ([OcrObject]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            performOcr(image: image) { complete($0) }
        }
    }
}
