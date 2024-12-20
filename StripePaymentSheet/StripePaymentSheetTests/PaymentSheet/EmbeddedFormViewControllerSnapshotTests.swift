//
//  EmbeddedFormViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/17/24.
//

@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP)  @_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class EmbeddedFormViewControllerSnapshotTests: STPSnapshotTestCase {

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
        StripeAPI.defaultPublishableKey = nil
    }

    // MARK: - Helper Methods

    func makeEmbeddedFormViewController(
        configuration: EmbeddedPaymentElement.Configuration,
        paymentMethodType: STPPaymentMethodType,
        previousPaymentOption: PaymentOption? = nil,
        savedPaymentMethods: [STPPaymentMethod] = []
    ) -> EmbeddedFormViewController {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]),
            elementsSession: ._testValue(paymentMethodTypes: [paymentMethodType.identifier]),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(paymentMethodType)]
        )

        return EmbeddedFormViewController(
            configuration: configuration,
            intent: loadResult.intent,
            elementsSession: loadResult.elementsSession,
            shouldUseNewCardNewCardHeader: loadResult.savedPaymentMethods.first?.type == .card,
            paymentMethodType: .stripe(paymentMethodType),
            previousPaymentOption: previousPaymentOption,
            analyticsHelper: ._testValue()
        )
    }

    func makeBottomSheetAndLayout(_ sut: EmbeddedFormViewController) -> BottomSheetViewController {
        let bottomSheet = BottomSheetViewController(
            contentViewController: sut,
            appearance: .default,
            isTestMode: false,
            didCancelNative3DS2: {}
        )
        bottomSheet.view.setNeedsLayout()
        bottomSheet.view.layoutIfNeeded()
        let height = bottomSheet.view.systemLayoutSizeFitting(
            CGSize(width: 375, height: UIView.noIntrinsicMetric)
        ).height
        bottomSheet.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: height))
        return bottomSheet
    }

    func verify(
        _ sut: EmbeddedFormViewController,
        identifier: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let bottomSheet = makeBottomSheetAndLayout(sut)
        STPSnapshotVerifyView(bottomSheet.view, identifier: identifier, file: file, line: line)
    }

    // MARK: - Tests

    func testDisplayCard_confirmFormSheetAction() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .card
        )
        verify(sut)
    }

    func testDisplayCard_continueFormSheetAction() {
        var configuration = EmbeddedPaymentElement.Configuration()
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .card
        )
        verify(sut)
    }

    func testDisplaysError() {
        struct MockError: LocalizedError {
            var errorDescription: String? {
                return "Mock error description"
            }
        }
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .card
        )
        sut.updateErrorLabel(for: MockError())
        verify(sut)
    }

    func testRestoresPreviousCustomerInput() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let previousPaymentOption = PaymentOption.new(
            confirmParams: IntentConfirmParams(
                params: ._testValidCardValue(),
                type: .stripe(.card)
            )
        )
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .card,
            previousPaymentOption: previousPaymentOption
        )
        verify(sut)
    }

    func testDisabledState() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .card
        )
        sut.isUserInteractionEnabled = false
        verify(sut)
    }

    func testBillingCollectionConfiguration() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        configuration.billingDetailsCollectionConfiguration = .init(name: .always, phone: .always)
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .cashApp
        )
        verify(sut)
    }

    func testMandateView() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .SEPADebit
        )

        sut.updateMandate()
        verify(sut)
    }

    func testDisplaysErrorAndMandate() {
        struct MockError: LocalizedError {
            var errorDescription: String? {
                return "Mock error description"
            }
        }
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let sut = makeEmbeddedFormViewController(
            configuration: configuration,
            paymentMethodType: .SEPADebit
        )

        sut.updateMandate()
        sut.updateErrorLabel(for: MockError())
        verify(sut)
    }

}
