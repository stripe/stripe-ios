import Foundation

public struct Expiry: Hashable {
    public let string: String
    public let month: UInt
    public let year: UInt
    
    public static func == (lhs: Expiry, rhs: Expiry) -> Bool {
        return lhs.string == rhs.string
    }
    
    public func hash(into hasher: inout Hasher) {
        self.string.hash(into: &hasher)
    }
    
    public var hashValue: Int {
        return self.string.hashValue
    }
    
    func display() -> String {
        let twoDigitYear = self.year % 100
        return String(format: "%02d/%02d", self.month, twoDigitYear)
    }
}
