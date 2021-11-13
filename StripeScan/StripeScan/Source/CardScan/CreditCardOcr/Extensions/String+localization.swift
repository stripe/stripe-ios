import Foundation

extension String {
    func localize() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: StripeScanBundleLocator.resourcesBundle, value: self, comment: self)
    }
}
