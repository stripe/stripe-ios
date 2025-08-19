//
//  CardScanningView.swift
//  StripePaymentSheet
//
//  Created by David Estes on 12/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

private class CardScanningEasilyTappableButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = bounds.insetBy(
            dx: -(PaymentSheetUI.minimumTapSize.width - bounds.width) / 2,
            dy: -(PaymentSheetUI.minimumTapSize.height - bounds.height) / 2)
        return newArea.contains(point)
    }
}

/// For internal SDK use only
@available(macCatalyst 14.0, *)
protocol STP_Internal_CardScanningViewDelegate: AnyObject {
    func cardScanningViewShouldClose(_ cardScanningView: CardScanningView, cardParams: STPPaymentMethodCardParams?)
}

/// For internal SDK use only
@available(macCatalyst 14.0, *)
class CardScanningView: UIView {
    private(set) weak var cameraView: STPCameraView?

    weak var delegate: STP_Internal_CardScanningViewDelegate?

    var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            cardScanner?.deviceOrientation = deviceOrientation
        }
    }

    private var isDisplayingError = false {
        didSet {
            errorLabel.isHidden = !isDisplayingError
        }
    }

    private lazy var cardScanner: STPCardScanner? = nil

    private static let cardSizeRatio: CGFloat = 2.125 / 3.370  // ID-1 card size (in inches)
    private static let cardCornerRadius: CGFloat = 0.125 / 3.370  // radius / ID-1 card width
    private static let cornerRadius: CGFloat = 4
    private static let cardInset: CGFloat = 32
    private static let errorLabelInset: CGFloat = 8
    private static let closeButtonInset: CGFloat = 8

    private lazy var cardOutlineView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 3.0
        view.layer.borderColor = UIColor.white.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var blurEffect: UIBlurEffect = {
        return UIBlurEffect(style: .systemUltraThinMaterialDark)
    }()

    private lazy var cardOuterBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = String.Localized.allow_camera_access
        label.textAlignment = .center
        label.numberOfLines = 3
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.isHidden = true
        return label
    }()

    private lazy var closeButton: CircularButton = {
        // TODO(porter): Customize card scanning view?
        let button = CircularButton(style: .close)
        button.accessibilityLabel = STPLocalizedString(
            "Close card scanner", "Accessibility label for the button to close the card scanner.")
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private func setupBlurView() {
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false

        vibrancyEffectView.contentView.addSubview(instructionsLabel)
        cardOuterBlurView.contentView.addSubview(vibrancyEffectView)

        cardOuterBlurView.addConstraints([
            vibrancyEffectView.bottomAnchor.constraint(
                equalTo: cardOuterBlurView.bottomAnchor, constant: 0),
            vibrancyEffectView.leftAnchor.constraint(
                equalTo: cardOuterBlurView.leftAnchor, constant: 0),
            vibrancyEffectView.rightAnchor.constraint(
                equalTo: cardOuterBlurView.rightAnchor, constant: 0),
            vibrancyEffectView.topAnchor.constraint(
                equalTo: cardOuterBlurView.topAnchor, constant: 0),
        ])

        vibrancyEffectView.addConstraints([
            instructionsLabel.leftAnchor.constraint(
                equalTo: vibrancyEffectView.leftAnchor, constant: 0),
            instructionsLabel.rightAnchor.constraint(
                equalTo: vibrancyEffectView.rightAnchor, constant: 0),
        ])
    }

    func startScanner() {
        cardScanner?.start()
    }

    func stopAndCloseScanner() {
        cardScanner?.cancel()
        delegate?.cardScanningViewShouldClose(self, cardParams: nil)
    }

    @objc private func closeTapped() {
        stopAndCloseScanner()
    }

    var snapshotView: UIView?

    // The shape layers don't animate cleanly during setHidden,
    // so let's use a snapshot view instead.
    func prepDismissAnimation() {
        // If this is called twice for any reason, we need to prevent two snapshot views from being added
        guard snapshotView == nil else { return }

        if let snapshot = snapshotView(afterScreenUpdates: true) {
            self.addSubview(snapshot)
            self.snapshotView = snapshot
        }
    }

    func completeDismissAnimation() {
        snapshotView?.removeFromSuperview()
        snapshotView = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupBlurView()

        let cameraView = STPCameraView(frame: bounds)
        cameraView.isAccessibilityElement = true
        cameraView.accessibilityLabel = STPLocalizedString(
            "Point the camera at your card.", "Accessibility instructions for card scanning.")
        let cardScanner = STPCardScanner(delegate: self)
        cardScanner.cameraView = cameraView
        self.cardScanner = cardScanner

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        self.addSubview(cameraView)
        self.addSubview(cardOutlineView)
        self.addSubview(cardOuterBlurView)
        self.addSubview(errorLabel)
        self.addSubview(closeButton)

        self.layer.cornerRadius = Self.cornerRadius
        self.cameraView = cameraView
        cameraView.layer.cornerRadius = CardScanningView.cornerRadius
        self.cameraView?.translatesAutoresizingMaskIntoConstraints = false
        // The first few frames of the camera view will be black, so our background should be black too.
        self.cameraView?.backgroundColor = UIColor.black
        // To get the right animation, we'll add a breakable bottom constraint
        // and enable clipsToBounds. Then, when hidden, the view will shrink while
        // the contents remain pinned to the top.
        let bottomConstraints = [
            cameraView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            cardOuterBlurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            cardOutlineView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Self.cardInset),
        ]
        bottomConstraints.forEach {
            $0.priority = .defaultHigh
        }
        self.clipsToBounds = true
        self.addConstraints(bottomConstraints)

        self.addConstraints(
            [
                cameraView.leftAnchor.constraint(equalTo: self.leftAnchor),
                cameraView.rightAnchor.constraint(equalTo: self.rightAnchor),
                cameraView.topAnchor.constraint(equalTo: self.topAnchor),

                cardOuterBlurView.leftAnchor.constraint(equalTo: self.leftAnchor),
                cardOuterBlurView.rightAnchor.constraint(equalTo: self.rightAnchor),
                cardOuterBlurView.topAnchor.constraint(equalTo: self.topAnchor),

                errorLabel.leftAnchor.constraint(equalTo: cardOutlineView.leftAnchor, constant: Self.errorLabelInset),
                errorLabel.rightAnchor.constraint(
                    equalTo: cardOutlineView.rightAnchor, constant: -Self.errorLabelInset),
                errorLabel.centerYAnchor.constraint(equalTo: cardOutlineView.centerYAnchor),

                closeButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Self.closeButtonInset),
                closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: Self.closeButtonInset),

                cardOutlineView.heightAnchor.constraint(
                    equalTo: cardOutlineView.widthAnchor, multiplier: CardScanningView.cardSizeRatio),
                cardOutlineView.leftAnchor.constraint(
                    equalTo: self.leftAnchor, constant: CardScanningView.cardInset),
                cardOutlineView.rightAnchor.constraint(
                    equalTo: self.rightAnchor, constant: -CardScanningView.cardInset),
                cardOutlineView.topAnchor.constraint(
                    equalTo: self.topAnchor, constant: CardScanningView.cardInset),
            ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius =
        (self.bounds.size.width - (CardScanningView.cardInset * 2))
        * CardScanningView.cardCornerRadius
        cardOutlineView.layer.cornerRadius = cornerRadius

        let outerPath = UIBezierPath(
            roundedRect: CGRect(
                x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height),
            cornerRadius: CardScanningView.cornerRadius)
        let innerPath = UIBezierPath(roundedRect: cardOutlineView.frame, cornerRadius: cornerRadius)

        outerPath.append(innerPath)
        outerPath.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd

        cardOuterBlurView.layer.mask = maskLayer
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

@available(macCatalyst 14.0, *)
extension CardScanningView: STPCardScannerDelegate {

    func cardScanner(_ scanner: STPCardScanner, didCompleteWith cardParams: StripePayments.STPPaymentMethodCardParams) {
        delegate?.cardScanningViewShouldClose(self, cardParams: cardParams)
    }

    func cardScannerDidError(_ scanner: STPCardScanner) {
        isDisplayingError = true
    }
}
#endif
