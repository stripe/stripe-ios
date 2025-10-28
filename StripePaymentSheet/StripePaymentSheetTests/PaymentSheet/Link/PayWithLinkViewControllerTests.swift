//
//  PayWithLinkViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 1/6/25.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import XCTest
#if !os(visionOS)
class PayWithLinkViewControllerTests: XCTestCase {
    var paymentSheet: PayWithNativeLinkController!

    @MainActor
    func testBailsToWebFlowWhenAttestationFails() async {
        // Set up a mock STPAPIClient with a mocked attestation backend
        let apiClient = STPAPIClient(publishableKey: "pk_live_abc123")
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        let mockAttestBackend = MockAttestBackend()
        let mockAttestService = MockAppAttestService()
        let mockStripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: apiClient)
        apiClient.stripeAttest = mockStripeAttest
        config.apiClient = apiClient

        // Always fail attestation, forcing us back to the web flow
        await mockAttestService.setShouldFailKeygenWithError(NSError(domain: "test", code: 1))

        let exp = expectation(description: "SFAuthenticationViewController presented")
        // Create a TestViewController, which will call our custom block when a child VC is presented.
        let hostVC = TestViewController(onPresentChild: { vc in
            // Ensure the SFWebAuthenticationSession view controller is being presented over us.
            // SFAuthenticationViewController is private, so this is a bit hacky.
            // Should be okay for a test — if it breaks, we'd just need to replace it with the new name for SFAuthenticationViewController.
            if String(describing: type(of: vc)) == "SFAuthenticationViewController" {
                exp.fulfill()
            }
        })
        // We need a real window to present the test VC
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostVC
        window.makeKeyAndVisible()

        let payWithNativeLinkController = PayWithNativeLinkController(
            mode: .full,
            intent: ._testValue(),
            elementsSession: ._testValue(intent: ._testValue()),
            configuration: config,
            analyticsHelper: ._testValue()
        )

        // Now make the fake PayWithLinkViewController and present it
        let vc = PayWithLinkViewController(intent: ._testValue(), linkAccount: nil, elementsSession: ._testValue(intent: ._testValue()), configuration: config, canSkipWalletAfterVerification: false, analyticsHelper: ._testValue())
        vc.payWithLinkDelegate = paymentSheet
        hostVC.present(vc, animated: true, completion: {})

        payWithNativeLinkController.presentAsBottomSheet(from: vc, shouldOfferApplePay: false, shouldFinishOnClose: false, completion: { _, _, _ in })

        // Wait a bit: Attestation should be attempted, but immediately fail.
        await fulfillment(of: [exp], timeout: 2.0)
    }
}

// This just exists for the above test, it calls a block when a VC is presented
class TestViewController: UIViewController {
    let onPresentChild: (UIViewController) -> Void

    init(onPresentChild: @escaping (UIViewController) -> Void) {
        self.onPresentChild = onPresentChild
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        onPresentChild(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
#endif
