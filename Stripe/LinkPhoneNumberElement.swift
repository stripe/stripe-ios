//
//  LinkPhoneNumberElement.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
//
import UIKit
@_spi(STP) import StripeUICore

class LinkPhoneNumberElement: Element {

    weak var delegate: ElementDelegate?

    private let phoneNumberElement: PhoneNumberElement

    lazy var view: UIView = {
        return FormView(viewModel: .init(elements: [phoneNumberElement.view], bordered: true))
    }()

    public var phoneNumber: PhoneNumber? {
        return phoneNumberElement.phoneNumber
    }

    init() {
        phoneNumberElement = PhoneNumberElement()
        phoneNumberElement.delegate = self
    }

}

extension LinkPhoneNumberElement: ElementDelegate {

    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func didFinishEditing(element: Element) {
        delegate?.didFinishEditing(element: self)
    }

}
