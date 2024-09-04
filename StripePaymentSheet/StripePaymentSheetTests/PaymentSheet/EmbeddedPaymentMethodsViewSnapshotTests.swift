//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest


class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {
    
    // MARK: Flat radio snapshot tests
    
    func testEmbeddedPaymentMethodsView_flatRadio() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatRadio
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatRadio_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatRadio
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatRadio_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatRadio
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatRadio_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatRadio
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    // MARK: Flat check snapshot tests
    
    func testEmbeddedPaymentMethodsView_flatCheck() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatCheck
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatCheck_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatCheck
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatCheck_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatCheck
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatCheck_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatCheck
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    // MARK: Floating snapshot tests
    
    func testEmbeddedPaymentMethodsView_floating() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .floating
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_floating_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .floating
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_floating_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .floating
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_floating_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .floating
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    // TODO(porter) Add more tests w.r.t the Appearance API

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
