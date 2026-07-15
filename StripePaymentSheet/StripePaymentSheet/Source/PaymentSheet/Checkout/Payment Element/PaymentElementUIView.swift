//
//  PaymentElementUIView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/13/26.
//

@_spi(STP) import StripeUICore
import UIKit

/// A view that displays payment methods.
@_spi(STP)
public final class PaymentElementUIView: UIView {
    /// A delegate for the view.
    public weak var delegate: PaymentElementViewDelegate?

    private let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        installContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - PaymentElementViewDelegate

    func embeddedPaymentElementDidUpdateHeight() {
        delegate?.paymentElementViewDidUpdateHeight(paymentElementView: self)
    }

    func embeddedPaymentElementWillPresent() {
        delegate?.paymentElementViewWillPresent(paymentElementView: self)
    }

    // MARK: - Internal Methods

    private func installContentView() {
        backgroundColor = .clear
        layoutMargins = .zero
        addAndPinSubview(contentView)
    }
}

@MainActor
@_spi(STP)
public protocol PaymentElementViewDelegate: AnyObject {
    /// Called inside an animation block when the PaymentElement view is updating its height.
    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView)

    /// Called immediately before the PaymentElement view presents.
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView)
}

public extension PaymentElementViewDelegate {
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView) {
        // Default implementation does nothing.
    }
}
