import UIKit

@_spi(DashboardOnly)
@available(iOS 15, *)
public final class CheckScanningController {
    struct Props: HasSupplementalFunctions {
        enum CodingKeys: CodingKey {}

        let supplementalFunctions: SupplementalFunctions
    }

    private(set) var webVC: ConnectComponentWebViewController!

    var retainedSelf: CheckScanningController?

    public weak var delegate: CheckScanningControllerDelegate?

    public var title: String? {
        get {
            webVC.title
        }
        set {
            webVC.title = newValue
        }
    }

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory,
         handleCheckScanSubmitted: @escaping HandleCheckScanSubmittedFn) {
        let supplementalFunctions = SupplementalFunctions(handleCheckScanSubmitted: handleCheckScanSubmitted)

        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .checkScanning,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            fetchInitProps: { Props(supplementalFunctions: supplementalFunctions) },
            didFailLoadWithError: { [weak self] error in
                guard let self else { return }
                delegate?.checkScanning(self, didFailLoadWithError: error)
            }
        )
    }

    public func present(from viewController: UIViewController, animated: Bool = true) {
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

@_spi(DashboardOnly)
@available(iOS 15, *)
public protocol CheckScanningControllerDelegate: AnyObject {
    func checkScanning(_ checkScanning: CheckScanningController,
                       didFailLoadWithError error: Error)
}

@available(iOS 15, *)
public extension CheckScanningControllerDelegate {
    func checkScanning(_ checkScanning: CheckScanningController,
                       didFailLoadWithError error: Error) { }
}
