import CoreGraphics
import Foundation

/// Data structure to keep track of each box that the model detects.
///
/// Note: the rect member is in the image's coordinate system.

struct DetectedBox {
    let rect: CGRect
    let row: Int
    let col: Int
    let confidence: Double
    let numRows: Int
    let numCols: Int
    let boxSize: CGSize
    let cardSize: CGSize
    let imageSize: CGSize

    init(
        row: Int,
        col: Int,
        confidence: Double,
        numRows: Int,
        numCols: Int,
        boxSize: CGSize,
        cardSize: CGSize,
        imageSize: CGSize
    ) {

        // Resize the box to transform it from the model's coordinates into
        // the image's coordinates
        let w = boxSize.width * imageSize.width / cardSize.width
        let h = boxSize.height * imageSize.height / cardSize.height
        let x = (imageSize.width - w) / CGFloat(numCols - 1) * CGFloat(col)
        let y = (imageSize.height - h) / CGFloat(numRows - 1) * CGFloat(row)
        self.rect = CGRect(x: x, y: y, width: w, height: h)
        self.row = row
        self.col = col
        self.confidence = confidence
        self.numRows = numRows
        self.numCols = numCols
        self.boxSize = boxSize
        self.cardSize = cardSize
        self.imageSize = imageSize
    }

    func move(row: Int, col: Int) -> DetectedBox? {
        if row < 0 || row >= self.numRows || col < 0 || col >= self.numCols {
            return nil
        }
        return DetectedBox(
            row: row,
            col: col,
            confidence: self.confidence,
            numRows: self.numRows,
            numCols: self.numCols,
            boxSize: self.boxSize,
            cardSize: self.cardSize,
            imageSize: self.imageSize
        )
    }
}
