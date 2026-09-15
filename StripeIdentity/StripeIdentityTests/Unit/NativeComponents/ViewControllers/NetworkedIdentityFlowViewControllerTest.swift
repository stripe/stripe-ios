//
//  NetworkedIdentityFlowViewControllerTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeUICore
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerTest: XCTestCase {
    private var linkSession: NetworkedIdentityLinkSessionTestMock!
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var actions: NetworkedIdentityActionsTestMock!
    private var coordinator: NetworkedIdentityCoordinator!
    private var viewController: NetworkedIdentityFlowViewController!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        actions = NetworkedIdentityActionsTestMock()
        coordinator = NetworkedIdentityCoordinator(
            linkSession: linkSession,
            apiClient: apiClient,
            actions: actions,
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
            config: .init(
                route: .reuse,
                saveAvailable: true,
                merchantPublishableKey: "pk_test_merchant",
                merchantEmail: nil,
                seedSavedDocuments: false
            ),
            handoff: nil,
            currentTime: { 1_800_000_000 }
        )
        viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: true)
        coordinator.delegate = self
        viewController.loadViewIfNeeded()
    }

    func testProgressIsShownWhilePreparing() {
        // When the user starts
        coordinator.startReuse()

        // Then a progress step is shown
        XCTAssertEqual(viewController.visibleStep, .progress)
    }

    func testPhoneStepKeepsThePhoneFieldInPlaceAcrossUpdates() {
        // Given the phone step is shown
        viewController.render(.collectPhone(email: "person@example.com", error: nil))
        let container = viewController.phoneElement.view.superview
        XCTAssertNotNil(container)

        // When it updates, e.g. while the user types or after an error
        viewController.render(.collectPhone(email: "person@example.com", error: "Invalid phone number"))
        viewController.render(.signUpPending(email: "person@example.com"))

        // Then the field stays in the same container, so it keeps focus and the keyboard stays up
        XCTAssertTrue(viewController.phoneElement.view.superview === container)
        XCTAssertEqual(viewController.visibleStep, .phone)
    }

    func testEmailStepAfterLinkIsConfigured() async {
        // Given the user started
        coordinator.startReuse()
        await settle()

        // When Link is configured
        linkSession.configure.respondToNext(with: .success(()))
        await settle()

        // Then the email step is shown
        XCTAssertEqual(viewController.visibleStep, .email)
    }

    func testDocumentStepThenSharedStep() async {
        // Given the user signed in and has a saved document
        coordinator.startReuse()
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        coordinator.submitEmail("person@example.com")
        await settle()
        linkSession.lookup.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
        apiClient.documentList.respondToNext(with: .success(.init(data: [makeDocument()])))
        await settle()
        XCTAssertEqual(viewController.visibleStep, .documents)

        // When the document is shared
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token")))
        await settle()
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then the shared confirmation is shown
        XCTAssertEqual(viewController.visibleStep, .documentShared)
    }
}

private extension NetworkedIdentityFlowViewControllerTest {
    func makeDocument() -> NetworkedIdentityDocument {
        .init(
            id: "doc_1",
            documentType: .passport,
            created: 1_700_000_000,
            country: "US",
            region: nil,
            redactedDocumentNumber: "•••• 1234",
            expirationDate: 1_900_000_000,
            liveCaptured: true
        )
    }

    func settle() async {
        for _ in 0..<20 {
            await Task.yield()
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
        for _ in 0..<20 {
            await Task.yield()
        }
    }
}

extension NetworkedIdentityFlowViewControllerTest: NetworkedIdentityCoordinatorDelegate {
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
