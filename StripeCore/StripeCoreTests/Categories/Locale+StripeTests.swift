//
//  Locale+StripeTests.swift
//  StripeCore
//
//  Created by Mel Ludowise on 10/11/24.
//

@_spi(STP) import StripeCore
import XCTest

class Locale_StripeTests: XCTestCase {
    func testLanguageTag() {
        // Language=English, region not specified
        XCTAssertEqual(Locale(identifier: "en").toLanguageTag(), "en")
        XCTAssertEqual(Locale(identifier: "en_GB").toLanguageTag(), "en-GB")

        // Language=English, region=US, calendar=Japanese
        XCTAssertEqual(Locale(identifier: "en_US@calendar=japanese").toLanguageTag(), "en-US")

        // Chinese languages, region not specified
        XCTAssertEqual(Locale(identifier: "zh").toLanguageTag(), "zh")
        XCTAssertEqual(Locale(identifier: "zh-Hans").toLanguageTag(), "zh-Hans")
        XCTAssertEqual(Locale(identifier: "zh-Hant").toLanguageTag(), "zh-Hant")

        // Language=Simplified Chinese, region=China mainland
        XCTAssertEqual(Locale(identifier: "zh_CN").toLanguageTag(), "zh-Hans")
        XCTAssertEqual(Locale(identifier: "zh-Hans_CN").toLanguageTag(), "zh-Hans")

        // Language=Simplified Chinese, region=Taiwan (China)
        XCTAssertEqual(Locale(identifier: "zh-Hans_TW").toLanguageTag(), "zh-Hans-TW")

        // Language=Simplified Chinese, region=Hong Kong (China)
        XCTAssertEqual(Locale(identifier: "zh-Hans_HK").toLanguageTag(), "zh-Hans-HK")

        // Language=Traditional Chinese, region=China Mainland
        XCTAssertEqual(Locale(identifier: "zh-Hant_CN").toLanguageTag(), "zh-Hant-CN")

        // Language=Traditional Chinese, region=Taiwan (China)
        XCTAssertEqual(Locale(identifier: "zh_TW").toLanguageTag(), "zh-Hant")
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW").toLanguageTag(), "zh-Hant")

        // Language=Traditional Chinese, region=Hong Kong (China)
        XCTAssertEqual(Locale(identifier: "zh_HK").toLanguageTag(), "zh-Hant-HK")
        XCTAssertEqual(Locale(identifier: "zh-Hant_HK").toLanguageTag(), "zh-Hant-HK")
    }

    /// On iOS 16+, the device region may be different from the language region
    /// The `@rg={region-code}zzzz` indicates the device region when it's different from the language region
    func testLanguageTag_languageRegionDifferentFromDevice() {
        // Language=English (UK), region=United States
        XCTAssertEqual(Locale(identifier: "en_GB@rg=uszzzz").toLanguageTag(), "en-GB")

        // Language=Portuguese (Brazil), region=Portugal
        XCTAssertEqual(Locale(identifier: "pt_BR@rg=ptzzzz").toLanguageTag(), "pt-BR")

        // Language=Simplified Chinese, region=Hong Kong (China)
        XCTAssertEqual(Locale(identifier: "zh-Hans@rg=hkzzzz").toLanguageTag(), "zh-Hans")

        // Language=Simplified Chinese, region=Taiwan (China)
        XCTAssertEqual(Locale(identifier: "zh-Hans@rg=twzzzz").toLanguageTag(), "zh-Hans")

        // Language=Traditional Chinese (Taiwan), region=China mainland
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW@rg=cnzzzz").toLanguageTag(), "zh-Hant")

        // Language=Traditional Chinese (Taiwan), region=Hong Kong (China)
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW@rg=hkzzzz").toLanguageTag(), "zh-Hant")

        // Language=Traditional Chinese (Hong Kong), region=Taiwan (China)
        XCTAssertEqual(Locale(identifier: "zh-Hant_HK@rg=twzzzz").toLanguageTag(), "zh-Hant-HK")

        // Language=Traditional Chinese (Hong Kong), region=China mainland
        XCTAssertEqual(Locale(identifier: "zh-Hant_HK@rg=cnzzzz").toLanguageTag(), "zh-Hant-HK")
    }
}
