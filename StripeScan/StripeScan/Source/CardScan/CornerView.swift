import UIKit

public class CornerView: UIView {
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public func setFrameSize(roi: UIView) {
        let borderWidth = self.layer.borderWidth
        let width = roi.layer.bounds.width + 2*borderWidth
        let height = roi.layer.bounds.height + 2*borderWidth
        let cornerViewBoundRect = CGRect(x: self.layer.bounds.origin.x, y: self.layer.bounds.origin.y, width: width, height: height)
        self.layer.bounds = cornerViewBoundRect
    }
    
    public func drawCorners(){
        let maskShapeLayer = CAShapeLayer()
        let maskPath = CGMutablePath()
        
        let boundX = self.layer.bounds.origin.x
        let boundY = self.layer.bounds.origin.y
        let boundWidth = self.layer.bounds.width
        let boundHeight = self.layer.bounds.height
        
        let cornerMultiplier = CGFloat(0.1)
        let cornerLength = self.layer.frame.width * cornerMultiplier
        
        //top left corner
        maskPath.move(to: self.layer.bounds.origin)
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y:  boundY))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundY + cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX, y: boundY + cornerLength))
        maskPath.closeSubpath()
        
        //top right corner
        maskPath.move(to: CGPoint(x: boundWidth - cornerLength, y: boundY))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundY))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundY + cornerLength))
        maskPath.addLine(to: CGPoint(x:boundWidth - cornerLength, y: boundY + cornerLength))
        maskPath.closeSubpath()
        
        //bottom left corner
        maskPath.move(to: CGPoint(x: boundX, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundX + cornerLength, y: boundHeight))
        maskPath.addLine(to: CGPoint(x: boundX, y: boundHeight))
        maskPath.closeSubpath()
        
        //bottom right corner
        maskPath.move(to: CGPoint(x: boundWidth - cornerLength, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundHeight - cornerLength))
        maskPath.addLine(to: CGPoint(x: boundWidth, y: boundHeight))
        maskPath.addLine(to: CGPoint(x: boundWidth - cornerLength, y: boundHeight))
        maskPath.closeSubpath()
        
        maskShapeLayer.path = maskPath
        self.layer.mask = maskShapeLayer
    }
}
