//
//  OneTimeCodeTextFieldTests.swift
//  StripeUICoreTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) @testable import StripeUICore
import UIKit
import XCTest

final class OneTimeCodeTextFieldTests: XCTestCase {

    func testItemsFillFieldWithoutMaxWidth() {
        // Given a field without a maximum item width
        let field = makeField(configuration: .init(enableDigitGrouping: false))

        // When it lays out wider than its items need
        layout(field, width: 400)

        // Then the items stretch to fill the field
        let frames = digitFrames(in: field)
        XCTAssertEqual(frames.first?.minX ?? -1, 0, accuracy: 0.5)
        XCTAssertEqual(frames.last?.maxX ?? -1, 400, accuracy: 0.5)
        XCTAssertGreaterThan(frames.first?.width ?? 0, 48)
    }

    func testItemsAreCappedAndCenteredWithMaxWidth() {
        // Given a field whose items are capped at 48 points
        let field = makeField(configuration: .init(enableDigitGrouping: false, itemMaxWidth: 48))

        // When it lays out wider than its capped items need
        layout(field, width: 400)

        // Then every item is 48 points wide and the row is centered
        let frames = digitFrames(in: field)
        XCTAssertEqual(frames.count, 6)
        for frame in frames {
            XCTAssertEqual(frame.width, 48, accuracy: 0.5)
        }
        let leadingInset = frames.first?.minX ?? -1
        let trailingInset = 400 - (frames.last?.maxX ?? -1)
        XCTAssertGreaterThan(leadingInset, 0)
        XCTAssertEqual(leadingInset, trailingInset, accuracy: 0.5)
    }

    func testItemsShrinkBelowMaxWidthInNarrowField() {
        // Given a field whose items are capped at 48 points
        let field = makeField(configuration: .init(enableDigitGrouping: false, itemMaxWidth: 48))

        // When it lays out narrower than the capped items need
        layout(field, width: 240)

        // Then the items shrink to fill the field
        let frames = digitFrames(in: field)
        XCTAssertEqual(frames.first?.minX ?? -1, 0, accuracy: 0.5)
        XCTAssertEqual(frames.last?.maxX ?? -1, 240, accuracy: 0.5)
        XCTAssertLessThan(frames.first?.width ?? .infinity, 48)
    }

    private func makeField(configuration: OneTimeCodeTextField.Configuration) -> OneTimeCodeTextField {
        return OneTimeCodeTextField(configuration: configuration, theme: .default)
    }

    private func layout(_ field: OneTimeCodeTextField, width: CGFloat) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 100))
        container.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        container.layoutIfNeeded()
    }

    private func digitFrames(in field: OneTimeCodeTextField) -> [CGRect] {
        // Without digit grouping, the digit views are the arranged subviews of the field's stack view.
        let stackView = field.subviews.compactMap { $0 as? UIStackView }.first
        return (stackView?.arrangedSubviews ?? []).map { $0.convert($0.bounds, to: field) }
    }
}
