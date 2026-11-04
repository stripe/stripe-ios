//
//  AutomaticCardScanTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/3/26.
//

#if !os(visionOS)

@_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePayments
@_spi(InternalOnlyAPI) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
final class AutomaticCardScanTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await AddressSpecProvider.shared.loadAddressSpecs()
    }

    func testCardOnlyFormStartsWithScanner() throws {
        // Given a card-only PaymentSheet that opens the card scanner automatically
        let sut = makeSUT()

        // Then the scanner is shown instead of the card form
        let scanViewController = try XCTUnwrap(sut.automaticCardScanViewController)
        XCTAssertTrue(sut.children.contains(scanViewController))
        XCTAssertFalse(sut.children.contains(try XCTUnwrap(sut.paymentMethodFormViewController)))
        // ...and the manual entry button replaces the primary button
        XCTAssertEqual(sut.manualCardEntryButton.alpha, 1)
        XCTAssertEqual(sut.primaryButton.alpha, 0)
        XCTAssertFalse(sut.primaryButton.isUserInteractionEnabled)
        XCTAssertNil(sut.selectedPaymentOption)
    }

    func testScannerIsNotShownWhenDisabled() {
        // Given a card-only PaymentSheet that doesn't open the card scanner automatically
        let sut = makeSUT(opensCardScannerAutomatically: false)

        // Then the card form is shown, with its inline "Scan card" button
        XCTAssertNil(sut.automaticCardScanViewController)
        XCTAssertTrue(sut.children.contains { $0 === sut.paymentMethodFormViewController })
        XCTAssertNil((sut.paymentMethodFormViewController?.headerView as? FormHeaderView)?.accessoryView)
        XCTAssertEqual(sut.primaryButton.alpha, 1)
    }

    func testManualEntryShowsForm() throws {
        // Given the scanner is showing
        let sut = makeSUT()
        let formViewController = try XCTUnwrap(sut.paymentMethodFormViewController)

        // When the customer taps "Enter card details manually"
        sut.manualCardEntryButton.sendActions(for: .touchUpInside)

        // Then the card form is shown with the primary button
        XCTAssertTrue(sut.children.contains(formViewController))
        XCTAssertFalse(sut.isShowingAutomaticCardScanner)
        XCTAssertEqual(sut.primaryButton.alpha, 1)
        XCTAssertEqual(sut.manualCardEntryButton.alpha, 0)
        // ...and the scan button in the header reads "Scan card"
        let headerButton = try XCTUnwrap(headerScanButton(sut))
        XCTAssertEqual(headerButton.configuration?.title, String.Localized.scan_card)
        // ...and the form's inline scan button is hidden in favor of the header's
        let cardSectionView = try XCTUnwrap(formViewController.cardSectionElement?.view as? CardSectionWithScannerView)
        XCTAssertTrue(cardSectionView.cardScanButton.isHidden)
        XCTAssertTrue(cardSectionView.cardScanningView.isHidden)
    }

    func testScanFillsFormAndShowsRescanButton() throws {
        // Given the scanner is showing
        let sut = makeSUT()
        let scanViewController = try XCTUnwrap(sut.automaticCardScanViewController)

        // When the scanner finishes scanning a card
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 4
        cardParams.expYear = 32
        sut.automaticCardScanViewController(scanViewController, didScan: cardParams)

        // Then the card form is shown, filled in with the scanned card
        let formViewController = try XCTUnwrap(sut.paymentMethodFormViewController)
        XCTAssertTrue(sut.children.contains(formViewController))
        let cardSection = try XCTUnwrap(formViewController.cardSectionElement)
        XCTAssertEqual(cardSection.panElement.text, "4242424242424242")
        XCTAssertEqual(cardSection.expiryElement.text, "0432")
        // ...and the header button offers to rescan
        XCTAssertEqual(try XCTUnwrap(headerScanButton(sut)).configuration?.title, "Rescan card")
    }

    func testHeaderScanButtonReopensScanner() throws {
        // Given the customer chose to enter their card manually
        let sut = makeSUT()
        sut.manualCardEntryButton.sendActions(for: .touchUpInside)
        let firstScanViewController = sut.automaticCardScanViewController

        // When they tap "Scan card" in the header
        try XCTUnwrap(headerScanButton(sut)).sendActions(for: .touchUpInside)

        // Then a new scanner is shown in place of the form
        let scanViewController = try XCTUnwrap(sut.automaticCardScanViewController)
        XCTAssertFalse(scanViewController === firstScanViewController)
        XCTAssertTrue(sut.children.contains(scanViewController))
        XCTAssertEqual(sut.manualCardEntryButton.alpha, 1)
    }

    func testTappingCardInListShowsScannerEachTime() throws {
        // Given a list of payment methods that includes card
        let sut = makeSUT(paymentMethodTypes: [.card, .cashApp])
        XCTAssertNil(sut.automaticCardScanViewController)

        // When the customer taps card
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))

        // Then the scanner is shown
        let firstScanViewController = try XCTUnwrap(sut.automaticCardScanViewController)
        XCTAssertTrue(sut.children.contains(firstScanViewController))

        // When they go back
        sut.sheetNavigationBarDidBack(sut.navigationBar)

        // Then the list is shown with the primary button
        XCTAssertTrue(sut.children.contains { $0 === sut.paymentMethodListViewController })
        XCTAssertFalse(sut.isShowingAutomaticCardScanner)
        XCTAssertEqual(sut.primaryButton.alpha, 1)

        // When they tap card again
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))

        // Then the scanner is shown again
        XCTAssertTrue(sut.isShowingAutomaticCardScanner)
        XCTAssertFalse(sut.automaticCardScanViewController === firstScanViewController)
    }

    func testTappingCardInListAfterManualEntryShowsForm() {
        // Given the customer chose to enter their card manually, then went back to the list
        let sut = makeSUT(paymentMethodTypes: [.card, .cashApp])
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))
        sut.manualCardEntryButton.sendActions(for: .touchUpInside)
        sut.sheetNavigationBarDidBack(sut.navigationBar)

        // When they tap card again
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))

        // Then the form is shown instead of the scanner
        XCTAssertTrue(sut.children.contains { $0 === sut.paymentMethodFormViewController })
        XCTAssertFalse(sut.isShowingAutomaticCardScanner)
    }

    func testTappingCardInListAfterScanShowsScannedDetails() throws {
        // Given the customer scanned a card, then went back to the list
        let sut = makeSUT(paymentMethodTypes: [.card, .cashApp])
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        sut.automaticCardScanViewController(try XCTUnwrap(sut.automaticCardScanViewController), didScan: cardParams)
        sut.sheetNavigationBarDidBack(sut.navigationBar)

        // When they tap card again
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.card)))

        // Then the form is shown with the scanned card
        XCTAssertFalse(sut.isShowingAutomaticCardScanner)
        XCTAssertEqual(sut.paymentMethodFormViewController?.cardSectionElement?.panElement.text, "4242424242424242")
    }

    func testScanViewReportsScanAfterShowingScannedState() {
        // Given a scanner that's looking for a card
        let scanView = AutomaticCardScanView(appearance: .default)
        scanView.setState(.scanning, animated: false)
        let didScan = expectation(description: "onScan called")
        scanView.onScan = { cardParams in
            XCTAssertEqual(cardParams.number, "4242424242424242")
            didScan.fulfill()
        }

        // When it scans a card
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        scanView.cardScanner(STPCardScanner(delegate: nil), didCompleteWith: cardParams)

        // Then it shows the scanned state before reporting the scan
        XCTAssertEqual(scanView.state, .scanned)
        wait(for: [didScan], timeout: AutomaticCardScanView.scannedStateDuration + 1)
    }

    func testScanViewDiscardsScanWhenStopped() {
        // Given a scanner that just scanned a card
        let scanView = AutomaticCardScanView(appearance: .default)
        scanView.setState(.scanning, animated: false)
        let didScan = expectation(description: "onScan not called")
        didScan.isInverted = true
        scanView.onScan = { _ in didScan.fulfill() }
        scanView.cardScanner(STPCardScanner(delegate: nil), didCompleteWith: STPPaymentMethodCardParams())

        // When it stops before reporting the scan
        scanView.stopScanning()

        // Then the scan is never reported
        wait(for: [didScan], timeout: AutomaticCardScanView.scannedStateDuration + 0.5)
    }

    // MARK: - Helpers

    private func makeSUT(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        opensCardScannerAutomatically: Bool = true
    ) -> PaymentSheetVerticalViewController {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.applePay = nil
        configuration.opensCardScannerAutomatically = opensCardScannerAutomatically
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: paymentMethodTypes),
            elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes.map { $0.identifier }),
            savedPaymentMethods: [],
            paymentMethodTypes: paymentMethodTypes.map { .stripe($0) },
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
        return PaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue(),
            previousPaymentOption: nil
        )
    }

    private func headerScanButton(_ sut: PaymentSheetVerticalViewController) -> UIButton? {
        return (sut.paymentMethodFormViewController?.headerView as? FormHeaderView)?.accessoryView as? UIButton
    }
}

// MARK: - Snapshots

@MainActor
final class AutomaticCardScanSnapshotTests: STPSnapshotTestCase {

    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testRequestingPermission() {
        verify(makeSUT())
    }

    func testScanning() {
        let sut = makeSUT()
        sut.automaticCardScanViewController!.scanView.setState(.scanning, animated: false)
        verify(sut)
    }

    func testScanned() {
        let sut = makeSUT()
        let scanView = sut.automaticCardScanViewController!.scanView
        scanView.setState(.scanning, animated: false)
        scanView.setState(.scanned, animated: false)
        verify(sut)
    }

    func testUnavailable() {
        let sut = makeSUT()
        sut.automaticCardScanViewController!.scanView.setState(.unavailable, animated: false)
        verify(sut)
    }

    func testManualEntryForm() {
        let sut = makeSUT()
        sut.manualCardEntryButton.sendActions(for: .touchUpInside)
        verify(sut)
    }

    func testScannedCardForm() {
        let sut = makeSUT()
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 4
        cardParams.expYear = 32
        sut.automaticCardScanViewController(sut.automaticCardScanViewController!, didScan: cardParams)
        verify(sut)
    }

    // MARK: - Helpers

    private func makeSUT() -> PaymentSheetVerticalViewController {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.applePay = nil
        configuration.opensCardScannerAutomatically = true
        configuration.primaryButtonLabel = "Add card"
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
        return PaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue(),
            previousPaymentOption: nil
        )
    }

    private func verify(_ sut: PaymentSheetVerticalViewController, file: StaticString = #file, line: UInt = #line) {
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: .default, didCancelNative3DS2: {})
        bottomSheet.view.setNeedsLayout()
        bottomSheet.view.layoutIfNeeded()
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(origin: .zero, size: .init(width: 375, height: height))
        STPSnapshotVerifyView(bottomSheet.view, file: file, line: line)
    }
}

#endif
