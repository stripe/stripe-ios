//
//  IdealDetailsEditView.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 2/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

final class IdealDetailsEditView: UIView {
    // Saving payment method for iDEAL isn't supported
    let shouldSavePaymentMethod = false

    weak var delegate: ElementDelegate?

    lazy var formView: STPiDEALFormView = {
        let formView = STPiDEALFormView()
        formView.internalDelegate = self
        return formView
    }()

    // TODO(mludowise|MOBILESDK-161): Add Billing Address and a
    // `PaymentSheet.BillingAddressCollectionLevel` parameter to init
    init() {
        super.init(frame: .zero)
        setupViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - AddPaymentMethodView

    func setErrorIfNecessary(for apiError: Error) -> Bool {
        return formView.markFormErrors(for: apiError)
    }

    // MARK: - UIView Overrides

    override var isUserInteractionEnabled: Bool {
        didSet {
            formView.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }
}

// MARK: - Private Helpers

extension IdealDetailsEditView {
    fileprivate func setupViews() {
        addSubview(formView)
    }

    fileprivate func installConstraints() {
        formView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formView.leadingAnchor.constraint(equalTo: leadingAnchor),
            formView.trailingAnchor.constraint(equalTo: trailingAnchor),
            formView.topAnchor.constraint(equalTo: topAnchor),
            formView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

// MARK: - STPFormViewDelegate

/// :nodoc:
extension IdealDetailsEditView: STPFormViewInternalDelegate {
    func formView(_ form: STPFormView, didChangeToStateComplete complete: Bool) {
        delegate?.didUpdate(element: self)
    }

    func formViewWillBecomeFirstResponder(_ form: STPFormView) {}

    func formView(_ form: STPFormView, didTapAccessoryButton button: UIButton) {}
}

// MARK: - Element

/// :nodoc:
extension IdealDetailsEditView: Element {
    enum IdealDetailsEditViewError: ElementValidationStateError {
        case unknown
    }
    
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let iDEALParams = formView.iDEALParams {
            params.paymentMethodParams = iDEALParams
            return params
        } else {
            return nil
        }
    }
    
    var validationState: ElementValidationState {
        if formView.iDEALParams != nil {
            return .valid
        } else {
            return .invalid(IdealDetailsEditViewError.unknown)
        }
    }
    
    var view: UIView {
        return self
    }
}
