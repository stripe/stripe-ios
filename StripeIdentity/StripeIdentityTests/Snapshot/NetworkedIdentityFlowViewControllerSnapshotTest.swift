//
//  NetworkedIdentityFlowViewControllerSnapshotTest.swift
//  StripeIdentityTests
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) import StripeUICore

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerSnapshotTest: STPSnapshotTestCase {
    private static let snapshotFrame = CGRect(x: 0, y: 0, width: 375, height: 812)

    private lazy var linkSession = NetworkedIdentityLinkSessionTestMock()
    private lazy var apiClient = NetworkedIdentityAPIClientTestMock()
    private lazy var actions = NetworkedIdentityActionsTestMock()
    private var mode: NetworkedIdentityMode = .reuse
    private lazy var coordinator: NetworkedIdentityCoordinator = {
        let coordinator = NetworkedIdentityCoordinator(
            linkSession: linkSession,
            apiClient: apiClient,
            actions: actions,
            documentRequirements: .init(
                allowedDocumentTypes: [.passport, .drivingLicense, .idCard],
                requiresLiveCapture: false
            ),
            config: .init(
                route: mode == .reuse ? .reuse : .save,
                saveAvailable: true,
                merchantPublishableKey: "pk_test_merchant",
                merchantEmail: nil,
                seedSavedDocuments: false
            ),
            handoff: nil,
            currentTime: { 1_800_000_000 }
        )
        coordinator.delegate = self
        return coordinator
    }()
    private lazy var viewController: NetworkedIdentityFlowViewController = {
        let viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: true)
        viewController.loadViewIfNeeded()
        return viewController
    }()
    private lazy var navigationController = UINavigationController(rootViewController: viewController)
    private lazy var window: UIWindow = {
        let window = UIWindow(frame: Self.snapshotFrame)
        window.rootViewController = navigationController
        window.isHidden = false
        return window
    }()

    func testEmailEntry() {
        startAndConfigure()

        XCTAssertEqual(viewController.visibleStep, .email)
        verifyView()
    }

    func testEmailEntryWithValidEmail() {
        startAndConfigure()

        // When the consumer enters a valid email address
        viewController.emailView.emailElement.setText("jane.diaz@example.com")

        // Then the Link primary action uses its enabled treatment
        XCTAssertTrue(viewController.emailView.hasValidEmailAddress)
        verifyView()
    }

    func testAwaitingOTP() {
        // Given a fresh SMS code is ready for entry
        beginExistingConsumerFlow()

        // Then the Link verification step is visible
        XCTAssertEqual(coordinator.state, .awaitingOTP(invalidCode: false))
        verifyView()
    }

    func testInvalidOTP() {
        // Given the consumer is entering the fresh SMS code
        beginExistingConsumerFlow()

        // When Link rejects the code
        coordinator.submitOTP("111111")
        settle()
        linkSession.confirmVerification.respondToNext(
            with: .failure(consumerError(code: "consumer_verification_code_invalid"))
        )
        settle()

        // Then the invalid-code UI remains visible and editable
        XCTAssertEqual(coordinator.state, .awaitingOTP(invalidCode: true))
        verifyView()
    }

    func testResendingOTP() {
        // Given the consumer has already received a fresh SMS code
        beginExistingConsumerFlow()

        // When they request another code
        coordinator.resendOTP()

        // Then the request is shown as pending
        XCTAssertEqual(coordinator.state, .otpStartPending)
        verifyView()
    }

    func testSelectedSavedDocument() {
        selectSavedDocument()
        verifyView()
    }

    func testAttachingSavedDocument() {
        // Given the consumer selected a saved document
        selectSavedDocument()

        // When they share it, minting and attachment show a pending state
        coordinator.shareSelectedDocument()

        // Then the screen cannot submit another action while attachment is pending
        XCTAssertEqual(coordinator.state, .sharingDocument(passport))
        verifyView()

        // Finish the pending request so the attempt doesn't outlive the test
        settle()
        apiClient.associationToken.respondToNext(with: .failure(consumerError(code: "resource_missing")))
        settle()
    }

    func testPhoneEntryForNewAccount() {
        // Given a consumer without a Link account is saving
        mode = .save
        startAndConfigure()
        coordinator.submitEmail("consumer@example.com")
        settle()
        linkSession.lookup.respondToNext(with: .success(nil))
        settle()

        // Then a phone number is collected to sign up
        XCTAssertEqual(coordinator.state, .collectPhone(email: "consumer@example.com", error: nil))
        verifyView()
    }

    func testSaveFailed() {
        // Given a signed-in consumer is saving
        mode = .save
        startAndConfigure()
        coordinator.submitEmail("consumer@example.com")
        settle()
        linkSession.lookup.respondToNext(with: .success(account(isVerified: true)))
        settle()

        // When the save token can't be created
        apiClient.saveAssociationToken.respondToNext(
            with: .failure(consumerError(code: "resource_missing"))
        )
        settle()

        // Then the failure stays on screen with its details
        guard case .saveFailed = coordinator.state else {
            return XCTFail("Expected a save failure, got \(coordinator.state)")
        }
        verifyView()
    }
}

extension NetworkedIdentityFlowViewControllerSnapshotTest: NetworkedIdentityCoordinatorDelegate {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        viewController.render(state)
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didFinishWith outcome: NetworkedIdentityOutcome
    ) {}
}

private extension NetworkedIdentityFlowViewControllerSnapshotTest {
    var passport: NetworkedIdentityDocument {
        identityDocument(id: "id_doc_passport", documentType: .passport, redactedDocumentNumber: "•••• 6789")
    }

    func verifyView(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _ = window
        window.layoutIfNeeded()
        navigationController.view.layoutIfNeeded()
        XCTAssertEqual(navigationController.view.bounds, Self.snapshotFrame)
        STPSnapshotVerifyView(navigationController.view, file: file, line: line)
    }

    func startAndConfigure() {
        _ = viewController
        switch mode {
        case .reuse:
            coordinator.startReuse()
        case .save:
            coordinator.startSave()
        }
        settle()
        linkSession.configure.respondToNext(with: .success(()))
        settle()
    }

    func beginExistingConsumerFlow() {
        startAndConfigure()
        coordinator.submitEmail("consumer@example.com")
        settle()
        linkSession.lookup.respondToNext(with: .success(account(isVerified: false)))
        settle()
        linkSession.startVerification.respondToNext(with: .success(account(isVerified: false)))
        settle()
    }

    func selectSavedDocument() {
        // Given a verified consumer has two reusable documents
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        settle()
        linkSession.confirmVerification.respondToNext(with: .success(account(isVerified: true)))
        settle()
        let drivingLicense = identityDocument(
            id: "id_doc_license",
            documentType: .drivingLicense,
            redactedDocumentNumber: "•••• 4242"
        )
        apiClient.documentList.respondToNext(with: .success(.init(data: [drivingLicense, passport])))
        settle()

        // When the consumer selects their passport
        coordinator.selectDocument(passport)

        // Then the selected state is visible in the saved-document list
        XCTAssertEqual(coordinator.state, .selectDocument(documents: [drivingLicense, passport], selectedDocumentID: passport.id))
    }

    func account(isVerified: Bool) -> NetworkedIdentityLinkAccount {
        .init(
            email: "consumer@example.com",
            redactedPhoneNumber: "(***) *** **34",
            isVerified: isVerified,
            credentials: .init(publishableKey: "pk_consumer", sessionClientSecret: "cs_consumer")
        )
    }

    func identityDocument(
        id: String,
        documentType: NetworkedIdentityDocumentType,
        redactedDocumentNumber: String
    ) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: documentType,
            created: 1_700_000_000,
            country: "US",
            region: nil,
            redactedDocumentNumber: redactedDocumentNumber,
            expirationDate: 1_900_000_000,
            liveCaptured: false
        )
    }

    func consumerError(code: String) -> Error {
        NSError(
            domain: "NetworkedIdentityFlowViewControllerSnapshotTest",
            code: 0,
            userInfo: [
                STPError.stripeErrorCodeKey: code,
                NSLocalizedDescriptionKey: "The request could not be completed.",
            ]
        )
    }

    /// Lets the coordinator's main-actor work run, keeping test names synchronous so they match the
    /// reference image names.
    func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
}
