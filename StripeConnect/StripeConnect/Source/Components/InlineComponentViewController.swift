//
//  InlineComponentViewController.swift
//  StripeConnect
//

import UIKit

/// An embedded component that renders inline in the host's layout and sizes itself to its web content.
///
/// Overlays opened by the component (dialogs, drawers, popovers) are presented as native sheets.
@_spi(DashboardOnly)
public class InlineComponentViewController: UIViewController {

    public enum InitialLoadState: Equatable {
        /// The component is fetching and rendering its initial content.
        case loading
        /// The initial content has rendered and settled.
        case loaded
        /// The initial load failed.
        case failed
    }

    private static let minimumSettledHeight: CGFloat = 60
    private static let settleDelay: TimeInterval = 0.35
    private static let loadTimeout: TimeInterval = 12

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: InlineComponentViewControllerDelegate?

    /// The current state of the initial load. Read this immediately after
    /// creation, then observe `inlineComponent(_:didChangeInitialLoadState:)`.
    public private(set) var initialLoadState: InitialLoadState = .loading

    /// The most recently published content height, in points.
    public private(set) var contentHeight: CGFloat = 0

    private var heightConstraint: NSLayoutConstraint?
    private var pendingContentHeight: CGFloat = 0
    private var settleWorkItem: DispatchWorkItem?
    /// Components that emit `loadcomplete` are revealed on that event instead of when their height settles.
    private let revealsOnLoadComplete: Bool
    private var didReceiveLoadComplete = false

    init<Props: Encodable>(
        componentType: ComponentType,
        componentManager: EmbeddedComponentManager,
        loadContent: Bool,
        analyticsClientFactory: @escaping ComponentAnalyticsClientFactory,
        fetchInitProps: @escaping () -> Props
    ) {
        revealsOnLoadComplete = [.payoutMethods, .payoutSession].contains(componentType)
        super.init(nibName: nil, bundle: nil)

        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: componentType,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            layoutMode: .sizesToContent { [weak self] height in
                self?.contentHeightDidChange(height)
            },
            fetchInitProps: fetchInitProps
        ) { [weak self] error in
            guard let self else { return }
            self.transitionInitialLoad(to: .failed)
            self.delegate?.inlineComponent(self, didFailLoadWithError: error)
        }

        if componentType == .onboarding {
            webVC.addMessageHandler(OnExitMessageHandler(didReceiveMessage: { [weak self] in
                guard let self else { return }
                self.delegate?.inlineComponentDidExit(self)
            }))
        }

        if revealsOnLoadComplete {
            webVC.addMessageHandler(OnLoadCompleteMessageHandler { [weak self] in
                guard let self, self.initialLoadState == .loading else { return }
                self.didReceiveLoadComplete = true
                // Measure the final layout; the reveal happens when that height arrives.
                self.webVC.requestContentHeightUpdate()
            })
        }

        webVC.view.alpha = 0
        addChildAndPinView(webVC)

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.loadTimeout) { [weak self] in
            guard let self, self.initialLoadState == .loading else { return }
            self.finishLoading()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func contentHeightDidChange(_ height: CGFloat) {
        pendingContentHeight = height

        switch initialLoadState {
        case .loading where revealsOnLoadComplete:
            if didReceiveLoadComplete, height > 0 { finishLoading() }
        case .loading:
            scheduleFinishLoadingIfSettled()
        case .loaded:
            publishContentHeight(height)
        case .failed:
            break
        }
    }

    // Components render a loading skeleton before their real content, so wait
    // for the height to stop changing before revealing them.
    private func scheduleFinishLoadingIfSettled() {
        settleWorkItem?.cancel()
        guard pendingContentHeight >= Self.minimumSettledHeight else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.finishLoading()
        }
        settleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleDelay, execute: workItem)
    }

    private func finishLoading() {
        guard initialLoadState == .loading else { return }
        publishContentHeight(pendingContentHeight)
        webVC.view.alpha = 1
        transitionInitialLoad(to: .loaded)
    }

    private func publishContentHeight(_ height: CGFloat) {
        guard heightConstraint?.constant != height else { return }
        heightConstraint?.constant = height
        contentHeight = height
        delegate?.inlineComponent(self, didChangeContentHeight: height)
    }

    private func transitionInitialLoad(to state: InitialLoadState) {
        guard initialLoadState == .loading, state != .loading else { return }
        settleWorkItem?.cancel()
        initialLoadState = state
        delegate?.inlineComponent(self, didChangeInitialLoadState: state)
    }
}

@_spi(DashboardOnly)
public protocol InlineComponentViewControllerDelegate: AnyObject {
    /// The user has exited the component's flow. Only sent by account onboarding.
    func inlineComponentDidExit(_ component: InlineComponentViewController)

    /// Triggered when an error occurs loading the component.
    func inlineComponent(_ component: InlineComponentViewController,
                         didFailLoadWithError error: Error)

    /// Triggered when the component's content height changes. The component sizes itself to
    /// this height; hosts can observe it to coordinate their own layout animations.
    func inlineComponent(_ component: InlineComponentViewController,
                         didChangeContentHeight height: CGFloat)

    /// Triggered when the component's initial load state changes.
    func inlineComponent(
        _ component: InlineComponentViewController,
        didChangeInitialLoadState initialLoadState: InlineComponentViewController.InitialLoadState
    )
}

@_spi(DashboardOnly)
public extension InlineComponentViewControllerDelegate {
    func inlineComponentDidExit(_ component: InlineComponentViewController) { }

    func inlineComponent(_ component: InlineComponentViewController,
                         didFailLoadWithError error: Error) { }

    func inlineComponent(_ component: InlineComponentViewController,
                         didChangeContentHeight height: CGFloat) { }

    func inlineComponent(
        _ component: InlineComponentViewController,
        didChangeInitialLoadState initialLoadState: InlineComponentViewController.InitialLoadState
    ) { }
}
