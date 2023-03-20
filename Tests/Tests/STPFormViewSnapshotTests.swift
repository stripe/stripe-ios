//
//  STPFormViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase
import XCTest

@testable import Stripe

class STPFormViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testSingleInput() {
        let input = STPInputTextField(
            formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator())
        input.placeholder = "Single input"
        let section = STPFormView.Section(rows: [[input]], title: nil, accessoryButton: nil)
        let formView = STPFormView(sections: [section])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

    func testSingleInputPerRow() {
        var rows = [[STPInputTextField]]()
        for row in 0..<5 {
            let input = STPInputTextField(
                formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator())
            input.placeholder = "Row \(row)"
            rows.append([input])
        }
        let section = STPFormView.Section(rows: rows, title: nil, accessoryButton: nil)
        let formView = STPFormView(sections: [section])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

    func testMultiInputPerRow() {
        var rows = [[STPInputTextField]]()
        for row in 0..<5 {
            var rowInputs = [STPInputTextField]()
            for c in ["A", "B", "C"] {
                let input = STPInputTextField(
                    formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator()
                )
                input.placeholder = "Row \(row) \(c)"
                rowInputs.append(input)
            }

            rows.append(rowInputs)
        }
        let section = STPFormView.Section(rows: rows, title: nil, accessoryButton: nil)
        let formView = STPFormView(sections: [section])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

    func testMixSingleMultiInputPerRow() {
        var rows = [[STPInputTextField]]()
        for row in 0..<5 {
            var rowInputs = [STPInputTextField]()
            for c in ["A", "B", "C"] {
                let input = STPInputTextField(
                    formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator()
                )
                input.placeholder = "Row \(row) \(c)"
                rowInputs.append(input)
                if row % 2 == 0 {
                    break
                }
            }

            rows.append(rowInputs)
        }
        let section = STPFormView.Section(rows: rows, title: nil, accessoryButton: nil)
        let formView = STPFormView(sections: [section])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

    func testSingleSectionWithTitle() {
        var rows = [[STPInputTextField]]()
        for row in 0..<5 {
            var rowInputs = [STPInputTextField]()
            for c in ["A", "B", "C"] {
                let input = STPInputTextField(
                    formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator()
                )
                input.placeholder = "Row \(row) \(c)"
                rowInputs.append(input)
            }

            rows.append(rowInputs)
        }
        let section = STPFormView.Section(rows: rows, title: "Single Section", accessoryButton: nil)
        let formView = STPFormView(sections: [section])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

    func testMultiSection() {
        var rows1 = [[STPInputTextField]]()
        for row in 0..<5 {
            var rowInputs = [STPInputTextField]()
            for c in ["A", "B", "C"] {
                let input = STPInputTextField(
                    formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator()
                )
                input.placeholder = "Row \(row) \(c)"
                rowInputs.append(input)
            }

            rows1.append(rowInputs)
        }
        let section1 = STPFormView.Section(
            rows: rows1, title: "First Section", accessoryButton: nil)

        var rows2 = [[STPInputTextField]]()
        for row in 0..<5 {
            var rowInputs = [STPInputTextField]()
            for c in ["A", "B", "C"] {
                let input = STPInputTextField(
                    formatter: STPInputTextFieldFormatter(), validator: STPInputTextFieldValidator()
                )
                input.placeholder = "Row \(row) \(c)"
                rowInputs.append(input)
            }

            rows2.append(rowInputs)
        }
        let section2 = STPFormView.Section(
            rows: rows2, title: "Second Section", accessoryButton: nil)

        let formView = STPFormView(sections: [section1, section2])
        formView.frame.size = formView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        STPSnapshotVerifyView(formView)
    }

}
