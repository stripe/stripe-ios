//
//  BlurView.swift
//  CardScan
//
//  Created by Jaime Park on 8/15/19.
//

import UIKit

class BlurView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func maskToRoi(roi: UIView) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let roiCornerRadius = roi.layer.cornerRadius
        let roiFrame = roi.layer.frame
        let roundedRectpath = UIBezierPath.init(roundedRect: roiFrame, cornerRadius: roiCornerRadius).cgPath

        path.addRect(self.layer.bounds)
        path.addPath(roundedRectpath)
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        self.layer.mask = maskLayer
    }

}
