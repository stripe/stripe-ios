//
//  STPCardFormScannerView.swift
//  StripePaymentsUI
//
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import AVFoundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// `STPCardFormScannerView ` provides a multiline interface for users to input their
/// credit card details as well as billing postal code and provides an interface to access
/// the created `STPPaymentMethodParams`.
/// `STPCardFormView` includes both the input fields as well as an error label that
/// is displayed when invalid input is detected.
public class STPCardFormScannerView: STPCardFormView, STPCardScannerDelegate {
    @available(macCatalyst 14.0, *) private var cardScanner: STPCardScanner? {
        get {
            _cardScanner as? STPCardScanner
        }
        set {
            _cardScanner = newValue
        }
    }

    /// Storage for `cardScanner`.
    private var _cardScanner: NSObject?
    private(set) weak var cameraView: STPCameraView?

    private var scannerCompleteAnimationTimer: Timer?
    private static let cardScannerKSTPCardScanAnimationTime: TimeInterval = 0.04
    private static let cardSizeRatio: CGFloat = 2.125 / 3.370 // ID-1 card size (in inches)
    private var _isScanning = false
    private var isScanning: Bool {
        get {
            _isScanning
        }
        set(isScanning) {
            if _isScanning == isScanning {
                return
            }
            _isScanning = isScanning
            switch _isScanning {
            case true:
                showCardScanner()
                cardScanner?.start()
            case false:
                hideCardScanner()
                cardScanner?.stop()
            }
        }
    }

    private var handleError: ((_ error: Error?) -> Void)?
    private lazy var hideHeightConstraint = cameraView?.heightAnchor
        .constraint(equalToConstant: 0) ?? NSLayoutConstraint()
    private lazy var showHeightConstraint = cameraView?.heightAnchor.constraint(
        equalTo: cameraView?.widthAnchor ?? NSLayoutDimension(),
        multiplier: STPCardFormScannerView.cardSizeRatio
    ) ?? NSLayoutConstraint()
    private var sectionAccessoryButton: UIButton?

    @objc public convenience init(
        style: STPCardFormViewStyle = .standard
    ) {
        self.init(
            billingAddressCollection: .automatic,
            style: style,
            prefillDetails: nil
        )
    }

    @_spi(STP) public convenience init(
        billingAddressCollection: BillingAddressCollectionLevel,
        style: STPCardFormViewStyle = .standard,
        postalCodeRequirement: STPPostalCodeRequirement = .standard,
        prefillDetails: PrefillDetails? = nil,
        inputMode: STPCardNumberInputTextField.InputMode = .standard,
        cbcEnabledOverride: Bool? = nil,
        sectionTitle: String? = nil,
        sectionAccessoryButton: UIButton? = nil
    ) {
        self.init(
            numberField: STPCardNumberInputTextField(
                inputMode: inputMode,
                prefillDetails: prefillDetails,
                cbcEnabledOverride: cbcEnabledOverride
            ),
            cvcField: STPCardCVCInputTextField(prefillDetails: prefillDetails),
            expiryField: STPCardExpiryInputTextField(prefillDetails: prefillDetails),
            billingAddressSubForm: BillingAddressSubForm(
                billingAddressCollection: billingAddressCollection,
                postalCodeRequirement: postalCodeRequirement
            ),
            style: style,
            postalCodeRequirement: postalCodeRequirement,
            prefillDetails: prefillDetails,
            inputMode: inputMode,
            sectionTitle: sectionTitle,
            sectionAccessoryButton: sectionAccessoryButton
        )
    }

    required init(
        numberField: STPCardNumberInputTextField,
        cvcField: STPCardCVCInputTextField,
        expiryField: STPCardExpiryInputTextField,
        billingAddressSubForm: BillingAddressSubForm,
        style: STPCardFormViewStyle = .standard,
        postalCodeRequirement: STPPostalCodeRequirement = .standard,
        prefillDetails: PrefillDetails? = nil,
        inputMode: STPCardNumberInputTextField.InputMode = .standard,
        sectionTitle: String? = nil,
        sectionAccessoryButton: UIButton? = nil
    ) {
        Self.stp_analyticsIdentifier = "STPCardFormScannerView"

        let sectionAccessoryButton = UIButton(type: .system)

        super.init(
            numberField: numberField,
            cvcField: cvcField,
            expiryField: expiryField,
            billingAddressSubForm: billingAddressSubForm,
            style: style,
            postalCodeRequirement: postalCodeRequirement,
            prefillDetails: prefillDetails,
            inputMode: inputMode,
            sectionTitle: sectionTitle,
            sectionAccessoryButton: sectionAccessoryButton
        )
        cardScanner = cardScanner
        handleError = nil
        self.sectionAccessoryButton = sectionAccessoryButton

        sectionAccessoryButton.contentHorizontalAlignment = .right
        sectionAccessoryButton.titleLabel?.numberOfLines = 0
        sectionAccessoryButton.titleLabel?.lineBreakMode = .byWordWrapping
        sectionAccessoryButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        sectionAccessoryButton.contentEdgeInsets = .zero
        sectionAccessoryButton.setTitle(
            String.Localized.scan_card_title_capitalization,
            for: .normal
        )
        sectionAccessoryButton.addTarget(self, action: #selector(toggleScanCard), for: .touchUpInside)

        numberField.addTarget(self, action: #selector(didTapFieldGesture), for: .touchDown)
        expiryField.addTarget(self, action: #selector(didTapFieldGesture), for: .touchDown)
        cvcField.addTarget(self, action: #selector(didTapFieldGesture), for: .touchDown)
        countryField.addTarget(self, action: #selector(didTapFieldGesture), for: .touchDown)
        postalCodeField.addTarget(self, action: #selector(didTapFieldGesture), for: .touchDown)

        let cameraView = STPCameraView(frame: .zero)
        vStack.distribution = .equalCentering
        vStack.addArrangedSubview(cameraView)
        self.cameraView = cameraView
        self.cameraView?.backgroundColor = UIColor.black
        self.cameraView?.translatesAutoresizingMaskIntoConstraints = false
        cameraView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addConstraints(
            [
                showHeightConstraint,
                hideHeightConstraint,
                cameraView.widthAnchor.constraint(equalTo: widthAnchor),
            ]
        )
        showHeightConstraint.isActive = false
        hideHeightConstraint.isActive = true
        setUpCardScanningIfAvailable()
    }

    /// Public initializer for `STPCardFormScannerView`.
    /// @param style The visual style to use for this instance. @see STPCardFormViewStyle
    @objc public convenience init(
        _ cardScanner: STPCardScanner? = nil,
        style: STPCardFormViewStyle = .standard,
        handleError: ((_ error: Error?) -> Void)?
    ) {
        self.init(
            billingAddressCollection: .automatic,
            style: style,
            prefillDetails: nil,
            sectionTitle: STPPaymentMethodType.card.displayName
        )
        self.cardScanner = cardScanner
        self.handleError = nil
    }

    @available(*, unavailable) required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        sections: [Section]
    ) {
        fatalError("init(sections:) has not been implemented")
    }

    @objc private func didTapFieldGesture() {
        stopScanCard()
    }

    func setUpCardScanningIfAvailable() {
        if #available(macCatalyst 14.0, *) {
            if !STPCardScanner.cardScanningAvailable {
                return
            }
            let cardScanner = STPCardScanner(delegate: self)
            cardScanner.cameraView = cameraView
            self.cardScanner = (self.cardScanner == nil) ? cardScanner : nil
        }
    }

    @available(macCatalyst 14.0, *)
    @objc func toggleScanCard() {
        isScanning.toggle()
    }

    @available(macCatalyst 14.0, *)
    @objc func startScanCard() {
        isScanning = true
    }

    @available(macCatalyst 14.0, *)
    @objc func stopScanCard() {
        isScanning = false
    }

    private func showCardScanner() {
        DispatchQueue.main.async {
            NSLayoutConstraint.deactivate([self.hideHeightConstraint])
            NSLayoutConstraint.activate([self.showHeightConstraint])
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
        sectionAccessoryButton?.setTitle(
            String.Localized.close,
            for: .normal
        )
        endEditing(true)
    }

    private func hideCardScanner() {
        DispatchQueue.main.async {
            NSLayoutConstraint.deactivate([self.showHeightConstraint])
            NSLayoutConstraint.activate([self.hideHeightConstraint])
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
        sectionAccessoryButton?.setTitle(
            String.Localized.scan_card_title_capitalization,
            for: .normal
        )
    }

    // MARK: - STPCardScanner

    /// :nodoc:
    @available(macCatalyst 14.0, *) public func cardScanner(
        _ scanner: STPCardScanner,
        didFinishWith cardParams: STPPaymentMethodCardParams?,
        error: Error?
    ) {
        if error != nil {
            isScanning = false
            handleError?(error)
        }
        if let cardParams {
            isUserInteractionEnabled = false
            var i = 0
            scannerCompleteAnimationTimer = Timer.scheduledTimer(
                withTimeInterval: Self.cardScannerKSTPCardScanAnimationTime,
                repeats: true,
                block: { timer in
                    i += 1
                    let newParams = STPPaymentMethodCardParams()
                    guard let number = cardParams.number else {
                        timer.invalidate()
                        self.isUserInteractionEnabled = false
                        return
                    }
                    if i < number.count {
                        newParams.number = String(
                            number[...number.index(number.startIndex, offsetBy: i)]
                        )
                    } else {
                        newParams.number = number
                    }
                    self.cardParams = STPPaymentMethodParams(
                        card: newParams,
                        billingDetails: nil,
                        metadata: nil
                    )
                    if i > number.count {
                        self.cardParams =
                            STPPaymentMethodParams(
                                card: cardParams,
                                billingDetails: nil,
                                metadata: nil
                            )
                        self.isScanning = false
                        timer.invalidate()
                        self.isUserInteractionEnabled = true
                    }
                }
            )
        } else {
            isScanning = false
        }
    }
}
