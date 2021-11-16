import Foundation

extension String {
    func localize() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: StripeCardScanBundleLocator.resourcesBundle, value: self, comment: self)
    }
}
