//
//  TextFieldFormatterTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 9/28/21.
//

import XCTest
@_spi(STP) @testable import StripeUICore

final class TextFieldFormatterTest: XCTestCase {
    // TODO: Test that we don't get lagging characters (e.g. `###-##-` should always drop the last `-` when formatted

    func testInvalidFormat() {
        // Formats are required to contain at least one `#` or `*`
        XCTAssertNil(TextFieldFormatter(format: ""))
        XCTAssertNil(TextFieldFormatter(format: "•••"))
    }

    func testApplyFormat() {
        // Don't format empty string
        verifyFormat(format: "###-###-###", input: "", expectedOutput: "")
        // Discard unwanted characters
        verifyFormat(format: "###-###-###", input: "12ab3", expectedOutput: "123")
        // Trim to size
        verifyFormat(format: "###-###-###", input: "1234567890000", expectedOutput: "123-456-789")
        // Partial format
        verifyFormat(format: "###-###-###", input: "12345", expectedOutput: "123-45")
        // Don't display lagging format characters
        verifyFormat(format: "###-###-###", input: "123456", expectedOutput: "123-456")
        // Already formatted
        verifyFormat(format: "###-###-###", input: "123-456-789", expectedOutput: "123-456-789")

        // Letters
        verifyFormat(format: "**####-###", input: "", expectedOutput: "")
        verifyFormat(format: "**####-###", input: "12ab3", expectedOutput: "ab3")
        verifyFormat(format: "**####-###", input: "ab123456789", expectedOutput: "ab1234-567")
        verifyFormat(format: "**####-###", input: "ab12345", expectedOutput: "ab1234-5")
        verifyFormat(format: "**####-###", input: "ab1234", expectedOutput: "ab1234")

        // Leading formatting
        verifyFormat(format: "••• - •• - ####", input: "", expectedOutput: "")
        verifyFormat(format: "••• - •• - ####", input: "abc123", expectedOutput: "••• - •• - 123")
        verifyFormat(format: "••• - •• - ####", input: "123456", expectedOutput: "••• - •• - 1234")
    }

    func testNoLaggingFormatCharacters() {
        // Note: If a format has non `*` or `#` characters at the end, they will
        // never be displayed. This is by design since it makes it impossible to
        // use the backspace key because TextFieldView will keep reformatting
        // and moving the cursor. We should never use a format like this, but
        // if we inadvertantly do, we want to ensure we don't break the
        // backspace key behavior.
        verifyFormat(format: "### - ## - •••", input: "12345", expectedOutput: "123 - 45")
        verifyFormat(format: "### - ## - •••", input: "123456789", expectedOutput: "123 - 45")
    }
}

// MARK: - Helpers

private extension TextFieldFormatterTest {
    func verifyFormat(format: String,
                      input: String,
                      expectedOutput: String,
                      file: StaticString = #filePath,
                      line: UInt = #line) {
        XCTAssertEqual(TextFieldFormatter(format: format)?.applyFormat(to: input), expectedOutput, file: file, line: line)
    }
}
