//
//  PartnerAuthViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import AuthenticationServices
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol PartnerAuthViewControllerDelegate: AnyObject {
    func partnerAuthViewControllerDidRequestToGoBack(_ viewController: PartnerAuthViewController)
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthSession
    )
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveError error: Error
    )
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane
    )
}

final class PartnerAuthViewController: SheetViewController {

    /**
     Unfortunately there is a need for this state-full parameter. When we get url callback the app might not be in foreground state.
     If we then authorize the auth session will fail as you can't do background networking without special permission.
     */
    private var unprocessedReturnURL: URL?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false

    private let dataSource: PartnerAuthDataSource
    private var institution: FinancialConnectionsInstitution {
        return dataSource.institution
    }
    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var lastHandledAuthenticationSessionReturnUrl: URL?
    weak var delegate: PartnerAuthViewControllerDelegate?

    private var prepaneViews: PrepaneViews?
    private var continueStateViews: ContinueStateViews?
    private var loadingView: UIView?
    private var legacyLoadingView: UIView?
    private var showLegacyBrowserOnViewDidAppear = false

    var pane: FinancialConnectionsSessionManifest.NextPane {
        return dataSource.isNetworkingRelinkSession ? .bankAuthRepair : .partnerAuth
    }

    init(
        dataSource: PartnerAuthDataSource,
        panePresentationStyle: PanePresentationStyle
    ) {
        self.dataSource = dataSource
        super.init(panePresentationStyle: panePresentationStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .partnerAuth)

        if let authSession = dataSource.pendingAuthSession {
            if authSession.isOauthNonOptional {
                createdAuthSession(authSession)
            } else {
                // for legacy (non-oauth), start showing the loading indicator,
                // and wait until `viewDidAppear` gets called
                insertLegacyLoadingView()
                showLegacyBrowserOnViewDidAppear = true
            }
        } else {
            assert(
                panePresentationStyle == .fullscreen,
                "partner auth initialized without an auth session is expected to be full screen"
            )
            createAuthSession()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if showLegacyBrowserOnViewDidAppear {
            showLegacyBrowserOnViewDidAppear = false
            // wait until `viewDidAppear` gets called for legacy (non-oauth) because
            // calling `createdAuthSession` WHILE the VC is animating causes an
            // animation glitch due to ASWebAuthenticationSession browser animation
            // happening simultaneously
            if
                let authSession = dataSource.pendingAuthSession,
                !authSession.isOauthNonOptional
            {
                createdAuthSession(authSession)
            }
        }
    }

    private func createAuthSession() {
        assertMainQueue()

        showLoadingView(true)
        dataSource
            .createAuthSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                // order is important so be careful of moving
                self.showLoadingView(false)
                switch result {
                case .success(let authSession):
                    self.createdAuthSession(authSession)
                case .failure(let error):
                    self.showErrorView(error)
                }
            }
    }

    private func createdAuthSession(_ authSession: FinancialConnectionsAuthSession) {
        dataSource.recordAuthSessionEvent(
            eventName: "launched",
            authSessionId: authSession.id
        )

        if authSession.isOauthNonOptional, let prepaneModel = authSession.display?.text?.oauthPrepane {
            prepaneViews = nil // the `deinit` of prepane views will remove views
            let prepaneViews = PrepaneViews(
                prepaneModel: prepaneModel,
                hideSecondaryButton: dataSource.isNetworkingRelinkSession,
                panePresentationStyle: panePresentationStyle,
                appearance: dataSource.manifest.appearance,
                didSelectURL: { [weak self] url in
                    self?.didSelectURLInTextFromBackend(url)
                },
                didSelectContinue: { [weak self] in
                    guard let self = self else { return }
                    self.dataSource.analyticsClient.log(
                        eventName: "click.prepane.continue",
                        parameters: [
                            "requires_native_redirect": authSession.requiresNativeRedirect,
                        ],
                        pane: .partnerAuth
                    )

                    if authSession.requiresNativeRedirect {
                        self.openInstitutionAuthenticationNativeRedirect(authSession: authSession)
                    } else {
                        self.openInstitutionAuthenticationWebView(authSession: authSession)
                    }
                },
                didSelectCancel: { [weak self] in
                    guard let self = self else { return }
                    let isModal = panePresentationStyle == .sheet

                    self.dataSource.analyticsClient.log(
                        eventName: isModal ? "click.prepane.cancel" : "click.prepane.choose_another_bank",
                        pane: .partnerAuth
                    )

                    self.dataSource.cancelPendingAuthSessionIfNeeded()

                    if isModal {
                        self.delegate?.partnerAuthViewControllerDidRequestToGoBack(self)
                    } else {
                        self.delegate?.partnerAuthViewController(self, didRequestNextPane: .institutionPicker)
                    }
                }
            )
            self.prepaneViews = prepaneViews

            setup(
                withContentView: prepaneViews.contentStackView,
                footerView: prepaneViews.footerView
            )

            dataSource.recordAuthSessionEvent(
                eventName: "loaded",
                authSessionId: authSession.id
            )
        } else {
            insertLegacyLoadingView()

            openInstitutionAuthenticationWebView(authSession: authSession)
        }
    }

    private func insertLegacyLoadingView() {
        legacyLoadingView?.removeFromSuperview()
        legacyLoadingView = nil

        // a legacy (non-oauth) institution will have a blank background
        // during presenting + dismissing of the Web View, so
        // add a loading spinner to fill some of the blank space
        //
        // note that this is purposefully separate from `showLoadingView`
        // function because it avoids animation glitches where
        // `showLoadingView(false)` can remove the loading view
        let loadingView = SpinnerView(appearance: dataSource.manifest.appearance)
        self.legacyLoadingView = loadingView
        view.addAndPinSubviewToSafeArea(loadingView)
    }

    private func showErrorView(_ error: Error) {
        delegate?.partnerAuthViewController(self, didReceiveError: error)
    }

    private func handleAuthSessionCompletionWithStatus(
        _ status: String,
        _ authSession: FinancialConnectionsAuthSession
    ) {
        if status == "success" {
            self.dataSource.recordAuthSessionEvent(
                eventName: "success",
                authSessionId: authSession.id
            )

            if dataSource.isNetworkingRelinkSession {
                self.pollAuthSession(authSession)
            } else if authSession.isOauthNonOptional {
                // for OAuth flows, we need to fetch OAuth results
                self.authorizeAuthSession(authSession)
            } else {
                // for legacy flows (non-OAuth), we do not need to fetch OAuth results, or call authorize
                self.didComplete(withAuthSession: authSession)
            }
        } else if status == "failure" {
            self.dataSource.recordAuthSessionEvent(
                eventName: "failure",
                authSessionId: authSession.id
            )

            // cancel current auth session
            self.dataSource.cancelPendingAuthSessionIfNeeded()

            // show a terminal error
            self.showErrorView(
                FinancialConnectionsSheetError.unknown(
                    debugDescription: "Shim returned a failure."
                )
            )
        } else {  // assume `status == cancel`
            self.checkIfAuthSessionWasSuccessful(
                authSession: authSession,
                completionHandler: { [weak self] isSuccess in
                    guard let self = self else { return }
                    if !isSuccess {
                        self.handleAuthSessionCancel(authSession, nil)
                    }
                }
            )
        }
    }

    private func handleAuthSessionCancel(
        _ authSession: FinancialConnectionsAuthSession,
        _ error: Error?
    ) {
        if authSession.isOauthNonOptional {
            // on "manual cancels" (for OAuth) we log retry event:
            dataSource.recordAuthSessionEvent(
                eventName: "retry",
                authSessionId: authSession.id
            )
        } else {
            // on "manual cancels" (for Legacy) we log cancel event:
            dataSource.recordAuthSessionEvent(
                eventName: "cancel",
                authSessionId: authSession.id
            )
        }

        // cancel current auth session because something went wrong
        dataSource.cancelPendingAuthSessionIfNeeded()

        if authSession.isOauthNonOptional {
            // for OAuth institutions, we remain on the pre-pane,
            // but create a brand new auth session
            createAuthSession()
        } else {
            // for legacy (non-OAuth) institutions, we navigate back to InstitutionPickerViewController
            navigateBack()
        }
    }

    private func openInstitutionAuthenticationNativeRedirect(
        authSession: FinancialConnectionsAuthSession
    ) {
        guard
            let urlString = authSession.url?.droppingNativeRedirectPrefix(),
            let url = URL(string: urlString)
        else {
            self.showErrorView(
                FinancialConnectionsSheetError.unknown(
                    debugDescription: "Malformed auth session url."
                )
            )
            return
        }
        let continueStateViews = ContinueStateViews(
            institutionImageUrl: institution.icon?.default,
            appearance: dataSource.manifest.appearance,
            didSelectContinue: { [weak self] in
                guard let self else { return }
                self.dataSource.analyticsClient.log(
                    eventName: "click.apptoapp.continue",
                    pane: .partnerAuth
                )
                self.openInstitutionAuthenticationNativeRedirect(authSession: authSession)
            },
            didSelectCancel: { [weak self] in
                guard let self else { return }
                self.delegate?.partnerAuthViewControllerDidRequestToGoBack(self)
            }
        )
        self.continueStateViews = continueStateViews
        setup(
            withContentView: continueStateViews.contentView,
            footerView: continueStateViews.footerView
        )

        subscribeToURLAndAppActiveNotifications()
        UIApplication.shared.open(
            url,
            options: [.universalLinksOnly: true]
        ) { (didOpenBankingApp) in
            guard !didOpenBankingApp else {
                // we pass control to the bank app
                return
            }
            // if we get here, it means the banking app is not installed
            self.clearStateAndUnsubscribeFromNotifications(removeContinueStateView: true)

            self.showLoadingView(true)
            self.dataSource
                .clearReturnURL(authSession: authSession, authURL: urlString)
                .observe(on: .main) { [weak self] result in
                    guard let self = self else { return }
                    // order is important so be careful of moving
                    self.showLoadingView(false)
                    switch result {
                    case .success(let authSession):
                        self.openInstitutionAuthenticationWebView(authSession: authSession)
                    case .failure(let error):
                        self.showErrorView(error)
                    }
                }
        }
    }

    private func openInstitutionAuthenticationWebView(authSession: FinancialConnectionsAuthSession) {
        guard let urlString = authSession.url, let url = URL(string: urlString) else {
            assertionFailure("Expected to get a URL back from authorization session.")
            dataSource
                .analyticsClient
                .logUnexpectedError(
                    FinancialConnectionsSheetError.unknown(
                        debugDescription: "Invalid or NULL URL returned from auth session"
                    ),
                    errorName: "InvalidAuthSessionURL",
                    pane: .partnerAuth
                )
            // navigate back to institution picker so user can try again
            navigateBack()
            return
        }

        lastHandledAuthenticationSessionReturnUrl = nil
        let webAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "stripe",
            // note that `error` is NOT related to our backend
            // sending errors, it's only related to `ASWebAuthenticationSession`
            completionHandler: { [weak self] returnUrl, error in
                guard let self = self else { return }
                if self.lastHandledAuthenticationSessionReturnUrl != nil
                    && self.lastHandledAuthenticationSessionReturnUrl == returnUrl
                {
                    // for unknown reason, `ASWebAuthenticationSession` can _sometimes_
                    // call the `completionHandler` twice
                    //
                    // we use `returnUrl`, instead of a `Bool`, in the case that
                    // this completion handler can sometimes return different URL's
                    self.dataSource.recordAuthSessionEvent(
                        eventName: "ios_double_return",
                        authSessionId: authSession.id
                    )
                    return
                }
                self.lastHandledAuthenticationSessionReturnUrl = returnUrl

                if let returnUrl = returnUrl,
                    returnUrl.scheme == "stripe",
                    let urlComponsents = URLComponents(url: returnUrl, resolvingAgainstBaseURL: true),
                    let status = urlComponsents.queryItems?.first(where: { $0.name == "status" })?.value
                {
                    self.logUrlReceived(returnUrl, status: status, authSessionId: authSession.id)
                    self.handleAuthSessionCompletionWithStatus(status, authSession)
                }
                // we did NOT get a `status` back from the backend,
                // so assume a "cancel"
                else {
                    self.logUrlReceived(returnUrl, status: nil, authSessionId: authSession.id)

                    if let error = error {
                        if
                            (error as NSError).domain == ASWebAuthenticationSessionErrorDomain,
                            (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                        {
                            self.dataSource
                                .analyticsClient
                                .log(
                                    eventName: "secure_webview_cancel",
                                    pane: .partnerAuth
                                )
                        } else {
                            self.dataSource
                                .analyticsClient
                                .logUnexpectedError(
                                    error,
                                    errorName: "ASWebAuthenticationSessionError",
                                    pane: .partnerAuth
                                )
                        }
                    }

                    self.checkIfAuthSessionWasSuccessful(
                        authSession: authSession,
                        completionHandler: { [weak self] isSuccess in
                            guard let self = self else { return }
                            if !isSuccess {
                                self.handleAuthSessionCancel(authSession, error)
                            }
                        }
                    )
                }

                self.webAuthenticationSession = nil
            }
        )
        self.webAuthenticationSession = webAuthenticationSession

        webAuthenticationSession.presentationContextProvider = self
        webAuthenticationSession.prefersEphemeralWebBrowserSession = true

        if #available(iOS 13.4, *) {
            if !webAuthenticationSession.canStart {
                dataSource.recordAuthSessionEvent(
                    eventName: "ios-browser-cant-start",
                    authSessionId: authSession.id
                )
                // navigate back to bank picker so user can try again
                //
                // this may be an odd way to handle an issue, but trying again
                // is potentially better than forcing user to close the whole
                // auth session
                navigateBack()
                return  // skip starting
            }
        }

        if !webAuthenticationSession.start() {
            dataSource.recordAuthSessionEvent(
                eventName: "ios-browser-did-not-start",
                authSessionId: authSession.id
            )
            // navigate back to bank picker so user can try again
            //
            // this may be an odd way to handle an issue, but trying again
            // is potentially better than forcing user to close the whole
            // auth session
            navigateBack()
        } else {
            // we successfully launched the secure web browser
            dataSource
                .analyticsClient
                .log(
                    eventName: "auth_session.opened",
                    parameters: [
                        "browser": "ASWebAuthenticationSession",
                        "auth_session_id": authSession.id,
                        "flow": authSession.flow?.rawValue ?? "null",
                    ],
                    pane: .partnerAuth
                )

            if authSession.isOauthNonOptional {
                dataSource.recordAuthSessionEvent(
                    eventName: "oauth-launched",
                    authSessionId: authSession.id
                )
            } else {
                dataSource.recordAuthSessionEvent(
                    eventName: "legacy-launched",
                    authSessionId: authSession.id
                )
            }
        }
    }

    private func authorizeAuthSession(_ authSession: FinancialConnectionsAuthSession) {
        showLoadingView(true)
        dataSource
            .authorizeAuthSession(authSession)
            .observe(on: .main) { [weak self] result in
                self?.handleAuthSessionRetrieved(result)
            }
    }

    private func pollAuthSession(_ authSession: FinancialConnectionsAuthSession) {
        showLoadingView(true)
        dataSource
            .pollAuthSession(authSession)
            .observe(on: .main) { [weak self] result in
                self?.handleAuthSessionRetrieved(result)
            }
    }

    private func handleAuthSessionRetrieved(_ result: Result<FinancialConnectionsAuthSession, any Error>) {
        switch result {
        case .success(let authSession):
            self.didComplete(withAuthSession: authSession)

            // hide the loading view after a delay to prevent
            // the screen from flashing _while_ the transition
            // to the next screen takes place
            //
            // note that it should be impossible to view this screen
            // after a successful `authorizeAuthSession`, so
            // calling `showEstablishingConnectionLoadingView(false)` is
            // defensive programming anyway
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showLoadingView(false)
            }
        case .failure(let error):
            self.showLoadingView(false)  // important to come BEFORE showing error view so we avoid showing back button
            self.showErrorView(error)
            assert(self.navigationItem.hidesBackButton)
        }
    }

    private func navigateBack() {
        delegate?.partnerAuthViewControllerDidRequestToGoBack(self)
    }

    private func showLoadingView(_ show: Bool) {
        loadingView?.removeFromSuperview()
        loadingView = nil

        // there's a chance we don't have the data yet to display a
        // prepane-based loading view, so we have extra handling
        // to handle both states
        if prepaneViews != nil || continueStateViews != nil {
            prepaneViews?.showLoadingView(show)
            continueStateViews?.showLoadingView(show)
        } else {
            if show {
                let loadingView = SpinnerView(appearance: dataSource.manifest.appearance)
                self.loadingView = loadingView
                view.addAndPinSubviewToSafeArea(loadingView)
            }
        }
        navigationItem.hidesBackButton = show
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .partnerAuth,
            analyticsClient: dataSource.analyticsClient,
            handleURL: { urlHost, _ in
                if urlHost == "data-access-notice" {
                    if let dataAccessNoticeModel = dataSource.pendingAuthSession?.display?.text?.oauthPrepane?.dataAccessNotice {
                        let dataAccessNoticeViewController = DataAccessNoticeViewController(
                            dataAccessNotice: dataAccessNoticeModel,
                            appearance: dataSource.manifest.appearance,
                            didSelectUrl: { [weak self] url in
                                self?.didSelectURLInTextFromBackend(url)
                            }
                        )
                        dataAccessNoticeViewController.present(on: self)
                    }
                }
            }
        )
    }

    // There are edge-cases where redirect links don't work properly.
    // Check the auth session in-case the auth session was successful.
    private func checkIfAuthSessionWasSuccessful(
        authSession: FinancialConnectionsAuthSession,
        completionHandler: @escaping (_ isSuccess: Bool) -> Void
    ) {
        guard !dataSource.disableAuthSessionRetrieval else {
            // if auth session retrieval is disabled, go to the default case
            completionHandler(false)
            return
        }

        showLoadingView(true)
        dataSource
            .retrieveAuthSession(authSession)
            .observe { [weak self] result in
                guard let self = self else { return }
                self.showLoadingView(false)

                self.dataSource
                    .analyticsClient
                    .log(
                        eventName: "auth_session.retrieved",
                        parameters: [
                            "auth_session_id": authSession.id,
                            "next_pane": (try? result.get())?.nextPane.rawValue ?? "null",
                        ],
                        pane: .partnerAuth
                    )

                switch result {
                case .success(let authSession):
                    if authSession.nextPane != .partnerAuth {
                        completionHandler(true)
                        self.dataSource.recordAuthSessionEvent(
                            eventName: "success",
                            authSessionId: authSession.id
                        )
                        // abstract auth handles calling `authorize`
                        self.didComplete(withAuthSession: authSession)
                    } else {
                        completionHandler(false)
                    }
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "RetrieveAuthSessionError",
                            pane: .partnerAuth
                        )
                    completionHandler(false)
                }
            }
    }

    private func logUrlReceived(
        _ url: URL?,
        status: String?,
        authSessionId: String
    ) {
        dataSource
            .analyticsClient
            .log(
                eventName: "auth_session.url_received",
                parameters: [
                    "status": status ?? "null",
                    "url": url?.absoluteString ?? "null",
                    "auth_session_id": authSessionId,
                ],
                pane: .partnerAuth
            )
    }

    // Defensive programming to avoid completing the same auth session twice.
    //
    // There's been a series of odd edge-cases where the same auth session
    // could complete twice, so this acts as future-proofing that this
    // never happens again.
    private var lastCompletedAuthSessionId: String?
    private func didComplete(withAuthSession authSession: FinancialConnectionsAuthSession) {
        if lastCompletedAuthSessionId != authSession.id {
            lastCompletedAuthSessionId = authSession.id
            delegate?.partnerAuthViewController(self, didCompleteWithAuthSession: authSession)
        } else {
            dataSource
                .analyticsClient.log(
                    eventName: "ios_double_complete_attempt",
                    parameters: [
                        "auth_session_id": authSession.id,
                    ],
                    pane: .partnerAuth
                )
        }
    }
}

// MARK: - STPURLCallbackListener

extension PartnerAuthViewController: STPURLCallbackListener {

    private func handleAuthSessionCompletionFromNativeRedirect(_ url: URL) {
        assertMainQueue()

        guard let authSession = dataSource.pendingAuthSession else {
            return
        }
        guard var urlComponsents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            dataSource.recordAuthSessionEvent(
                eventName: "native-app-to-app-failed-to-resolve-url",
                authSessionId: authSession.id
            )
            return
        }
        urlComponsents.query = url.fragment

        if
            let status = urlComponsents.queryItems?.first(where: { $0.name == "code" })?.value,
            let authSessionId = urlComponsents.queryItems?.first(where: { $0.name == "authSessionId" })?.value,
            authSessionId == dataSource.pendingAuthSession?.id
        {
            logUrlReceived(url, status: status, authSessionId: authSession.id)
            handleAuthSessionCompletionWithStatus(status, authSession)
        } else {
            logUrlReceived(url, status: nil, authSessionId: authSession.id)
            handleAuthSessionCancel(authSession, nil)
        }
    }

    func handleURLCallback(_ url: URL) -> Bool {
        DispatchQueue.main.async {
            self.unprocessedReturnURL = url
            self.handleAuthSessionCompletionFromNativeRedirectIfNeeded()
        }
        return true
    }
}

// MARK: - Authentication restart helpers

private extension PartnerAuthViewController {

    private func subscribeToURLAndAppActiveNotifications() {
        assertMainQueue()

        subscribeToURLNotifications()
        if !subscribedToAppActiveNotifications {
            subscribedToAppActiveNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDidBecomeActiveNotification),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    private func subscribeToURLNotifications() {
        assertMainQueue()

        guard let returnURL = dataSource.returnURL,
            let url = URL(string: returnURL)
        else {
            return
        }
        if !subscribedToURLNotifications {
            subscribedToURLNotifications = true
            STPURLCallbackHandler.shared().register(
                self,
                for: url
            )
        }
    }

    private func unsubscribeFromNotifications() {
        assertMainQueue()

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        STPURLCallbackHandler.shared().unregisterListener(self)
        subscribedToURLNotifications = false
        subscribedToAppActiveNotifications = false
    }

    @objc func handleDidBecomeActiveNotification() {
        DispatchQueue.main.async {
            self.handleAuthSessionCompletionFromNativeRedirectIfNeeded()
        }
    }

    private func clearStateAndUnsubscribeFromNotifications(
        removeContinueStateView: Bool
    ) {
        unprocessedReturnURL = nil
        unsubscribeFromNotifications()

        if removeContinueStateView {
            continueStateViews = nil
            if let authSession = dataSource.pendingAuthSession {
                // re-create the views
                createdAuthSession(authSession)
            }
        }
    }

    private func handleAuthSessionCompletionFromNativeRedirectIfNeeded() {
        assertMainQueue()

        guard UIApplication.shared.applicationState == .active else {
            /**
             When we get url callback the app might not be in foreground state.
             If we then proceed with authorization network request might fail as we will be doing background networking without special permission..
             */
            return
        }
        if let url = unprocessedReturnURL {
            if let authSession = dataSource.pendingAuthSession {
                dataSource.recordAuthSessionEvent(
                    eventName: "native-app-to-app-redirect-url-received",
                    authSessionId: authSession.id
                )
            }
            clearStateAndUnsubscribeFromNotifications(removeContinueStateView: false)
            handleAuthSessionCompletionFromNativeRedirect(url)
        } else if let authSession = dataSource.pendingAuthSession {
            self.checkIfAuthSessionWasSuccessful(
                authSession: authSession,
                completionHandler: { [weak self] isSuccess in
                    if isSuccess {
                        self?.clearStateAndUnsubscribeFromNotifications(
                            // on success, we will move away from
                            // the screen, so there's no reason
                            // to remove the continue state now
                            removeContinueStateView: false
                        )
                    } else {
                        // the default case is to not do anything
                        // user can press "Continue" to re-start
                        // app-to-app
                    }
                }
            )
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

/// :nodoc:
extension PartnerAuthViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
