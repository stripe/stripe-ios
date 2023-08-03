//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentCardTextFieldTest.swift
//  Stripe
//
//  Created by Jack Flintermann on 8/26/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import OCMock
import StripeCoreTestUtils
import UIKit
import XCTest

//delegate
var delegate = PaymentCardTextFieldBlockDelegate()
//delegate
var hasReturned = false
var didEnd = false
var delegate = PaymentCardTextFieldBlockDelegate()
//delegate
var hasReturned = false
var didEnd = false
var delegate = PaymentCardTextFieldBlockDelegate()
//delegate

extension STPPaymentCardTextField {
    weak var brandImageView: UIImageView?
    weak var numberField: STPFormTextField?
    weak var expirationField: STPFormTextField?
    weak var cvcField: STPFormTextField?
    weak var postalCodeField: STPFormTextField?
    private(set) weak var currentFirstResponderField: STPFormTextField?
    var viewModel: STPPaymentCardTextFieldViewModel?
    var focusedTextFieldForLayout: NSNumber?

    class func cvcImage(for cardBrand: STPCardBrand) -> UIImage? {
    }

    class func brandImage(for cardBrand: STPCardBrand) -> UIImage? {
    }
}

/// Class that implements STPPaymentCardTextFieldDelegate and uses a block for each delegate method.
class PaymentCardTextFieldBlockDelegate: NSObject, STPPaymentCardTextFieldDelegate {
    var didChange: ((STPPaymentCardTextField?) -> Void)?
    var willEndEditingForReturn: ((STPPaymentCardTextField?) -> Void)?
    var didEndEditing: ((STPPaymentCardTextField?) -> Void)?
    // add more properties for other delegate methods as this test needs them

    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField?) {
        if let didChange {
            didChange(textField)
        }
    }

    func paymentCardTextFieldWillEndEditing(forReturn textField: STPPaymentCardTextField?) {
        if let willEndEditingForReturn {
            willEndEditingForReturn(textField)
        }
    }

    func paymentCardTextFieldDidEndEditing(_ textField: STPPaymentCardTextField?) {
        if let didEndEditing {
            didEndEditing(textField)
        }
    }
}

class STPPaymentCardTextFieldTest: XCTestCase {
    override class func setUp() {
        super.setUp()
        STPAPIClient.shared().publishableKey = STPTestingDefaultPublishableKey
    }

    func testIntrinsicContentSize() {
        let textField = STPPaymentCardTextField()

        let iOS8SystemFont = UIFont(name: "HelveticaNeue", size: 18)
        textField.font = iOS8SystemFont
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1)
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 247, 0.1)

        let iOS9SystemFont = UIFont.systemFont(ofSize: 18)
        textField.font = iOS9SystemFont
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1)
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 259, 1.0)

        textField.font = UIFont(name: "Avenir", size: 44)
        if #available(iOS 13.0, *) {
            XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 62, 0.1)
        } else {
            XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 61, 0.1)
        }
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 478, 0.1)
    }

    func testSetCard_numberUnknown() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "1"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.unknown).pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
    }

    func testSetCard_expiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_CVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_updatesCVCValidity() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "378282246310005"
        sut.cvcField?.text = "1234"
        sut.expirationField?.text = "10/99"
        XCTAssertTrue(sut.cvcField?.validText)
        sut.numberField?.text = "4242424242424242"
        XCTAssertFalse(sut.cvcField?.validText)
    }

    func testSetCard_numberVisa() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.placeholder, "CVC")
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisaInvalid() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242111111111111"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.visa).pngData()

        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
    }

    func testSetCard_numberAmex() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.placeholder, "CVV")
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAmexInvalid() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246311111"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.amex).pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
    }

    func testSetCard_numberAndExpiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_partialNumberAndExpiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAndCVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246310005"
        let cvc = "123"
        card.number = number
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_expirationAndCVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_completeCardCountryWithoutPostal() {
        let sut = STPPaymentCardTextField()
        sut.countryCode = "BZ"
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCardNoPostal() {
        let sut = STPPaymentCardTextField()
        sut.postalCodeEntryEnabled = false
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCard() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address.postalCode = "90210"
        let params = STPPaymentMethodParams(card: card, billingDetails: billingDetails, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_empty() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        sut.cvcField?.text = "123"
        sut.expirationField?.text = "10/99"
        let card = STPPaymentMethodCardParams()
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated"

    //#pragma clang diagnostic pop

    func testSettingTextUpdatesViewModelText() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        XCTAssertEqual(sut.viewModel?.cardNumber, sut.numberField?.text)

        sut.cvcField?.text = "123"
        XCTAssertEqual(sut.viewModel?.cvc, sut.cvcField?.text)

        sut.expirationField?.text = "10/99"
        XCTAssertEqual(sut.viewModel?.rawExpiration, sut.expirationField?.text)
        XCTAssertEqual(sut.viewModel?.expirationMonth, "10")
        XCTAssertEqual(sut.viewModel?.expirationYear, "99")
    }

    func testSettingTextUpdatesCardParams() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        sut.cvcField?.text = "123"
        sut.expirationField?.text = "10/99"
        sut.postalCodeField?.text = "90210"

        let card = sut.paymentMethodParams.card
        XCTAssertNotNil(Int(card ?? 0))
        XCTAssertEqual(card?.number, "4242424242424242")
        XCTAssertEqual(card?.cvc, "123")
        XCTAssertEqual(card?.expMonth.intValue ?? 0, 10)
        XCTAssertEqual(card?.expYear.intValue ?? 0, 99)
        XCTAssertEqual(sut.paymentMethodParams.billingDetails.address.postalCode, "90210")
    }

    func testSettingBillingDetailsRetainsBillingDetails() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Test test"

        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: billingDetails, metadata: nil)
        let actual = sut.paymentMethodParams

        XCTAssertEqual("Test test", actual?.billingDetails.name)
    }

    func testSettingMetadataRetainsMetadata() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()
        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: [
            "hello": "test"
        ])
        let actual = sut.paymentMethodParams

        XCTAssertEqual([
            "hello": "test"
        ], actual?.metadata)
    }

    func testSettingPostalCodeUpdatesCardParams() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        sut.cvcField?.text = "123"
        sut.expirationField?.text = "10/99"
        sut.postalCodeField?.text = "90210"

        let params = sut.paymentMethodParams.card
        XCTAssertNotNil(Int(params ?? 0))
        XCTAssertEqual(params?.number, "4242424242424242")
        XCTAssertEqual(params?.cvc, "123")
        XCTAssertEqual(params?.expMonth.intValue ?? 0, 10)
        XCTAssertEqual(params?.expYear.intValue ?? 0, 99)
    }

    func testEmptyPostalCodeVendsNilAddress() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        sut.cvcField?.text = "123"
        sut.expirationField?.text = "10/99"

        XCTAssertNil(sut.paymentMethodParams.billingDetails.address.postalCode)
        let params = sut.paymentMethodParams.card
        XCTAssertNotNil(Int(params ?? 0))
        XCTAssertEqual(params?.number, "4242424242424242")
        XCTAssertEqual(params?.cvc, "123")
        XCTAssertEqual(params?.expMonth.intValue ?? 0, 10)
        XCTAssertEqual(params?.expYear.intValue ?? 0, 99)
    }

    func testAccessingCardParamsDuringSettingCardParams() {
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.didChange = { textField in
            // delegate reads the `cardParams` for any reason it wants
            textField?.paymentMethodParams().card()
        }
        let sut = STPPaymentCardTextField()
        sut.delegate = delegate

        let params = STPPaymentMethodCardParams()
        params.number = "4242424242424242"
        params.cvc = "123"

        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: nil)
        let actual = sut.paymentMethodParams.card

        XCTAssertEqual("4242424242424242", actual?.number)
        XCTAssertEqual("123", actual?.cvc)
    }

    func testSetCardParamsCopiesObject() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()

        params.number = "4242424242424242" // legit
        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: nil)

        // fetching `sut.cardParams` returns a copy, so edits happen to caller's copy
        sut.paymentMethodParams.card.number = "number 1"

        // `sut` copied `params` (& `params.address`) when set, so edits to original don't show up
        params.number = "number 2"

        XCTAssertEqual("4242424242424242", sut.paymentMethodParams.card.number)

        XCTAssertNotEqualObjects("number 1", sut.paymentMethodParams.card.number, "return value from cardParams cannot be edited inline")

        XCTAssertNotEqualObjects("number 2", sut.paymentMethodParams.card.number, "caller changed their copy after setCardParams:")
    }

    // MARK: - paymentMethodParams

    func testSetCard_numberUnknown_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "1"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.unknown).pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
    }

    func testSetCard_expiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_CVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisa_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.placeholder, "CVC")
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisaInvalid_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242111111111111"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.visa).pngData()

        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
    }

    func testSetCard_numberAmex_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.placeholder, "CVV")
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAmexInvalid_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246311111"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: STPCardBrand.amex).pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
    }

    func testSetCard_numberAndExpiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_partialNumberAndExpiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAndCVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246310005"
        let cvc = "123"
        card.number = number
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_expirationAndCVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_completeCardCountryWithoutPostal_pm() {
        let sut = STPPaymentCardTextField()
        sut.countryCode = "BZ"
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCardNoPostal_pm() {
        let sut = STPPaymentCardTextField()
        sut.postalCodeEntryEnabled = false
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCard_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: STPPaymentMethodBillingDetails(postalCode: "90210", countryCode: "US"), metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text, number)
        XCTAssertEqual(sut.expirationField?.text, "10/99")
        XCTAssertEqual(sut.cvcField?.text, cvc)
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        let isvalid = sut.isValid
        XCTAssertTrue(isvalid)


        let paymentMethodParams = sut.paymentMethodParams
        XCTAssertNotNil(Int(paymentMethodParams ?? 0))

        let sutCardParams = paymentMethodParams?.card
        XCTAssertNotNil(Int(sutCardParams ?? 0))

        XCTAssertEqual(sutCardParams?.number, card.number)
        XCTAssertEqual(sutCardParams?.expMonth, card.expMonth)
        XCTAssertEqual(sutCardParams?.expYear, card.expYear)
        XCTAssertEqual(sutCardParams?.cvc, card.cvc)

        let sutBillingDetails = paymentMethodParams?.billingDetails
        XCTAssertNotNil(Int(sutBillingDetails ?? 0))

        let sutAddress = sutBillingDetails?.address
        XCTAssertNotNil(Int(sutAddress ?? 0))

        XCTAssertEqual(sutAddress?.postalCode, "90210")
        XCTAssertEqual(sutAddress?.country, "US")
    }

    func testSetCard_empty_pm() {
        let sut = STPPaymentCardTextField()
        sut.numberField?.text = "4242424242424242"
        sut.cvcField?.text = "123"
        sut.expirationField?.text = "10/99"
        let card = STPPaymentMethodCardParams()
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut.cvcField?.text.length ?? 0, Int(0))
        XCTAssertNil(Int(sut.currentFirstResponderField ?? 0))
        XCTAssertFalse(sut.isValid)
    }
}

// N.B. It is eexpected for setting the card params to generate API response errors
// because we are calling to the card metadata service without configuration STPAPIClient
class STPPaymentCardTextFieldUITests: XCTestCase {
    var window: UIWindow?
    var sut: STPPaymentCardTextField?

    override class func setUp() {
        super.setUp()
        STPAPIClient.shared().publishableKey = STPTestingDefaultPublishableKey
    }

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        let textField = STPPaymentCardTextField(frame: window?.bounds)
        window?.addSubview(textField)
        XCTAssertTrue(textField.numberField?.canBecomeFirstResponder(), "text field cannot become first responder")
        sut = textField
    }

    // MARK: - UI Tests

    func testSetCard_allFields_whileEditingNumber() {
        XCTAssertTrue(sut?.numberField?.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address.postalCode = "90210"
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        card.cvc = cvc
        sut?.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: billingDetails, metadata: nil)

        let imgData = sut?.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNil(Int(truncating: sut?.focusedTextFieldForLayout ?? 0))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut?.numberField?.text, number)
        XCTAssertEqual(sut?.expirationField?.text, "10/99")
        XCTAssertEqual(sut?.cvcField?.text, cvc)
        XCTAssertEqual(sut?.postalCode, "90210")
        XCTAssertFalse(sut?.isFirstResponder(), "after `setCardParams:`, if all fields are valid, should resign firstResponder")
        XCTAssertTrue(sut?.isValid)
    }

    func testSetCard_partialNumberAndExpiration_whileEditingExpiration() {
        XCTAssertTrue(sut?.expirationField?.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let number = "42"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 99)
        sut?.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut?.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.cvcImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut?.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut?.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeCVC))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut?.numberField?.text, number)
        XCTAssertEqual(sut?.expirationField?.text, "10/99")
        XCTAssertEqual(sut?.cvcField?.text.length ?? 0, Int(0))
        XCTAssertTrue(sut?.cvcField?.isFirstResponder(), "after `setCardParams:`, when firstResponder becomes valid, first invalid field should become firstResponder")
        XCTAssertFalse(sut?.isValid)
    }

    func testSetCard_number_whileEditingCVC() {
        XCTAssertTrue(sut?.cvcField?.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        sut?.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut?.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.cvcImage(for: .visa)?.pngData()

        XCTAssertNotNil(Int(truncating: sut?.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut?.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeCVC))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut?.numberField?.text, number)
        XCTAssertEqual(sut?.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut?.cvcField?.text.length ?? 0, Int(0))
        XCTAssertTrue(sut?.cvcField?.isFirstResponder(), "after `setCardParams:`, if firstResponder is invalid, it should remain firstResponder")
        XCTAssertFalse(sut?.isValid)
    }

    func testSetCard_empty_whileEditingNumber() {
        sut?.numberField?.text = "4242424242424242"
        sut?.cvcField?.text = "123"
        sut?.expirationField?.text = "10/99"
        XCTAssertTrue(sut?.numberField?.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        sut?.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut?.brandImageView?.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(Int(truncating: sut?.focusedTextFieldForLayout ?? 0))
        XCTAssertTrue(sut?.focusedTextFieldForLayout?.intValue ?? 0 == Int(STPCardFieldTypeNumber))
        if let imgData {
            XCTAssertTrue(expectedImgData?.isEqual(to: imgData))
        }
        XCTAssertEqual(sut?.numberField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut?.expirationField?.text.length ?? 0, Int(0))
        XCTAssertEqual(sut?.cvcField?.text.length ?? 0, Int(0))
        XCTAssertTrue(sut?.numberField?.isFirstResponder(), "after `setCardParams:` that clears the text fields, the first invalid field should become firstResponder")
        XCTAssertFalse(sut?.isValid)
    }

    func testIsValidKVO() {
        let observer = OCMClassMock(UIViewController.self)
        sut?.numberField?.text = "4242424242424242"
        sut?.expirationField?.text = "10/99"
        sut?.postalCodeField?.text = "90210"
        XCTAssertFalse(sut?.isValid)

        let expectedKeyPath = "sut.isValid"
        if let observer = observer as? NSObject {
            addObserver(observer, forKeyPath: expectedKeyPath, options: .new, context: nil)
        }
        let exp = expectation(description: "observeValue")
        OCMStub(observer?.observeValue(forKeyPath: OCMArg.any(), of: OCMArg.any(), change: OCMArg.any(), context: nil)).andDo(
            { [self] invocation in
                        var keyPath: String?
                        var change: [AnyHashable : Any]?
                        invocation?.getArgument(&keyPath, atIndex: 2)
                        invocation?.getArgument(&change, atIndex: 4)
                        if keyPath == expectedKeyPath {
                            if (change?["new"] as? NSNumber)?.boolValue ?? false {
                                exp.fulfill()
                                removeObserver(observer, forKeyPath: "sut.isValid")
                            }
                        }
                    })

        sut?.cvcField?.text = "123"

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testBecomeFirstResponder() {
        sut?.postalCodeEntryEnabled = false
        XCTAssertTrue(sut?.canBecomeFirstResponder())
        XCTAssertTrue(sut?.becomeFirstResponder())
        XCTAssertTrue(sut?.isFirstResponder)

        XCTAssertEqual(Int(sut?.numberField ?? 0), Int(sut?.currentFirstResponderField ?? 0))

        sut?.becomeFirstResponder()
        XCTAssertEqual(
            Int(sut?.numberField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        sut?.numberField?.text = """
            4242\
            4242\
            4242\
            4242
            """

        // Don't unit test auto-advance from number field here because we don't know the cache state

        XCTAssertTrue(sut?.cvcField?.becomeFirstResponder())
        XCTAssertEqual(
            Int(sut?.cvcField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        XCTAssertTrue(sut?.becomeFirstResponder())
        XCTAssertEqual(
            Int(sut?.cvcField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        sut?.expirationField?.text = "10/99"
        sut?.cvcField?.text = "123"

        sut?.resignFirstResponder()
        XCTAssertTrue(sut?.canBecomeFirstResponder())
        XCTAssertTrue(sut?.becomeFirstResponder())

        XCTAssertEqual(
            Int(sut?.cvcField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        sut?.postalCodeEntryEnabled = true
        XCTAssertFalse(sut?.isValid)

        sut?.resignFirstResponder()
        XCTAssertTrue(sut?.becomeFirstResponder())
        XCTAssertEqual(
            Int(sut?.postalCodeField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        sut?.expirationField?.text = ""
        sut?.resignFirstResponder()
        XCTAssertTrue(sut?.becomeFirstResponder())
        XCTAssertEqual(
            Int(sut?.expirationField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))

        sut?.expirationField?.text = "10/99"
        sut?.postalCodeField?.text = "90210"

        sut?.resignFirstResponder()
        XCTAssertTrue(sut?.becomeFirstResponder())
        XCTAssertEqual(
            Int(sut?.postalCodeField ?? 0),
            Int(sut?.currentFirstResponderField ?? 0))
    }

    func testShouldReturnCyclesThroughFields() {
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.willEndEditingForReturn = 
    }
}