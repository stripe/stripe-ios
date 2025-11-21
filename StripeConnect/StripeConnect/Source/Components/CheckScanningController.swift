import UIKit

/// A view controller representing a check-scanning component
/// - Seealso: [Check scanning component documentation](https://docs.stripe.com/connect/supported-embedded-components/check-scanning?platform=ios)
@_spi(PrivatePreviewConnect)
@available(iOS 15, *)
public final class CheckScanningController {
    typealias HandleCheckScanSubmittedFn = (CheckScanDetails) async throws -> Void

    /// Contains details about a check scan
    public struct CheckScanDetails: Decodable, Equatable {
        /// Token identifying the check scan, see [UsPaperCheck](https://docs.stripe.com/api/us-paper-check)
        public let checkScanToken: String

        public init(checkScanToken: String) {
            self.checkScanToken = checkScanToken
        }
    }

    struct Props: HasSupplementalFunctions {
        enum CodingKeys: CodingKey {}

        let supplementalFunctions: SupplementalFunctions
    }

    private(set) var webVC: ConnectComponentWebViewController!

    var retainedSelf: CheckScanningController?

    public var delegate: CheckScanningControllerDelegate?

    /// Sets the title for the check scanning experience
    public var title: String? {
        get {
            webVC.title
        }
        set {
            webVC.title = newValue
        }
    }

    enum CallbackError: Error {
       case controllerDisappeared
    }

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        let supplementalFunctions = SupplementalFunctions(handleCheckScanSubmitted: { [weak self] details in
              guard let self = self else {
                 assertionFailure()
                 throw CallbackError.controllerDisappeared
              }
              try await self.delegate!.checkScanning(self, didSubmitCheckScan: details)
        })

        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .checkScanning,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            fetchInitProps: { Props(supplementalFunctions: supplementalFunctions) },
            didFailLoadWithError: { [weak self] error in
                guard let self else { return }
                delegate!.checkScanning(self, didFailLoadWithError: error)
            }
        )
    }

    enum DelegateError: Error {
        case delegateNotSet
    }

    /// Presents the check scanning experience
    public func present(from viewController: UIViewController, animated: Bool = true) throws {
        if self.delegate == nil {
            throw DelegateError.delegateNotSet
        }

        let navController = UINavigationController(rootViewController: webVC)
        navController.navigationBar.prefersLargeTitles = false
        navController.modalPresentationStyle = .fullScreen
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .done,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.accessibilityIdentifier = "closeButton"

        webVC.navigationItem.rightBarButtonItem = closeButton
        viewController.present(navController, animated: animated)
        retainedSelf = self
        webVC.onDismiss = { [weak self] in
            guard let self else { return }
            self.retainedSelf = nil
        }
    }

    /// Dismisses the currently presented check scanning experience.
    /// No-ops if not presented.
    public func dismiss(animated: Bool = true) {
        webVC.dismiss(animated: animated)
    }

    @objc
    func closeButtonTapped() {
        Task { @MainActor in
            do {
                try await self.webVC.sendMessageAsync(MobileInputReceivedSender())
            } catch {
                self.dismiss()
            }
        }
    }
}

@_spi(PrivatePreviewConnect)
@available(iOS 15, *)
public protocol CheckScanningControllerDelegate: AnyObject {
    /// Called when the component fails to load (e.g., network issue during initial fetch). To try again, initialize a new CheckScanningController.
    func checkScanning(_ checkScanning: CheckScanningController,
                       didFailLoadWithError error: Error)

    /// Called when the check scanning process is complete with a check in the `verified` or `manual_review` states.
    /// If this function throws an Error, then the user will be given an opportunity to submit the check again, effectively resulting in a retry of this function.
    /// When this function is complete, a default success screen will be displayed and the modal will remain presented to the user.
    /// You should dismiss the modal explicitly and present your own custom success screen before returning.
    /// See [Check scanning component documentation](https://docs.stripe.com/connect/supported-embedded-components/check-scanning?platform=ios) for further discussion.
    func checkScanning(_ checkScanning: CheckScanningController,
                       didSubmitCheckScan: CheckScanningController.CheckScanDetails) async throws
}

@available(iOS 15, *)
public extension CheckScanningControllerDelegate {
    func checkScanning(_ checkScanning: CheckScanningController,
                       didFailLoadWithError error: Error) { }
}
