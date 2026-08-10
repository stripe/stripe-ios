//
//  CaptureTickMarksView.swift
//  StripeIdentity
//
//  Created by Stripe on 8/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

final class CaptureTickMarksView: UIView {
    struct Styling {
        static let tickCount = 68
        static let tickLength: CGFloat = 10.25
        static let highlightedTickLength: CGFloat = 18.75
        static let tickWidth: CGFloat = 2.09
        static let highlightedTickWidth: CGFloat = 4.025
        static let baseTickFadeAnimationDuration: TimeInterval = 1.0
        static let baseTickOppositeSideMinOpacityMultiplier: CGFloat = 0.02
        static let baseTickOppositeSideFadeExponent: CGFloat = 0.25
        static let legacyHighlightAnimationDuration: TimeInterval = 0.18
        static let instructionAnimationDuration: TimeInterval = 0.72
        static let feedbackAnimationDuration: TimeInterval = 0.15
        static let successAnimationDuration: TimeInterval = 0.42
        static let successFadeOutDuration: TimeInterval = 0.34
        static let successCheckmarkSize: CGFloat = 28
        static let successCheckmarkInitialScale: CGFloat = 0.72
        static let horizontalDiameterToWidthRatio: CGFloat = 0.57
        static let verticalDiameterToHeightRatio: CGFloat = 0.57
        static let centerYRatio: CGFloat = 0.5
        static let tickColor = UIColor.white.withAlphaComponent(0.9)
        static let acceptedTickColor = UIColor(
            red: 0x31 / 255,
            green: 0xC9 / 255,
            blue: 0x5F / 255,
            alpha: 1
        )
        static let shadowColor = UIColor.black.withAlphaComponent(0.22)
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowBlur: CGFloat = 3.5
        static let centeredShadowOuterOpacity: CGFloat = 0.62
        static let centeredShadowClearPadding: CGFloat = 6
        static let centeredShadowGradientStepCount = 16
        static let centeredShadowFadeInDuration: TimeInterval = SelfieScanningView.Styling.captureGuideShadowFadeInDuration
    }

    private var uses3DCaptureAnimations = false
    private var captureGuideHighlight: SelfieScanningView.ViewModel.CaptureGuideHighlight = .none
    private var captureGuideTarget: SelfieScanningView.ViewModel.CaptureGuideTarget = .none
    private var targetProgress: CGFloat = 0
    private var displayedTargetProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var targetProgressAnimationStartValue: CGFloat = 0
    private var targetProgressAnimationStartTime: CFTimeInterval?
    private var baseTickFadeProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var baseTickFadeAnimationStartTime: CFTimeInterval?
    private var directionalPulseProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var directionalPulseAnimationStartTime: CFTimeInterval?
    private var highlightedTickProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var highlightedTickOpacity: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var showsCenteredShadow: Bool = false
    private var centeredShadowOpacity: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var highlightedTickDisplayLink: CADisplayLink?
    private var highlightedTickAnimationStartTime: CFTimeInterval?
    private var targetTickDisplayLink: CADisplayLink?
    private var centeredShadowDisplayLink: CADisplayLink?
    private var centeredShadowAnimationStartTime: CFTimeInterval?

    private let successCheckmarkView: CaptureSuccessCheckmarkView = {
        let view = CaptureSuccessCheckmarkView()
        view.alpha = 0
        view.isHidden = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.28
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(successCheckmarkView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        highlightedTickDisplayLink?.invalidate()
        targetTickDisplayLink?.invalidate()
        centeredShadowDisplayLink?.invalidate()
    }

    func setUses3DCaptureAnimations(_ uses3DCaptureAnimations: Bool) {
        guard uses3DCaptureAnimations != self.uses3DCaptureAnimations else {
            return
        }

        self.uses3DCaptureAnimations = uses3DCaptureAnimations
        resetTargetAnimation()
        resetHighlightAnimation()
    }

    func setCaptureGuideTarget(
        _ captureGuideTarget: SelfieScanningView.ViewModel.CaptureGuideTarget,
        progress: CGFloat,
        animated: Bool
    ) {
        let clampedProgress = min(max(progress, 0), 1)
        let didChangeTarget = captureGuideTarget != self.captureGuideTarget
        guard didChangeTarget || clampedProgress != targetProgress else {
            return
        }

        self.captureGuideTarget = captureGuideTarget
        targetProgress = clampedProgress

        guard uses3DCaptureAnimations, captureGuideTarget != .none else {
            resetTargetAnimation()
            return
        }

        if didChangeTarget {
            displayedTargetProgress = 0
            baseTickFadeProgress = 0
            baseTickFadeAnimationStartTime = CACurrentMediaTime()
            directionalPulseProgress = 0
            directionalPulseAnimationStartTime = CACurrentMediaTime()
        }

        guard animated, window != nil else {
            displayedTargetProgress = clampedProgress
            baseTickFadeProgress = 1
            baseTickFadeAnimationStartTime = nil
            targetProgressAnimationStartTime = nil
            directionalPulseProgress = 0
            directionalPulseAnimationStartTime = nil
            return
        }

        targetProgressAnimationStartValue = displayedTargetProgress
        targetProgressAnimationStartTime = CACurrentMediaTime()
        startTargetTickDisplayLinkIfNeeded()
    }

    func setShowsCenteredShadow(_ showsCenteredShadow: Bool, animated: Bool) {
        guard showsCenteredShadow != self.showsCenteredShadow else {
            return
        }

        self.showsCenteredShadow = showsCenteredShadow
        centeredShadowDisplayLink?.invalidate()
        centeredShadowDisplayLink = nil
        centeredShadowAnimationStartTime = nil

        guard showsCenteredShadow else {
            centeredShadowOpacity = 0
            return
        }

        guard animated, window != nil else {
            centeredShadowOpacity = 1
            return
        }

        centeredShadowOpacity = 0
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateCenteredShadowFadeIn)
        )
        displayLink.add(to: .main, forMode: .common)
        centeredShadowDisplayLink = displayLink
    }

    func setCaptureGuideHighlight(
        _ captureGuideHighlight: SelfieScanningView.ViewModel.CaptureGuideHighlight,
        animated: Bool
    ) {
        guard captureGuideHighlight != self.captureGuideHighlight else {
            return
        }

        self.captureGuideHighlight = captureGuideHighlight
        highlightedTickDisplayLink?.invalidate()
        highlightedTickDisplayLink = nil
        highlightedTickAnimationStartTime = nil

        guard captureGuideHighlight != .none else {
            highlightedTickProgress = 0
            highlightedTickOpacity = 0
            successCheckmarkView.alpha = 0
            successCheckmarkView.isHidden = true
            return
        }

        guard animated, window != nil else {
            highlightedTickProgress = 1
            highlightedTickOpacity = 1
            configureSuccessCheckmark(progress: 1, opacity: 1)
            return
        }

        highlightedTickProgress = 0
        highlightedTickOpacity = 0
        successCheckmarkView.isHidden = !uses3DCaptureAnimations
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateHighlightedTickAnimation)
        )
        displayLink.add(to: .main, forMode: .common)
        highlightedTickDisplayLink = displayLink
    }

    @objc private func updateHighlightedTickAnimation(_ displayLink: CADisplayLink) {
        if highlightedTickAnimationStartTime == nil {
            highlightedTickAnimationStartTime = displayLink.timestamp
        }
        guard let highlightedTickAnimationStartTime else {
            return
        }

        let elapsedTime = displayLink.timestamp - highlightedTickAnimationStartTime
        if uses3DCaptureAnimations {
            let fadeInProgress = min(
                max(elapsedTime / Styling.successAnimationDuration, 0),
                1
            )
            highlightedTickProgress = materialEase(fadeInProgress)

            if elapsedTime <= Styling.successAnimationDuration {
                highlightedTickOpacity = highlightedTickProgress
            } else {
                let fadeOutProgress = min(
                    max(
                        (elapsedTime - Styling.successAnimationDuration)
                            / Styling.successFadeOutDuration,
                        0
                    ),
                    1
                )
                highlightedTickOpacity = 1 - fadeOutProgress
            }
            configureSuccessCheckmark(
                progress: highlightedTickProgress,
                opacity: highlightedTickOpacity
            )

            if elapsedTime >= Styling.successAnimationDuration + Styling.successFadeOutDuration {
                displayLink.invalidate()
                highlightedTickDisplayLink = nil
                self.highlightedTickAnimationStartTime = nil
                highlightedTickProgress = 1
                highlightedTickOpacity = 0
                successCheckmarkView.alpha = 0
                successCheckmarkView.isHidden = true
            }
            return
        }

        let progress = min(max(elapsedTime / Styling.legacyHighlightAnimationDuration, 0), 1)
        highlightedTickProgress = progress
        highlightedTickOpacity = 1 - pow(1 - progress, 2)
        if progress >= 1 {
            displayLink.invalidate()
            highlightedTickDisplayLink = nil
            self.highlightedTickAnimationStartTime = nil
            highlightedTickProgress = 1
            highlightedTickOpacity = 1
        }
    }

    @objc private func updateTargetTickAnimation(_ displayLink: CADisplayLink) {
        if let directionalPulseAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - directionalPulseAnimationStartTime)
                        / Styling.instructionAnimationDuration,
                    0
                ),
                1
            )
            if progress < 0.5 {
                directionalPulseProgress = materialEase(progress * 2)
            } else {
                directionalPulseProgress = 1 - materialEase((progress - 0.5) * 2)
            }
            if progress >= 1 {
                self.directionalPulseAnimationStartTime = nil
                directionalPulseProgress = 0
            }
        }

        if let targetProgressAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - targetProgressAnimationStartTime)
                        / Styling.feedbackAnimationDuration,
                    0
                ),
                1
            )
            let easedProgress = 1 - pow(1 - progress, 3)
            displayedTargetProgress = targetProgressAnimationStartValue
                + ((targetProgress - targetProgressAnimationStartValue) * easedProgress)
            if progress >= 1 {
                self.targetProgressAnimationStartTime = nil
                displayedTargetProgress = targetProgress
            }
        }
        if let baseTickFadeAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - baseTickFadeAnimationStartTime)
                        / Styling.baseTickFadeAnimationDuration,
                    0
                ),
                1
            )
            baseTickFadeProgress = materialEase(progress)
            if progress >= 1 {
                self.baseTickFadeAnimationStartTime = nil
                baseTickFadeProgress = 1
            }
        }

        if directionalPulseAnimationStartTime == nil
            && targetProgressAnimationStartTime == nil
            && baseTickFadeAnimationStartTime == nil
        {
            displayLink.invalidate()
            targetTickDisplayLink = nil
        }
    }

    private func startTargetTickDisplayLinkIfNeeded() {
        guard targetTickDisplayLink == nil,
            directionalPulseAnimationStartTime != nil
                || targetProgressAnimationStartTime != nil
                || baseTickFadeAnimationStartTime != nil
        else {
            return
        }

        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateTargetTickAnimation)
        )
        displayLink.add(to: .main, forMode: .common)
        targetTickDisplayLink = displayLink
    }

    private func resetTargetAnimation() {
        targetTickDisplayLink?.invalidate()
        targetTickDisplayLink = nil
        captureGuideTarget = .none
        targetProgress = 0
        displayedTargetProgress = 0
        baseTickFadeProgress = 0
        baseTickFadeAnimationStartTime = nil
        targetProgressAnimationStartTime = nil
        directionalPulseProgress = 0
        directionalPulseAnimationStartTime = nil
    }

    private func resetHighlightAnimation() {
        highlightedTickDisplayLink?.invalidate()
        highlightedTickDisplayLink = nil
        highlightedTickAnimationStartTime = nil
        captureGuideHighlight = .none
        highlightedTickProgress = 0
        highlightedTickOpacity = 0
        successCheckmarkView.alpha = 0
        successCheckmarkView.isHidden = true
    }

    private func configureSuccessCheckmark(progress: CGFloat, opacity: CGFloat) {
        guard uses3DCaptureAnimations else {
            successCheckmarkView.isHidden = true
            return
        }

        successCheckmarkView.isHidden = false
        successCheckmarkView.alpha = opacity
        let scale = Styling.successCheckmarkInitialScale
            + ((1 - Styling.successCheckmarkInitialScale) * progress)
        successCheckmarkView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    private func materialEase(_ progress: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 1)
        var parameter = clampedProgress
        for _ in 0..<5 {
            let x = cubicBezier(parameter, controlPoint1: 0.4, controlPoint2: 0.2)
            let slope = cubicBezierSlope(parameter, controlPoint1: 0.4, controlPoint2: 0.2)
            guard abs(slope) > 0.0001 else {
                break
            }
            parameter = min(max(parameter - ((x - clampedProgress) / slope), 0), 1)
        }
        return cubicBezier(parameter, controlPoint1: 0, controlPoint2: 1)
    }

    private func cubicBezier(
        _ progress: CGFloat,
        controlPoint1: CGFloat,
        controlPoint2: CGFloat
    ) -> CGFloat {
        let inverseProgress = 1 - progress
        return (3 * inverseProgress * inverseProgress * progress * controlPoint1)
            + (3 * inverseProgress * progress * progress * controlPoint2)
            + (progress * progress * progress)
    }

    private func cubicBezierSlope(
        _ progress: CGFloat,
        controlPoint1: CGFloat,
        controlPoint2: CGFloat
    ) -> CGFloat {
        let inverseProgress = 1 - progress
        return (3 * inverseProgress * inverseProgress * controlPoint1)
            + (6 * inverseProgress * progress * (controlPoint2 - controlPoint1))
            + (3 * progress * progress * (1 - controlPoint2))
    }

    @objc private func updateCenteredShadowFadeIn(_ displayLink: CADisplayLink) {
        if centeredShadowAnimationStartTime == nil {
            centeredShadowAnimationStartTime = displayLink.timestamp
        }
        guard let centeredShadowAnimationStartTime else {
            return
        }

        let elapsedTime = displayLink.timestamp - centeredShadowAnimationStartTime
        let progress = min(
            max(elapsedTime / Styling.centeredShadowFadeInDuration, 0),
            1
        )
        centeredShadowOpacity = 1 - ((1 - progress) * (1 - progress))

        if progress >= 1 {
            displayLink.invalidate()
            centeredShadowDisplayLink = nil
            self.centeredShadowAnimationStartTime = nil
            centeredShadowOpacity = 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        successCheckmarkView.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: Styling.successCheckmarkSize,
                height: Styling.successCheckmarkSize
            )
        )
        successCheckmarkView.center = CGPoint(
            x: bounds.midX,
            y: bounds.height * Styling.centerYRatio
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        let horizontalRadius = bounds.width * Styling.horizontalDiameterToWidthRatio / 2
        let verticalRadius = bounds.height * Styling.verticalDiameterToHeightRatio / 2
        let center = CGPoint(
            x: bounds.midX,
            y: bounds.height * Styling.centerYRatio
        )

        if showsCenteredShadow, centeredShadowOpacity > 0 {
            drawCenteredShadow(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                opacity: centeredShadowOpacity
            )
        }

        drawBaseTicks(
            in: context,
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius
        )

        if uses3DCaptureAnimations,
            captureGuideTarget != .none,
            directionalPulseProgress > 0
        {
            let tickLength = Styling.tickLength
                + ((Styling.highlightedTickLength - Styling.tickLength)
                    * directionalPulseProgress)
            context.setLineWidth(Styling.tickWidth)
            context.setStrokeColor(Styling.tickColor.cgColor)
            drawTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: tickLength,
                growsOutward: true,
                outwardGrowthScale: { abs(cos($0)) },
                shouldDrawTick: { [weak self] angle in
                    self?.shouldDrawDirectionalPulseTick(at: angle) ?? false
                }
            )
            context.strokePath()
        }

        if uses3DCaptureAnimations,
            captureGuideTarget != .none,
            displayedTargetProgress > 0
        {
            drawAcceptedTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: Styling.highlightedTickLength,
                growsOutward: true,
                opacity: 1,
                shouldDrawTick: { [weak self] angle in
                    self?.isTickRevealedByProgress(at: angle) ?? false
                }
            )
        }

        if captureGuideHighlight != .none,
            highlightedTickProgress > 0,
            highlightedTickOpacity > 0
        {
            let highlightedTickLength = Styling.tickLength
                + ((Styling.highlightedTickLength - Styling.tickLength)
                    * highlightedTickProgress)
            drawAcceptedTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: highlightedTickLength,
                growsOutward: uses3DCaptureAnimations,
                opacity: highlightedTickOpacity,
                shouldDrawTick: { [weak self] angle in
                    self?.isTickHighlighted(at: angle) ?? false
                }
            )
        }
    }

    private func drawAcceptedTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool,
        opacity: CGFloat,
        shouldDrawTick: (CGFloat) -> Bool
    ) {
        let clampedOpacity = min(max(opacity, 0), 1)

        context.saveGState()
        context.setLineCap(.round)
        context.setLineWidth(Styling.highlightedTickWidth)
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(
            Styling.acceptedTickColor.withAlphaComponent(clampedOpacity).cgColor
        )
        drawTicks(
            in: context,
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: tickLength,
            growsOutward: growsOutward,
            shouldDrawTick: shouldDrawTick
        )
        context.strokePath()
        context.restoreGState()
    }

    private func drawBaseTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat
    ) {
        context.saveGState()
        context.setLineWidth(Styling.tickWidth)
        context.setLineCap(.round)
        context.setShadow(
            offset: Styling.shadowOffset,
            blur: Styling.shadowBlur,
            color: Styling.shadowColor.cgColor
        )

        forEachTick(
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: Styling.tickLength,
            shouldDrawTick: { [weak self] angle in
                self?.shouldDrawBaseTick(at: angle) ?? true
            }
        ) { angle, startPoint, endPoint in
            context.setStrokeColor(baseTickColor(at: angle).cgColor)
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
        context.restoreGState()
    }

    private func drawTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool = false,
        outwardGrowthScale: ((CGFloat) -> CGFloat)? = nil,
        shouldDrawTick: (CGFloat) -> Bool
    ) {
        forEachTick(
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: tickLength,
            growsOutward: growsOutward,
            outwardGrowthScale: outwardGrowthScale,
            shouldDrawTick: shouldDrawTick
        ) { _, startPoint, endPoint in

            context.move(to: startPoint)
            context.addLine(to: endPoint)
        }
    }

    private func forEachTick(
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool = false,
        outwardGrowthScale: ((CGFloat) -> CGFloat)? = nil,
        shouldDrawTick: (CGFloat) -> Bool,
        _ body: (CGFloat, CGPoint, CGPoint) -> Void
    ) {
        for index in 0..<Styling.tickCount {
            let angle = (CGFloat(index) / CGFloat(Styling.tickCount)) * .pi * 2
            guard shouldDrawTick(angle) else {
                continue
            }

            let cosAngle = cos(angle)
            let sinAngle = sin(angle)
            let tickCenter = CGPoint(
                x: center.x + cosAngle * horizontalRadius,
                y: center.y + sinAngle * verticalRadius
            )
            let normal = CGVector(
                dx: cosAngle / horizontalRadius,
                dy: sinAngle / verticalRadius
            )
            let normalLength = sqrt((normal.dx * normal.dx) + (normal.dy * normal.dy))
            let unitNormal = CGVector(
                dx: normal.dx / normalLength,
                dy: normal.dy / normalLength
            )
            let growthScale = min(max(outwardGrowthScale?(angle) ?? 1, 0), 1)
            let scaledTickLength = Styling.tickLength
                + ((tickLength - Styling.tickLength) * growthScale)
            let innerTickLength = growsOutward ? Styling.tickLength / 2 : scaledTickLength / 2
            let outerTickLength = growsOutward
                ? scaledTickLength - innerTickLength
                : scaledTickLength / 2
            let startPoint = CGPoint(
                x: tickCenter.x - unitNormal.dx * innerTickLength,
                y: tickCenter.y - unitNormal.dy * innerTickLength
            )
            let endPoint = CGPoint(
                x: tickCenter.x + unitNormal.dx * outerTickLength,
                y: tickCenter.y + unitNormal.dy * outerTickLength
            )

            body(angle, startPoint, endPoint)
        }
    }

    private func isTickInTargetHalf(at angle: CGFloat) -> Bool {
        switch captureGuideTarget {
        case .none:
            return false
        case .left:
            return angle >= .pi * 0.5 && angle <= .pi * 1.5
        case .right:
            return angle <= .pi * 0.5 || angle >= .pi * 1.5
        }
    }

    private func isTickRevealedByProgress(at angle: CGFloat) -> Bool {
        guard isTickInTargetHalf(at: angle) else {
            return false
        }

        let centerAngle: CGFloat
        switch captureGuideTarget {
        case .none:
            return false
        case .left:
            centerAngle = .pi
        case .right:
            centerAngle = 0
        }

        let angularDistance = abs(atan2(sin(angle - centerAngle), cos(angle - centerAngle)))
        let hiddenAngle = (1 - displayedTargetProgress) * .pi * 0.5
        return angularDistance >= hiddenAngle && angularDistance <= .pi * 0.5
    }

    private func baseTickColor(at angle: CGFloat) -> UIColor {
        return Styling.tickColor.withAlphaComponent(
            Styling.tickColor.cgColor.alpha * baseTickOpacity(at: angle)
        )
    }

    private func baseTickOpacity(at angle: CGFloat) -> CGFloat {
        guard uses3DCaptureAnimations,
            let oppositeSideAngle = oppositeSideAngleForBaseFade()
        else {
            return 1
        }

        let oppositeSideAlignment = max(0, cos(angle - oppositeSideAngle))
        let oppositeSideFadeStrength = pow(
            oppositeSideAlignment,
            Styling.baseTickOppositeSideFadeExponent
        )
        let fadedOpacity = 1
            - ((1 - Styling.baseTickOppositeSideMinOpacityMultiplier) * oppositeSideFadeStrength)
        return baseTickFadeProgress * fadedOpacity
    }

    private func oppositeSideAngleForBaseFade() -> CGFloat? {
        switch captureGuideTarget {
        case .none:
            return nil
        case .left:
            return 0
        case .right:
            return .pi
        }
    }

    private func shouldDrawBaseTick(at angle: CGFloat) -> Bool {
        return !isTickCoveredByAcceptedState(at: angle)
    }

    private func shouldDrawDirectionalPulseTick(at angle: CGFloat) -> Bool {
        return isTickInTargetHalf(at: angle) && !isTickCoveredByAcceptedState(at: angle)
    }

    private func isTickCoveredByAcceptedState(at angle: CGFloat) -> Bool {
        let isAcceptedTargetTick = uses3DCaptureAnimations
            && captureGuideTarget != .none
            && displayedTargetProgress > 0
            && isTickRevealedByProgress(at: angle)
        let isAcceptedHighlightTick = captureGuideHighlight != .none
            && highlightedTickProgress > 0
            && highlightedTickOpacity > 0
            && isTickHighlighted(at: angle)
        return isAcceptedTargetTick || isAcceptedHighlightTick
    }

    private func isTickHighlighted(at angle: CGFloat) -> Bool {
        switch captureGuideHighlight {
        case .none:
            return false
        case .front:
            return true
        case .left:
            return angle > .pi * 0.5 && angle < .pi * 1.5
        case .right:
            return angle < .pi * 0.5 || angle > .pi * 1.5
        }
    }

    private func drawCenteredShadow(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        opacity: CGFloat
    ) {
        let scaleX = horizontalRadius / verticalRadius
        let maxXDistance = max(center.x, bounds.width - center.x) / scaleX
        let maxYDistance = max(center.y, bounds.height - center.y)
        let outerRadius = hypot(maxXDistance, maxYDistance)
        let clearRadius = verticalRadius + Styling.centeredShadowClearPadding
        guard outerRadius > clearRadius else {
            return
        }

        let gradientSteps = max(Styling.centeredShadowGradientStepCount, 2)
        let denominator = CGFloat(gradientSteps - 1)
        let colors = (0..<gradientSteps).map { index -> CGColor in
            let progress = CGFloat(index) / denominator
            let smoothProgress = progress * progress * (3 - (2 * progress))
            let alpha = Styling.centeredShadowOuterOpacity * smoothProgress * opacity
            return UIColor.black.withAlphaComponent(alpha).cgColor
        } as CFArray
        let locations = (0..<gradientSteps).map { index in
            CGFloat(index) / denominator
        }

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) else {
            return
        }

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scaleX, y: 1)
        context.drawRadialGradient(
            gradient,
            startCenter: .zero,
            startRadius: clearRadius,
            endCenter: .zero,
            endRadius: outerRadius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }
}

private final class CaptureSuccessCheckmarkView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: bounds.insetBy(dx: 1, dy: 1))

        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to: CGPoint(x: bounds.width * 0.31, y: bounds.height * 0.52))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * 0.44, y: bounds.height * 0.65))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * 0.70, y: bounds.height * 0.38))
        checkmarkPath.lineCapStyle = .round
        checkmarkPath.lineJoinStyle = .round
        checkmarkPath.lineWidth = 2.6
        context.setBlendMode(.clear)
        UIColor.white.setStroke()
        checkmarkPath.stroke()
    }
}

