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

}
