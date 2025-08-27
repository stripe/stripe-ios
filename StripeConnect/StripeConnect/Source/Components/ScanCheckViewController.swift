import UIKit

@_spi(DashboardOnly)
@available(iOS 15, *)
public final class ScanCheckViewController: UIViewController {

    private(set) var webVC: ConnectComponentWebViewController!
    
    public weak var delegate: ScanCheckViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .scanCheck,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) { [weak self] error in
            guard let self else { return }
            delegate?.scanCheck(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func dismiss(animated: Bool = true) {
        webVC.dismiss(animated: animated)
    }

    @objc
    func closeButtonTapped(_ sender: UIBarButtonItem) {
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
public protocol ScanCheckViewControllerDelegate: AnyObject {

    func scanCheck(_ scanCheck: ScanCheckViewController,
                 didFailLoadWithError error: Error)

}

@available(iOS 15, *)
public extension ScanCheckViewControllerDelegate {
    func scanCheck(_ scanCheck: ScanCheckViewController,
                 didFailLoadWithError error: Error) { }
}
