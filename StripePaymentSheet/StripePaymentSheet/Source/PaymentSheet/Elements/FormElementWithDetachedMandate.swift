//
//  FormElementWithDetachedMandate.swift
//  StripePaymentSheet
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore


class FormElementWithDetachedMandate: PaymentMethodElement{

    var delegate: ElementDelegate? {
        get {
            return formElement.delegate
        }
        set {
            formElement.delegate = newValue
        }
    }
    var view: UIView {
        return formElement.view
    }
    var collectsUserInput: Bool {
        return formElement.collectsUserInput
    }

    let formElement: FormElement
    let detachedMandate: String?
    let theme: ElementsUITheme
    init(formElement: FormElement, theme: ElementsUITheme, detachedMandate: String?) {
        self.formElement = formElement
        self.theme = theme
        self.detachedMandate = detachedMandate
    }

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return self.formElement.updateParams(params: params)
    }

}

extension FormElementWithDetachedMandate : MandateDetachable {
    func mandateString() -> NSAttributedString? {
        guard let detachedMandate else {
            return nil
        }
        let formattedString = NSMutableAttributedString(string: detachedMandate)
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        formattedString.addAttributes([.paragraphStyle: style,
                                       .font: theme.fonts.caption,
                                       .foregroundColor: theme.colors.secondaryText,
                                      ],
                                      range: NSRange(location: 0, length: formattedString.length))
        return formattedString
    }
}
