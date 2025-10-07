//
//  CheckProgressView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/7/25.
//

import UIKit

class CheckProgressView: UIView {
    
    private static let checkmarkStrokeDuration = 0.2
    private static let spinnerMoveToCenterAnimationDuration = 0.35
    
    let circleLayer = CAShapeLayer()
    let checkmarkLayer = CAShapeLayer()
    let baseLineWidth: CGFloat
    var color: UIColor = .white {
        didSet {
            colorDidChange()
        }
    }
    
    init(frame: CGRect, baseLineWidth: CGFloat = 1.0) {
        self.baseLineWidth = baseLineWidth
        // Circle
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(
                x: frame.size.width / 2,
                y: frame.size.height / 2),
            radius: (frame.size.width) / 2,
            startAngle: 0.0,
            endAngle: CGFloat.pi * 2,
            clockwise: false)
        circleLayer.bounds = CGRect(
            x: 0, y: 0, width: frame.size.width, height: frame.size.width)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = baseLineWidth
        circleLayer.strokeEnd = 0.0
        
        // Checkmark
        let checkmarkPath = UIBezierPath()
        let checkOrigin = CGPoint(x: frame.size.width * 0.33, y: frame.size.height * 0.5)
        let checkPoint1 = CGPoint(x: frame.size.width * 0.46, y: frame.size.height * 0.635)
        let checkPoint2 = CGPoint(x: frame.size.width * 0.70, y: frame.size.height * 0.36)
        checkmarkPath.move(to: checkOrigin)
        checkmarkPath.addLine(to: checkPoint1)
        checkmarkPath.addLine(to: checkPoint2)
        
        checkmarkLayer.bounds = CGRect(
            x: 0, y: 0, width: frame.size.width, height: frame.size.width)
        checkmarkLayer.path = checkmarkPath.cgPath
        checkmarkLayer.lineCap = .round
        checkmarkLayer.fillColor = UIColor.clear.cgColor
        checkmarkLayer.lineWidth = baseLineWidth + 0.5
        checkmarkLayer.strokeEnd = 0.0
        
        checkmarkLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        circleLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        layer.addSublayer(circleLayer)
        layer.addSublayer(checkmarkLayer)
        
        colorDidChange()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func beginProgress() {
        checkmarkLayer.strokeEnd = 0.0  // Make sure checkmark is not drawn yet
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 1.0
        animation.fromValue = 0
        animation.toValue = 0.8
        animation.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeOut)
        circleLayer.strokeEnd = 0.8
        circleLayer.add(animation, forKey: "animateCircle")
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = 2.0 * Float.pi
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = .infinity
        circleLayer.add(rotationAnimation, forKey: "animateRotate")
    }
    
    func completeProgress(completion: (() -> Void)? = nil) {
        CATransaction.begin()
        // Note: Make sure the completion block is set before adding any animations
        CATransaction.setCompletionBlock {
            if let completion {
                completion()
            }
        }
        circleLayer.removeAnimation(forKey: "animateCircle")
        
        // Close the circle
        let circleAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circleAnimation.duration = Self.spinnerMoveToCenterAnimationDuration
        circleAnimation.fromValue = 0.8
        circleAnimation.toValue = 1
        circleAnimation.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeIn)
        circleLayer.strokeEnd = 1.0
        circleLayer.add(circleAnimation, forKey: "animateDone")
        
        // Check the mark
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.beginTime = CACurrentMediaTime() + circleAnimation.duration + 0.15  // Start after the circle closes
        animation.fillMode = .backwards
        animation.duration = Self.checkmarkStrokeDuration
        animation.fromValue = 0.0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        checkmarkLayer.strokeEnd = 1.0
        checkmarkLayer.add(animation, forKey: "animateFinishCircle")
        CATransaction.commit()
    }
    
    private func colorDidChange() {
        circleLayer.strokeColor = color.cgColor
        checkmarkLayer.strokeColor = color.cgColor
    }
}
