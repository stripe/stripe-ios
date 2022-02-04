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

    weak var delegate: ElementDelegate? {
        get {
            phoneNumberElement.delegate
        }
        set {
            phoneNumberElement.delegate = newValue
        }
    }

    private let phoneNumberElement: PhoneNumberElement

    lazy var view: UIView = {
        return FormView(viewModel: .init(elements: [phoneNumberElement.view], bordered: true))
    }()

    public var phoneNumber: PhoneNumber? {
        return phoneNumberElement.phoneNumber
    }

    init() {
        phoneNumberElement = PhoneNumberElement()
    }

}
