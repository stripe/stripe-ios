//
//  CheckmarkCircleView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
import UIKit

final class CheckmarkCircleView: UIView {
    
    let checkmarkColor: UIColor = .white
    let fillColor: UIColor
    
    // Initialization
    init(fillColor: UIColor) {
        self.fillColor = fillColor
        super.init(frame: .zero)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCircle()
        drawCheckmark()
    }
    
    private func drawCircle() {
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: intrinsicContentSize))
        fillColor.setFill()
        path.fill()
    }
    
    private func drawCheckmark() {
        let path = UIBezierPath()
        path.lineWidth = max(2, intrinsicContentSize.width * 0.06)
        path.move(to: CGPoint(x: intrinsicContentSize.width * 0.28, y: intrinsicContentSize.height * 0.53))
        path.addLine(to: CGPoint(x: intrinsicContentSize.width * 0.42, y: intrinsicContentSize.height * 0.66))
        path.addLine(to: CGPoint(x: intrinsicContentSize.width * 0.72, y: intrinsicContentSize.height * 0.36))
        
        checkmarkColor.setStroke()
        path.stroke()
    }
}
