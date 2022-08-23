//
//  PhoneMetadataProvider.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation

@_spi(STP) import StripeCore

final class PhoneMetadataProvider {

    static let shared: PhoneMetadataProvider = .init()

    /// Metadata entries.
    let metadata: [Metadata]

    /// A lookup table for finding metadata entries by region/country code.
    private lazy var metadataByRegion: [String: Metadata] = {
        return .init(uniqueKeysWithValues: metadata.map { ($0.region, $0) })
    }()

    private init() {
        self.metadata = Self.loadMetadata()
    }

    /// Returns the phone metadata for a given region.
    /// - Parameter region: ISO 3166-1 alpha-2 country code.
    /// - Returns: Metadata entry, or `nil` if not found.
    func metadata(for region: String) -> Metadata? {
        return metadataByRegion[region]
    }

}

// MARK: - Loading

private extension PhoneMetadataProvider {

    static func loadMetadata() -> [Metadata] {
        let resourcesBundle = StripeUICoreBundleLocator.resourcesBundle

        guard let url = resourcesBundle.url(
            forResource: "phone_metadata",
            withExtension: "json.lzfse"
        ) else {
            assertionFailure("phone_metadata.json.lzfse is missing")
            return getFallbackMetadata()
        }

        do {
            let data = try Data.fromLZFSEFile(at: url)

            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode([Metadata].self, from: data)
        } catch {
            assertionFailure(error.localizedDescription)
            return getFallbackMetadata()
        }
    }

    static func getFallbackMetadata() -> [Metadata] {
        return [
            Metadata(region: "US", code: "+1", trunkPrefix: "1"),
            Metadata(region: "AG", code: "+1", trunkPrefix: "1"),
            Metadata(region: "AI", code: "+1", trunkPrefix: "1"),
            Metadata(region: "BB", code: "+1", trunkPrefix: "1"),
            Metadata(region: "BM", code: "+1", trunkPrefix: "1"),
            Metadata(region: "BS", code: "+1", trunkPrefix: "1"),
            Metadata(region: "CA", code: "+1", trunkPrefix: "1"),
            Metadata(region: "DM", code: "+1", trunkPrefix: "1"),
            Metadata(region: "DO", code: "+1", trunkPrefix: "1"),
            Metadata(region: "GD", code: "+1", trunkPrefix: "1"),
            Metadata(region: "GU", code: "+1", trunkPrefix: "1"),
            Metadata(region: "JM", code: "+1", trunkPrefix: "1"),
            Metadata(region: "KN", code: "+1", trunkPrefix: "1"),
            Metadata(region: "KY", code: "+1", trunkPrefix: "1"),
            Metadata(region: "LC", code: "+1", trunkPrefix: "1"),
            Metadata(region: "MS", code: "+1", trunkPrefix: "1"),
            Metadata(region: "PR", code: "+1", trunkPrefix: "1"),
            Metadata(region: "SX", code: "+1", trunkPrefix: "1"),
            Metadata(region: "TC", code: "+1", trunkPrefix: "1"),
            Metadata(region: "TT", code: "+1", trunkPrefix: "1"),
            Metadata(region: "VC", code: "+1", trunkPrefix: "1"),
            Metadata(region: "VG", code: "+1", trunkPrefix: "1"),
            Metadata(region: "EG", code: "+20", trunkPrefix: "0"),
            Metadata(region: "SS", code: "+211", trunkPrefix: "0"),
            Metadata(region: "MA", code: "+212", trunkPrefix: "0"),
            Metadata(region: "EH", code: "+212", trunkPrefix: "0"),
            Metadata(region: "DZ", code: "+213", trunkPrefix: "0"),
            Metadata(region: "TN", code: "+216"),
            Metadata(region: "LY", code: "+218", trunkPrefix: "0"),
            Metadata(region: "GM", code: "+220"),
            Metadata(region: "SN", code: "+221"),
            Metadata(region: "MR", code: "+222"),
            Metadata(region: "ML", code: "+223"),
            Metadata(region: "GN", code: "+224"),
            Metadata(region: "CI", code: "+225"),
            Metadata(region: "BF", code: "+226"),
            Metadata(region: "NE", code: "+227"),
            Metadata(region: "TG", code: "+228"),
            Metadata(region: "BJ", code: "+229"),
            Metadata(region: "MU", code: "+230"),
            Metadata(region: "LR", code: "+231", trunkPrefix: "0"),
            Metadata(region: "SL", code: "+232", trunkPrefix: "0"),
            Metadata(region: "GH", code: "+233", trunkPrefix: "0"),
            Metadata(region: "NG", code: "+234", trunkPrefix: "0"),
            Metadata(region: "TD", code: "+235"),
            Metadata(region: "CF", code: "+236"),
            Metadata(region: "CM", code: "+237"),
            Metadata(region: "CV", code: "+238"),
            Metadata(region: "ST", code: "+239"),
            Metadata(region: "GQ", code: "+240"),
            Metadata(region: "GA", code: "+241"),
            Metadata(region: "CG", code: "+242"),
            Metadata(region: "CD", code: "+243", trunkPrefix: "0"),
            Metadata(region: "AO", code: "+244"),
            Metadata(region: "GW", code: "+245"),
            Metadata(region: "IO", code: "+246"),
            Metadata(region: "AC", code: "+247"),
            Metadata(region: "SC", code: "+248"),
            Metadata(region: "RW", code: "+250", trunkPrefix: "0"),
            Metadata(region: "ET", code: "+251", trunkPrefix: "0"),
            Metadata(region: "SO", code: "+252", trunkPrefix: "0"),
            Metadata(region: "DJ", code: "+253"),
            Metadata(region: "KE", code: "+254", trunkPrefix: "0"),
            Metadata(region: "TZ", code: "+255", trunkPrefix: "0"),
            Metadata(region: "UG", code: "+256", trunkPrefix: "0"),
            Metadata(region: "BI", code: "+257"),
            Metadata(region: "MZ", code: "+258"),
            Metadata(region: "ZM", code: "+260", trunkPrefix: "0"),
            Metadata(region: "MG", code: "+261", trunkPrefix: "0"),
            Metadata(region: "RE", code: "+262", trunkPrefix: "0"),
            Metadata(region: "YT", code: "+262", trunkPrefix: "0"),
            Metadata(region: "ZW", code: "+263", trunkPrefix: "0"),
            Metadata(region: "NA", code: "+264", trunkPrefix: "0"),
            Metadata(region: "MW", code: "+265", trunkPrefix: "0"),
            Metadata(region: "LS", code: "+266"),
            Metadata(region: "BW", code: "+267"),
            Metadata(region: "SZ", code: "+268"),
            Metadata(region: "KM", code: "+269"),
            Metadata(region: "ZA", code: "+27", trunkPrefix: "0"),
            Metadata(region: "SH", code: "+290"),
            Metadata(region: "TA", code: "+290"),
            Metadata(region: "ER", code: "+291", trunkPrefix: "0"),
            Metadata(region: "AW", code: "+297"),
            Metadata(region: "FO", code: "+298"),
            Metadata(region: "GL", code: "+299"),
            Metadata(region: "GR", code: "+30"),
            Metadata(region: "NL", code: "+31", trunkPrefix: "0"),
            Metadata(region: "BE", code: "+32", trunkPrefix: "0"),
            Metadata(region: "FR", code: "+33", trunkPrefix: "0"),
            Metadata(region: "ES", code: "+34"),
            Metadata(region: "GI", code: "+350"),
            Metadata(region: "PT", code: "+351"),
            Metadata(region: "LU", code: "+352"),
            Metadata(region: "IE", code: "+353", trunkPrefix: "0"),
            Metadata(region: "IS", code: "+354"),
            Metadata(region: "AL", code: "+355", trunkPrefix: "0"),
            Metadata(region: "MT", code: "+356"),
            Metadata(region: "CY", code: "+357"),
            Metadata(region: "FI", code: "+358", trunkPrefix: "0"),
            Metadata(region: "AX", code: "+358", trunkPrefix: "0"),
            Metadata(region: "BG", code: "+359", trunkPrefix: "0"),
            Metadata(region: "HU", code: "+36", trunkPrefix: "06"),
            Metadata(region: "LT", code: "+370", trunkPrefix: "8"),
            Metadata(region: "LV", code: "+371"),
            Metadata(region: "EE", code: "+372"),
            Metadata(region: "MD", code: "+373", trunkPrefix: "0"),
            Metadata(region: "AM", code: "+374", trunkPrefix: "0"),
            Metadata(region: "BY", code: "+375", trunkPrefix: "8"),
            Metadata(region: "AD", code: "+376"),
            Metadata(region: "MC", code: "+377", trunkPrefix: "0"),
            Metadata(region: "SM", code: "+378"),
            Metadata(region: "UA", code: "+380", trunkPrefix: "0"),
            Metadata(region: "RS", code: "+381", trunkPrefix: "0"),
            Metadata(region: "ME", code: "+382", trunkPrefix: "0"),
            Metadata(region: "XK", code: "+383", trunkPrefix: "0"),
            Metadata(region: "HR", code: "+385", trunkPrefix: "0"),
            Metadata(region: "SI", code: "+386", trunkPrefix: "0"),
            Metadata(region: "BA", code: "+387", trunkPrefix: "0"),
            Metadata(region: "MK", code: "+389", trunkPrefix: "0"),
            Metadata(region: "IT", code: "+39"),
            Metadata(region: "VA", code: "+39"),
            Metadata(region: "RO", code: "+40", trunkPrefix: "0"),
            Metadata(region: "CH", code: "+41", trunkPrefix: "0"),
            Metadata(region: "CZ", code: "+420"),
            Metadata(region: "SK", code: "+421", trunkPrefix: "0"),
            Metadata(region: "LI", code: "+423", trunkPrefix: "0"),
            Metadata(region: "AT", code: "+43", trunkPrefix: "0"),
            Metadata(region: "GB", code: "+44", trunkPrefix: "0"),
            Metadata(region: "GG", code: "+44", trunkPrefix: "0"),
            Metadata(region: "IM", code: "+44", trunkPrefix: "0"),
            Metadata(region: "JE", code: "+44", trunkPrefix: "0"),
            Metadata(region: "DK", code: "+45"),
            Metadata(region: "SE", code: "+46", trunkPrefix: "0"),
            Metadata(region: "NO", code: "+47"),
            Metadata(region: "SJ", code: "+47"),
            Metadata(region: "PL", code: "+48"),
            Metadata(region: "DE", code: "+49", trunkPrefix: "0"),
            Metadata(region: "FK", code: "+500"),
            Metadata(region: "BZ", code: "+501"),
            Metadata(region: "GT", code: "+502"),
            Metadata(region: "SV", code: "+503"),
            Metadata(region: "HN", code: "+504"),
            Metadata(region: "NI", code: "+505"),
            Metadata(region: "CR", code: "+506"),
            Metadata(region: "PA", code: "+507"),
            Metadata(region: "PM", code: "+508", trunkPrefix: "0"),
            Metadata(region: "HT", code: "+509"),
            Metadata(region: "PE", code: "+51", trunkPrefix: "0"),
            Metadata(region: "MX", code: "+52", trunkPrefix: "01"),
            Metadata(region: "AR", code: "+54", trunkPrefix: "0"),
            Metadata(region: "BR", code: "+55", trunkPrefix: "0"),
            Metadata(region: "CL", code: "+56"),
            Metadata(region: "CO", code: "+57", trunkPrefix: "0"),
            Metadata(region: "VE", code: "+58", trunkPrefix: "0"),
            Metadata(region: "GP", code: "+590", trunkPrefix: "0"),
            Metadata(region: "BL", code: "+590", trunkPrefix: "0"),
            Metadata(region: "MF", code: "+590", trunkPrefix: "0"),
            Metadata(region: "BO", code: "+591", trunkPrefix: "0"),
            Metadata(region: "GY", code: "+592"),
            Metadata(region: "EC", code: "+593", trunkPrefix: "0"),
            Metadata(region: "GF", code: "+594", trunkPrefix: "0"),
            Metadata(region: "PY", code: "+595", trunkPrefix: "0"),
            Metadata(region: "MQ", code: "+596", trunkPrefix: "0"),
            Metadata(region: "SR", code: "+597"),
            Metadata(region: "UY", code: "+598", trunkPrefix: "0"),
            Metadata(region: "CW", code: "+599"),
            Metadata(region: "BQ", code: "+599"),
            Metadata(region: "MY", code: "+60", trunkPrefix: "0"),
            Metadata(region: "AU", code: "+61", trunkPrefix: "0"),
            Metadata(region: "ID", code: "+62", trunkPrefix: "0"),
            Metadata(region: "PH", code: "+63", trunkPrefix: "0"),
            Metadata(region: "NZ", code: "+64", trunkPrefix: "0"),
            Metadata(region: "SG", code: "+65"),
            Metadata(region: "TH", code: "+66", trunkPrefix: "0"),
            Metadata(region: "TL", code: "+670"),
            Metadata(region: "BN", code: "+673"),
            Metadata(region: "NR", code: "+674"),
            Metadata(region: "PG", code: "+675"),
            Metadata(region: "TO", code: "+676"),
            Metadata(region: "SB", code: "+677"),
            Metadata(region: "VU", code: "+678"),
            Metadata(region: "FJ", code: "+679"),
            Metadata(region: "WF", code: "+681"),
            Metadata(region: "CK", code: "+682"),
            Metadata(region: "NU", code: "+683"),
            Metadata(region: "WS", code: "+685"),
            Metadata(region: "KI", code: "+686", trunkPrefix: "0"),
            Metadata(region: "NC", code: "+687"),
            Metadata(region: "TV", code: "+688"),
            Metadata(region: "PF", code: "+689"),
            Metadata(region: "TK", code: "+690"),
            Metadata(region: "RU", code: "+7", trunkPrefix: "8"),
            Metadata(region: "KZ", code: "+7", trunkPrefix: "8"),
            Metadata(region: "JP", code: "+81", trunkPrefix: "0"),
            Metadata(region: "KR", code: "+82", trunkPrefix: "0"),
            Metadata(region: "VN", code: "+84", trunkPrefix: "0"),
            Metadata(region: "HK", code: "+852"),
            Metadata(region: "MO", code: "+853"),
            Metadata(region: "KH", code: "+855", trunkPrefix: "0"),
            Metadata(region: "LA", code: "+856", trunkPrefix: "0"),
            Metadata(region: "CN", code: "+86", trunkPrefix: "0"),
            Metadata(region: "BD", code: "+880", trunkPrefix: "0"),
            Metadata(region: "TW", code: "+886", trunkPrefix: "0"),
            Metadata(region: "TR", code: "+90", trunkPrefix: "0"),
            Metadata(region: "IN", code: "+91", trunkPrefix: "0"),
            Metadata(region: "PK", code: "+92", trunkPrefix: "0"),
            Metadata(region: "AF", code: "+93", trunkPrefix: "0"),
            Metadata(region: "LK", code: "+94", trunkPrefix: "0"),
            Metadata(region: "MM", code: "+95", trunkPrefix: "0"),
            Metadata(region: "MV", code: "+960"),
            Metadata(region: "LB", code: "+961", trunkPrefix: "0"),
            Metadata(region: "JO", code: "+962", trunkPrefix: "0"),
            Metadata(region: "IQ", code: "+964", trunkPrefix: "0"),
            Metadata(region: "KW", code: "+965"),
            Metadata(region: "SA", code: "+966", trunkPrefix: "0"),
            Metadata(region: "YE", code: "+967", trunkPrefix: "0"),
            Metadata(region: "OM", code: "+968"),
            Metadata(region: "PS", code: "+970", trunkPrefix: "0"),
            Metadata(region: "AE", code: "+971", trunkPrefix: "0"),
            Metadata(region: "IL", code: "+972", trunkPrefix: "0"),
            Metadata(region: "BH", code: "+973"),
            Metadata(region: "QA", code: "+974"),
            Metadata(region: "BT", code: "+975"),
            Metadata(region: "MN", code: "+976", trunkPrefix: "0"),
            Metadata(region: "NP", code: "+977", trunkPrefix: "0"),
            Metadata(region: "TJ", code: "+992"),
            Metadata(region: "TM", code: "+993", trunkPrefix: "8"),
            Metadata(region: "AZ", code: "+994", trunkPrefix: "0"),
            Metadata(region: "GE", code: "+995", trunkPrefix: "0"),
            Metadata(region: "KG", code: "+996", trunkPrefix: "0"),
            Metadata(region: "UZ", code: "+998", trunkPrefix: "8")
        ]
    }

}
