//
//  BottomSheetViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
import StripeCoreTestUtils
import UIKit

@testable import StripeIdentity

final class BottomSheetViewControllerSnapshotTest: STPSnapshotTestCase {
    func testHowWeVerifyYou() throws {
        try verify(
            .init(
                bottomsheetId: "consent_identity",
                title: "How we verify you",
                lines: [
                    .init(
                        icon: .cloud,
                        title: "Stripe technology",
                        content: "We leverage Stripe's own verification service to verify your identity through your document and selfie."
                    ),
                    .init(
                        icon: .moved,
                        title: "Third-party partners",
                        content: "We work with trusted partners (e.g., document issuers, phone verification vendors and authorized record holders) to collect information about you to verify your identity and to improve how Stripe and our partners fight fraud."
                    ),
                    .init(
                        icon: .createIdentityVerification,
                        title: "Biometrics",
                        content: "Stripe will not share your biometrics with Andrew's Audio. Stripe will identify you using your biometrics for only one year. You can <a href='https://support.stripe.com/questions/managing-your-id-verification-information#data-deletion'>opt-out</a> at any time."
                    ),
                ]
            )
        )
    }

    func testTypesOfPhotoID() throws {
        try verify(
            .init(
                bottomsheetId: "consent_photo_id",
                title: "Types of photo ID",
                lines: [
                    .init(
                        icon: .wallet,
                        title: "Accepted forms of identification",
                        content: "<ul><li>Passport</li><li>Drivers license</li><li>National ID</li><li>Valid government-issued identification that clearly shows your face</li></ul>"
                    ),
                ]
            )
        )
    }

    func testYourData() throws {
        try verify(
            .init(
                bottomsheetId: "consent_verification_data",
                title: "Your data",
                lines: [
                    .init(
                        icon: .lock,
                        title: "Your data is encrypted",
                        content: "Stripe handles billions of dollars in payments annually. The same infrastructure keeps identity verification data safe as well."
                    ),
                    .init(
                        icon: .lock,
                        title: "Stripe data use",
                        content: "Stripe will use and store your data under Stripe’s privacy policy, including to manage loss and for legal compliance. <a href='https://stripe.com/privacy-center/legal#stripe-identity'>Learn more</a>."
                    ),
                    .init(
                        icon: .moved,
                        title: "Andrew's Audio access",
                        content: "Andrew's Audio will have access to the information you submit and the status of your verification, and may use your information under its privacy policy."
                    ),
                    .init(
                        icon: .document,
                        title: "Manage your data",
                        content: "You can delete your data by contacting Andrew's Audio."
                    ),
                ]
            )
        )
    }

    private func verify(
        _ content: StripeAPI.VerificationPageStaticContentBottomSheetContent,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let verificationPage = try VerificationPageMock.response200.make()
        let welcomeViewController = try IndividualWelcomeViewController(
            brandLogo: SnapshotTestMockData.uiImage(image: .headerIcon),
            welcomeContent: verificationPage.individualWelcome,
            sheetController: VerificationSheetControllerMock()
        )
        let hostViewController = IdentityFlowNavigationController(
            rootViewController: welcomeViewController
        )
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostViewController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        hostViewController.beginAppearanceTransition(true, animated: false)
        hostViewController.endAppearanceTransition()

        let sheetViewController = try BottomSheetViewController.makeForPresentation(content: content)
        let dimmingView = UIView(frame: hostViewController.view.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        hostViewController.view.addSubview(dimmingView)

        hostViewController.addChild(sheetViewController)
        sheetViewController.view.frame = CGRect(
            x: 0,
            y: hostViewController.view.bounds.height - sheetViewController.preferredDetentHeight,
            width: hostViewController.view.bounds.width,
            height: sheetViewController.preferredDetentHeight
        )
        sheetViewController.view.layer.cornerRadius = 8
        sheetViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetViewController.view.clipsToBounds = true
        hostViewController.view.addSubview(sheetViewController.view)
        sheetViewController.didMove(toParent: hostViewController)
        window.layoutIfNeeded()

        STPSnapshotVerifyView(window, file: file, line: line)
    }
}
