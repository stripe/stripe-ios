//
//  CardScanningView.swift
//  StripeiOS
//
//  Created by David Estes on 12/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

private class CardScanningEasilyTappableButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = bounds.insetBy(
            dx: -(PaymentSheetUI.minimumTapSize.width - bounds.width) / 2,
            dy: -(PaymentSheetUI.minimumTapSize.height - bounds.height) / 2)
        return newArea.contains(point)
    }
}

@available(iOS 13, macCatalyst 14, *)
@objc protocol CardScanningViewDelegate: NSObjectProtocol {
    func cardScanningView(
        _ cardScanningView: CardScanningView, didFinishWith cardParams: STPPaymentMethodCardParams?)
}

@available(iOS 13, macCatalyst 14, *)
class CardScanningView: UIView, STPCardScannerDelegate {
    private(set) weak var cameraView: STPCameraView?

    weak var delegate: CardScanningViewDelegate?

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

    func cardScanner(
        _ scanner: STPCardScanner, didFinishWith cardParams: STPPaymentMethodCardParams?,
        error: Error?
    ) {
        if error != nil {
            self.isDisplayingError = true
        } else {
            self.delegate?.cardScanningView(self, didFinishWith: cardParams)
        }
    }

    private lazy var cardScanner: STPCardScanner? = nil

    private static let cardSizeRatio: CGFloat = 2.125 / 3.370  // ID-1 card size (in inches)
    private static let cardCornerRadius: CGFloat = 0.125 / 3.370  // radius / ID-1 card width
    private static let cornerRadius: CGFloat = 4
    private static let cardInset: CGFloat = 32
    private static let textInset: CGFloat = 14

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
        label.text = STPLocalizedString(
            "To scan your card, allow camera access in Settings.",
            "Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."
        )
        label.textAlignment = .center
        label.numberOfLines = 3
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.isHidden = true
        return label
    }()

    private lazy var closeButton: CircularButton = {
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

    func start() {
        cardScanner?.start()
    }

    func stop() {
        if isDisplayingError {
            self.delegate?.cardScanningView(self, didFinishWith: nil)
        }
        cardScanner?.stop()
    }

    @objc private func closeTapped() {
        self.stop()
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

        self.layer.cornerRadius = CardScanningView.cornerRadius
        self.cameraView = cameraView
        cameraView.layer.cornerRadius = CardScanningView.cornerRadius
        self.cameraView?.translatesAutoresizingMaskIntoConstraints = false
        // The first few frames of the camera view will be black, so our background should be black too.
        self.cameraView?.backgroundColor = UIColor.black
        self.addConstraints(
            [
                cameraView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
                cameraView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
                cameraView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
                cameraView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),

                cardOuterBlurView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                cardOuterBlurView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
                cardOuterBlurView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
                cardOuterBlurView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),

                errorLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
                errorLabel.leftAnchor.constraint(equalTo: cardOutlineView.leftAnchor, constant: 8),
                errorLabel.rightAnchor.constraint(
                    equalTo: cardOutlineView.rightAnchor, constant: -8),

                closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                closeButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),

                cardOutlineView.heightAnchor.constraint(
                    equalTo: cardOutlineView.widthAnchor, multiplier: CardScanningView.cardSizeRatio
                ),

                cardOutlineView.topAnchor.constraint(
                    equalTo: self.topAnchor, constant: CardScanningView.cardInset),
                cardOutlineView.leftAnchor.constraint(
                    equalTo: self.leftAnchor, constant: CardScanningView.cardInset),
                cardOutlineView.rightAnchor.constraint(
                    equalTo: self.rightAnchor, constant: -CardScanningView.cardInset),
                cardOutlineView.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor, constant: -CardScanningView.cardInset),
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
