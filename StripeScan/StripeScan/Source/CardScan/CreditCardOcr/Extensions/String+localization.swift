import Foundation

extension String {
    func localize() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: CSBundle.bundle() ?? Bundle.main, value: self, comment: self)
    }
}
