//
//  BlurView.swift
//  CardScan
//
//  Created by Jaime Park on 8/15/19.
//

import UIKit

public class BlurView: UIView {
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func maskToRoi(roi: UIView) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let roiCornerRadius = roi.layer.cornerRadius
        let roiFrame = roi.layer.frame
        let roundedRectpath = UIBezierPath.init(roundedRect: roiFrame, cornerRadius: roiCornerRadius).cgPath
        
        path.addRect(self.layer.bounds)
        path.addPath(roundedRectpath)
        maskLayer.path = path
        #if swift(>=4.2)
        maskLayer.fillRule = .evenOdd
        #else
        maskLayer.fillRule = kCAFillRuleEvenOdd
        #endif
        self.layer.mask = maskLayer
    }

}
