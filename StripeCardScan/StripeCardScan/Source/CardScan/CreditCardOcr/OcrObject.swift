import UIKit

struct OcrObject {
    let rect: CGRect
    let text: String
    let confidence: Float
    let imageSize: CGSize

    init(
        text: String,
        conf: Float,
        textBox: CGRect,
        imageSize: CGSize
    ) {
        self.text = text
        self.confidence = conf
        self.rect = textBox
        self.imageSize = imageSize
    }

    func toDict() -> [String: Any] {
        return [
            "x_min": self.rect.minX / self.imageSize.width,
            "y_min": self.rect.minY / self.imageSize.height,
            "height": self.rect.height / self.imageSize.height,
            "width": self.rect.width / self.imageSize.width,
            "text": self.text,
            "confidence": self.confidence,
        ]
    }

}
