//
//  SharedPartnerAuthViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/23.
//

import AuthenticationServices
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol SharedPartnerAuthViewControllerDelegate: AnyObject {

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didSucceedWithAuthSession authSession: FinancialConnectionsAuthSession,
        // for OAuth, non-retrieve-auth-session successes, we should call `authorize`
        considerCallingAuthorize: Bool
    )

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didCancelWithAuthSession authSession: FinancialConnectionsAuthSession,
        // indicates whether we got back a status from abstract auth
        // which can change how we handle the cancel
        statusWasReturned: Bool
    )

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didFailWithAuthSession authSession: FinancialConnectionsAuthSession
    )

    func sharedPartnerAuthViewControllerDidRequestToGoBack(
        _ viewController: SharedPartnerAuthViewController
    )

    // we call this when we should display an error
    // (vs. terminating the session with a terminal error)
    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveError error: Error
    )
}

final class SharedPartnerAuthViewController: UIViewController {

    /**
     Unfortunately there is a need for this state-full parameter. When we get url callback the app might not be in foreground state.
     If we then authorize the auth session will fail as you can't do background networking without special permission.
     */
    private var unprocessedReturnURL: URL?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false
    private var continueStateView: ContinueStateView?

    private let dataSource: SharedPartnerAuthDataSource
    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var lastHandledAuthenticationSessionReturnUrl: URL?
    weak var delegate: SharedPartnerAuthViewControllerDelegate?

    private lazy var establishingConnectionLoadingView: UIView = {
        let establishingConnectionLoadingView = ReusableInformationView(
            iconType: .loading,
            title: STPLocalizedString(
                "Establishing connection",
                "The title of the loading screen that appears after a user selected a bank. The user is waiting for Stripe to establish a bank connection with the bank."
            ),
            subtitle: STPLocalizedString(
                "Please wait while we connect to your bank.",
                "The subtitle of the loading screen that appears after a user selected a bank. The user is waiting for Stripe to establish a bank connection with the bank."
            )
        )
        establishingConnectionLoadingView.isHidden = true
        return establishingConnectionLoadingView
    }()

    private lazy var connectingToBankView: UIView = {
        return buildRetrievingAccountsView()
    }()

    init(dataSource: SharedPartnerAuthDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
    }

    func startWithAuthSession(_ authSession: FinancialConnectionsAuthSession) {
        dataSource.pendingAuthSession = authSession

        dataSource.recordAuthSessionEvent(
            eventName: "launched",
            authSessionId: authSession.id
        )

        if authSession.isOauthNonOptional, let prepaneModel = authSession.display?.text?.oauthPrepane {
            let prepaneView = PrepaneView(
                prepaneModel: prepaneModel,
                didSelectURL: { [weak self] url in
                    self?.didSelectURLInTextFromBackend(url)
                },
                didSelectContinue: { [weak self] in
                    guard let self = self else { return }
                    self.dataSource.analyticsClient.log(
                        eventName: "click.prepane.continue",
                        parameters: [
                            "requires_native_redirect": authSession.requiresNativeRedirect
                        ],
                        pane: self.dataSource.pane
                    )

                    if authSession.requiresNativeRedirect {
                        self.openInstitutionAuthenticationNativeRedirect(authSession: authSession)
                    } else {
                        self.openInstitutionAuthenticationWebView(authSession: authSession)
                    }
                }
            )
            view.addAndPinSubview(prepaneView)

            dataSource.recordAuthSessionEvent(
                eventName: "loaded",
                authSessionId: authSession.id
            )
        } else {
            // a legacy (non-oauth) institution will have a blank background
            // during presenting + dismissing of the Web View, so
            // add a loading spinner to fill some of the blank space
            let activityIndicator = ActivityIndicator(size: .large)
            activityIndicator.color = .textDisabled
            activityIndicator.backgroundColor = .customBackgroundColor
            activityIndicator.startAnimating()
            view.addAndPinSubview(activityIndicator)

            openInstitutionAuthenticationWebView(authSession: authSession)
        }
    }

    private func handleAuthSessionCompletionWithStatus(
        _ status: String,
        _ authSession: FinancialConnectionsAuthSession
    ) {
        if status == "success" {
            dataSource.recordAuthSessionEvent(
                eventName: "success",
                authSessionId: authSession.id
            )

            delegate?.sharedPartnerAuthViewController(
                self,
                didSucceedWithAuthSession: authSession,
                considerCallingAuthorize: true
            )
        } else if status == "failure" {
            dataSource.recordAuthSessionEvent(
                eventName: "failure",
                authSessionId: authSession.id
            )

            delegate?.sharedPartnerAuthViewController(self, didFailWithAuthSession: authSession)
        } else {  // assume `status == cancel`
            checkIfAuthSessionWasSuccessful(
                authSession: authSession,
                completionHandler: { [weak self] isSuccess in
                    guard let self = self else { return }
                    if !isSuccess {
                        self.delegate?.sharedPartnerAuthViewController(
                            self,
                            didCancelWithAuthSession: authSession,
                            statusWasReturned: true
                        )
                    }
                }
            )
        }
    }

    private func handleAuthSessionCompletionWithNoStatus(
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

        delegate?.sharedPartnerAuthViewController(
            self,
            didCancelWithAuthSession: authSession,
            statusWasReturned: false
        )
    }

    private func openInstitutionAuthenticationNativeRedirect(authSession: FinancialConnectionsAuthSession) {
        guard
            let urlString = authSession.url?.droppingNativeRedirectPrefix(),
            let url = URL(string: urlString)
        else {
            let error = FinancialConnectionsSheetError.unknown(
                debugDescription: "Malformed auth session url."
            )
            delegate?.sharedPartnerAuthViewController(
                self,
                didReceiveError: error
            )
            return
        }
        self.continueStateView = ContinueStateView(
            institutionImageUrl: dataSource.institution.icon?.default,
            didSelectContinue: { [weak self] in
                guard let self = self else { return }
                self.dataSource.analyticsClient.log(
                    eventName: "click.apptoapp.continue",
                    pane: self.dataSource.pane
                )
                self.continueStateView?.removeFromSuperview()
                self.continueStateView = nil
                self.openInstitutionAuthenticationNativeRedirect(authSession: authSession)
            }
        )
        view.addAndPinSubview(self.continueStateView!)

        subscribeToURLAndAppActiveNotifications()
        UIApplication.shared.open(
            url,
            options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]
        ) { (success) in
            if success { return }
            // This means banking app is not installed
            self.clearStateAndUnsubscribeFromNotifications()

            self.showEstablishingConnectionLoadingView(true)
            self.dataSource
                .clearReturnURL(authSession: authSession, authURL: urlString)
                .observe(on: .main) { [weak self] result in
                    guard let self = self else { return }
                    // order is important so be careful of moving
                    self.showEstablishingConnectionLoadingView(false)
                    switch result {
                    case .success(let authSession):
                        self.openInstitutionAuthenticationWebView(authSession: authSession)
                    case .failure(let error):
                        self.delegate?.sharedPartnerAuthViewController(
                            self,
                            didReceiveError: error
                        )
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
                    pane: self.dataSource.pane
                )
            delegate?.sharedPartnerAuthViewControllerDidRequestToGoBack(self)
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
                                    pane: self.dataSource.pane
                                )
                        } else {
                            self.dataSource
                                .analyticsClient
                                .logUnexpectedError(
                                    error,
                                    errorName: "ASWebAuthenticationSessionError",
                                    pane: self.dataSource.pane
                                )
                        }
                    }

                    self.checkIfAuthSessionWasSuccessful(
                        authSession: authSession,
                        completionHandler: { [weak self] isSuccess in
                            guard let self = self else { return }
                            if !isSuccess {
                                self.handleAuthSessionCompletionWithNoStatus(authSession, error)
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
                // navigate back so user can try again
                //
                // this may be an odd way to handle an issue, but trying again
                // is potentially better than forcing user to close the whole
                // auth session
                delegate?.sharedPartnerAuthViewControllerDidRequestToGoBack(self)
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
            delegate?.sharedPartnerAuthViewControllerDidRequestToGoBack(self)
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

    func showEstablishingConnectionLoadingView(_ show: Bool) {
        showView(loadingView: establishingConnectionLoadingView, show: show)
    }

    func showConnectingToBankView(_ show: Bool) {
        showView(loadingView: connectingToBankView, show: show)
    }

    func showView(loadingView: UIView, show: Bool) {
        if loadingView.superview == nil {
            view.addAndPinSubviewToSafeArea(loadingView)
        }
        view.bringSubviewToFront(loadingView)  // bring to front in-case something else is covering it

        navigationItem.hidesBackButton = show
        loadingView.isHidden = !show
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .partnerAuth,
            analyticsClient: dataSource.analyticsClient,
            handleStripeScheme: { urlHost in
                if urlHost == "data-access-notice" {
                    if let dataAccessNoticeModel = dataSource.pendingAuthSession?.display?.text?.oauthPrepane?
                        .dataAccessNotice
                    {
                        let consentBottomSheetModel = ConsentBottomSheetModel(
                            title: dataAccessNoticeModel.title,
                            subtitle: dataAccessNoticeModel.subtitle,
                            body: ConsentBottomSheetModel.Body(
                                bullets: dataAccessNoticeModel.body.bullets
                            ),
                            extraNotice: dataAccessNoticeModel.connectedAccountNotice,
                            learnMore: dataAccessNoticeModel.learnMore,
                            cta: dataAccessNoticeModel.cta
                        )
                        ConsentBottomSheetViewController.present(
                            withModel: consentBottomSheetModel,
                            didSelectUrl: { [weak self] url in
                                self?.didSelectURLInTextFromBackend(url)
                            }
                        )
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

        showEstablishingConnectionLoadingView(true)
        dataSource
            .retrieveAuthSession(authSession)
            .observe { [weak self] result in
                guard let self = self else { return }
                self.showEstablishingConnectionLoadingView(false)

                self.dataSource
                    .analyticsClient
                    .log(
                        eventName: "auth_session.retrieved",
                        parameters: [
                            "auth_session_id": authSession.id,
                            "next_pane": (try? result.get())?.nextPane.rawValue ?? "null",
                        ],
                        pane: self.dataSource.pane
                    )

                switch result {
                case .success(let authSession):
                    if authSession.nextPane != .partnerAuth {
                        completionHandler(true)
                        self.dataSource.recordAuthSessionEvent(
                            eventName: "success",
                            authSessionId: authSession.id
                        )
                        self.delegate?.sharedPartnerAuthViewController(
                            self,
                            didSucceedWithAuthSession: authSession,
                            // abstract auth handles calling `authorize`
                            considerCallingAuthorize: false
                        )
                    } else {
                        completionHandler(false)
                    }
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "RetrieveAuthSessionError",
                            pane: self.dataSource.pane
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
                pane: dataSource.pane
            )
    }
}

// MARK: - STPURLCallbackListener

extension SharedPartnerAuthViewController: STPURLCallbackListener {

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
            handleAuthSessionCompletionWithNoStatus(authSession, nil)
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

private extension SharedPartnerAuthViewController {

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

    private func clearStateAndUnsubscribeFromNotifications() {
        unprocessedReturnURL = nil
        continueStateView?.removeFromSuperview()
        continueStateView = nil
        unsubscribeFromNotifications()
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
            handleAuthSessionCompletionFromNativeRedirect(url)
            clearStateAndUnsubscribeFromNotifications()
        } else if let authSession = dataSource.pendingAuthSession {
            self.checkIfAuthSessionWasSuccessful(
                authSession: authSession,
                completionHandler: { [weak self] isSuccess in
                    if isSuccess {
                        self?.clearStateAndUnsubscribeFromNotifications()
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
extension SharedPartnerAuthViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}

private func IsToday(_ comparisonDate: Date) -> Bool {
    return Calendar.current.startOfDay(for: comparisonDate) == Calendar.current.startOfDay(for: Date())
}
