//
//  LocaleExtensionTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/8/24.
//

@testable import StripeConnect
import XCTest

class LocaleExtensionTests: XCTestCase {
    func testWebIdentifier() {
        XCTAssertEqual(Locale(identifier: "en").webIdentifier, "en")
        XCTAssertEqual(Locale(identifier: "en_GB").webIdentifier, "en-GB")

        // Chinese languages, region not specified
        XCTAssertEqual(Locale(identifier: "zh").webIdentifier, "zh")
        XCTAssertEqual(Locale(identifier: "zh-Hans").webIdentifier, "zh-Hans")
        XCTAssertEqual(Locale(identifier: "zh-Hant").webIdentifier, "zh-Hant")

        // Language=Simplified Chinese, region=China Mainland
        XCTAssertEqual(Locale(identifier: "zh_CN").webIdentifier, "zh-Hans-CN")
        XCTAssertEqual(Locale(identifier: "zh-Hans_CN").webIdentifier, "zh-Hans-CN")

        // Language=Simplified Chinese, region=Taiwan
        XCTAssertEqual(Locale(identifier: "zh-Hans_TW").webIdentifier, "zh-Hans-TW")

        // Language=Simplified Chinese, region=Hong Kong
        XCTAssertEqual(Locale(identifier: "zh-Hans_HK").webIdentifier, "zh-Hans-HK")

        // Language=Traditional Chinese, region=China Mainland
        XCTAssertEqual(Locale(identifier: "zh-Hant_CN").webIdentifier, "zh-Hant-CN")

        // Language=Traditional Chinese, region=Taiwan
        XCTAssertEqual(Locale(identifier: "zh_TW").webIdentifier, "zh-Hant-TW")
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW").webIdentifier, "zh-Hant-TW")

        // Language=Traditional Chinese, region=Hong Kong
        XCTAssertEqual(Locale(identifier: "zh_HK").webIdentifier, "zh-Hant-HK")
        XCTAssertEqual(Locale(identifier: "zh-Hant_HK").webIdentifier, "zh-Hant-HK")
    }

    /// On iOS 16+, the device region may be different from the language region
    func testWebIdentifierUsesLanguageRegion() {
        guard #available(iOS 16, *) else { return }

        // Language=English (UK), region=United States
        XCTAssertEqual(Locale(identifier: "en_GB@rg=uszzzz").webIdentifier, "en-GB")

        // Language=Portuguese (Brazil), region=Portugal
        XCTAssertEqual(Locale(identifier: "pt_BR@rg=ptzzzz").webIdentifier, "pt-BR")

        // Language=Traditional Chinese (Taiwan), region=China
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW@rg=cnzzzz").webIdentifier, "zh-Hant-TW")

        // Language=Traditional Chinese (Taiwan), region=Hong Kong
        XCTAssertEqual(Locale(identifier: "zh-Hant_TW@rg=hkzzzz").webIdentifier, "zh-Hant-TW")
    }
}

extension Locale {
    @available(iOS 16, *)
    init(languageCode: LanguageCode? = nil, script: Script? = nil, languageRegion: Region? = nil, region: Region?) {
        var components = Components(languageCode: languageCode, script: script, languageRegion: languageRegion)
        components.region = region
        self.init(components: components)
    }
}
