import Foundation

struct Expiry: Hashable {
    let string: String
    let month: UInt
    let year: UInt
    
    static func == (lhs: Expiry, rhs: Expiry) -> Bool {
        return lhs.string == rhs.string
    }
    
    func hash(into hasher: inout Hasher) {
        self.string.hash(into: &hasher)
    }
    
    var hashValue: Int {
        return self.string.hashValue
    }
    
    func display() -> String {
        let twoDigitYear = self.year % 100
        return String(format: "%02d/%02d", self.month, twoDigitYear)
    }
}
