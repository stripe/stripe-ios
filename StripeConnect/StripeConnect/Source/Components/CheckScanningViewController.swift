import UIKit

@_spi(DashboardOnly)
@available(iOS 15, *)
public final class CheckScanningViewController: UIViewController {
    struct Props: HasSupplementalFunctions {
        enum CodingKeys: CodingKey {}
        
        let supplementalFunctions: SupplementalFunctions
    }

    private(set) var webVC: ConnectComponentWebViewController!
    
    public weak var delegate: CheckScanningViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory,
         handleCheckScanSubmitted: @escaping HandleCheckScanSubmittedFn) {
        super.init(nibName: nil, bundle: nil)
        
        let supplementalFunctions = SupplementalFunctions(handleCheckScanSubmitted: handleCheckScanSubmitted)

        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .checkScanning,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            fetchInitProps: { Props(supplementalFunctions: supplementalFunctions)},
            didFailLoadWithError: { [weak self] error in
                guard let self else { return }
                delegate?.checkScanning(self, didFailLoadWithError: error)
            },
        )

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@_spi(DashboardOnly)
@available(iOS 15, *)
public protocol CheckScanningViewControllerDelegate: AnyObject {
    func checkScanning(_ checkScanning: CheckScanningViewController,
                 didFailLoadWithError error: Error)
}

@available(iOS 15, *)
public extension CheckScanningViewControllerDelegate {
    func checkScanning(_ checkScanning: CheckScanningViewController,
                 didFailLoadWithError error: Error) { }
}
