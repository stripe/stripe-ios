//
//  STPFloatingPlaceholderTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/9/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPFloatingPlaceholderTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    // MARK: Not Floating

    func testNotFloating_noBackground() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_whiteBackground() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_roundedRectBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_bezelBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_lineBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    // MARK: Floating

    func testFloating_noBackground() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_whiteBackground() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_roundedRectBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_bezelBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_lineBorderStyle() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    // MARK: Right/Left Views Not Floating

    func testNotFloating_noBackground_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_whiteBackground_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_roundedRectBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_bezelBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_lineBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_noBackground_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_whiteBackground_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_roundedRectBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_bezelBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_lineBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_noBackground_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_whiteBackground_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_roundedRectBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_bezelBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testNotFloating_lineBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    // MARK: Right/Left Views Floating

    func testFloating_noBackground_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_whiteBackground_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_roundedRectBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_bezelBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_lineBorderStyle_rightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_noBackground_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_whiteBackground_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_roundedRectBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_bezelBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_lineBorderStyle_leftView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_noBackground_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_whiteBackground_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.backgroundColor = .white
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_roundedRectBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .roundedRect
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_bezelBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .bezel
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }

    func testFloating_lineBorderStyle_leftRightView() {
        let textField: STPFloatingPlaceholderTextField = STPFloatingPlaceholderTextField()
        textField.placeholder = "Test Placeholder"
        textField.text = "Input Text"
        textField.leftView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.leftViewMode = .always
        textField.rightView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        textField.rightViewMode = .always
        textField.borderStyle = .line
        textField.sizeToFit()
        STPSnapshotVerifyView(textField)
    }
}
