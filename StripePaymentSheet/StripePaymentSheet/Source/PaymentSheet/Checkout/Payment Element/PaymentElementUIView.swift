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

    override public var intrinsicContentSize: CGSize {
        return fittingSize(width: bounds.width)
    }

    override public func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return fittingSize(width: targetSize.width)
    }

    override public func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        return fittingSize(width: targetSize.width, horizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func fittingSize(
        width: CGFloat,
        horizontalFittingPriority: UILayoutPriority = .required,
        verticalFittingPriority: UILayoutPriority = .fittingSizeLevel
    ) -> CGSize {
        let fittingWidth = width > 0 ? width : bounds.width
        guard fittingWidth > 0 else {
            return UIView.layoutFittingCompressedSize
        }
        return contentView.systemLayoutSizeFitting(
            CGSize(width: fittingWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
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
