@testable @_spi(STP) import StripeFinancialConnections
import UIKit
import XCTest

final class FinancialConnectionsAppearanceTests: XCTestCase {
    override func tearDown() {
        PresentationManager.shared.configuration = .init()
        super.tearDown()
    }

    func testBackgroundResolvesToWhiteInLightMode() {
        let traits = UITraitCollection(userInterfaceStyle: .light)

        let background = FinancialConnectionsAppearance.Colors.background.resolvedColor(with: traits)

        XCTAssertEqual(background.hexString, "#FFFFFF")
    }

    func testBackgroundResolvesToDarkNeutralInDarkMode() {
        let traits = UITraitCollection(userInterfaceStyle: .dark)

        let background = FinancialConnectionsAppearance.Colors.background.resolvedColor(with: traits)

        XCTAssertEqual(background.hexString, "#171717")
    }
}

private extension UIColor {
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: nil) else {
            return nil
        }
        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
