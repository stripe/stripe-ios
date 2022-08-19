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
        let data: [(String, Int, String?)] = [
            ("US", 1, "1"),
            ("AG", 1, "1"),
            ("AI", 1, "1"),
            ("AS", 1, "1"),
            ("BB", 1, "1"),
            ("BM", 1, "1"),
            ("BS", 1, "1"),
            ("CA", 1, "1"),
            ("DM", 1, "1"),
            ("DO", 1, "1"),
            ("GD", 1, "1"),
            ("GU", 1, "1"),
            ("JM", 1, "1"),
            ("KN", 1, "1"),
            ("KY", 1, "1"),
            ("LC", 1, "1"),
            ("MP", 1, "1"),
            ("MS", 1, "1"),
            ("PR", 1, "1"),
            ("SX", 1, "1"),
            ("TC", 1, "1"),
            ("TT", 1, "1"),
            ("VC", 1, "1"),
            ("VG", 1, "1"),
            ("VI", 1, "1"),
            ("EG", 20, "0"),
            ("SS", 211, "0"),
            ("MA", 212, "0"),
            ("EH", 212, "0"),
            ("DZ", 213, "0"),
            ("TN", 216, nil),
            ("LY", 218, "0"),
            ("GM", 220, nil),
            ("SN", 221, nil),
            ("MR", 222, nil),
            ("ML", 223, nil),
            ("GN", 224, nil),
            ("CI", 225, nil),
            ("BF", 226, nil),
            ("NE", 227, nil),
            ("TG", 228, nil),
            ("BJ", 229, nil),
            ("MU", 230, nil),
            ("LR", 231, "0"),
            ("SL", 232, "0"),
            ("GH", 233, "0"),
            ("NG", 234, "0"),
            ("TD", 235, nil),
            ("CF", 236, nil),
            ("CM", 237, nil),
            ("CV", 238, nil),
            ("ST", 239, nil),
            ("GQ", 240, nil),
            ("GA", 241, nil),
            ("CG", 242, nil),
            ("CD", 243, "0"),
            ("AO", 244, nil),
            ("GW", 245, nil),
            ("IO", 246, nil),
            ("AC", 247, nil),
            ("SC", 248, nil),
            ("SD", 249, "0"),
            ("RW", 250, "0"),
            ("ET", 251, "0"),
            ("SO", 252, "0"),
            ("DJ", 253, nil),
            ("KE", 254, "0"),
            ("TZ", 255, "0"),
            ("UG", 256, "0"),
            ("BI", 257, nil),
            ("MZ", 258, nil),
            ("ZM", 260, "0"),
            ("MG", 261, "0"),
            ("RE", 262, "0"),
            ("YT", 262, "0"),
            ("ZW", 263, "0"),
            ("NA", 264, "0"),
            ("MW", 265, "0"),
            ("LS", 266, nil),
            ("BW", 267, nil),
            ("SZ", 268, nil),
            ("KM", 269, nil),
            ("ZA", 27, "0"),
            ("SH", 290, nil),
            ("TA", 290, nil),
            ("ER", 291, "0"),
            ("AW", 297, nil),
            ("FO", 298, nil),
            ("GL", 299, nil),
            ("GR", 30, nil),
            ("NL", 31, "0"),
            ("BE", 32, "0"),
            ("FR", 33, "0"),
            ("ES", 34, nil),
            ("GI", 350, nil),
            ("PT", 351, nil),
            ("LU", 352, nil),
            ("IE", 353, "0"),
            ("IS", 354, nil),
            ("AL", 355, "0"),
            ("MT", 356, nil),
            ("CY", 357, nil),
            ("FI", 358, "0"),
            ("AX", 358, "0"),
            ("BG", 359, "0"),
            ("HU", 36, "06"),
            ("LT", 370, "8"),
            ("LV", 371, nil),
            ("EE", 372, nil),
            ("MD", 373, "0"),
            ("AM", 374, "0"),
            ("BY", 375, "8"),
            ("AD", 376, nil),
            ("MC", 377, "0"),
            ("SM", 378, nil),
            ("UA", 380, "0"),
            ("RS", 381, "0"),
            ("ME", 382, "0"),
            ("XK", 383, "0"),
            ("HR", 385, "0"),
            ("SI", 386, "0"),
            ("BA", 387, "0"),
            ("MK", 389, "0"),
            ("IT", 39, nil),
            ("VA", 39, nil),
            ("RO", 40, "0"),
            ("CH", 41, "0"),
            ("CZ", 420, nil),
            ("SK", 421, "0"),
            ("LI", 423, "0"),
            ("AT", 43, "0"),
            ("GB", 44, "0"),
            ("GG", 44, "0"),
            ("IM", 44, "0"),
            ("JE", 44, "0"),
            ("DK", 45, nil),
            ("SE", 46, "0"),
            ("NO", 47, nil),
            ("SJ", 47, nil),
            ("PL", 48, nil),
            ("DE", 49, "0"),
            ("FK", 500, nil),
            ("BZ", 501, nil),
            ("GT", 502, nil),
            ("SV", 503, nil),
            ("HN", 504, nil),
            ("NI", 505, nil),
            ("CR", 506, nil),
            ("PA", 507, nil),
            ("PM", 508, "0"),
            ("HT", 509, nil),
            ("PE", 51, "0"),
            ("MX", 52, "01"),
            ("CU", 53, "0"),
            ("AR", 54, "0"),
            ("BR", 55, "0"),
            ("CL", 56, nil),
            ("CO", 57, "0"),
            ("VE", 58, "0"),
            ("GP", 590, "0"),
            ("BL", 590, "0"),
            ("MF", 590, "0"),
            ("BO", 591, "0"),
            ("GY", 592, nil),
            ("EC", 593, "0"),
            ("GF", 594, "0"),
            ("PY", 595, "0"),
            ("MQ", 596, "0"),
            ("SR", 597, nil),
            ("UY", 598, "0"),
            ("CW", 599, nil),
            ("BQ", 599, nil),
            ("MY", 60, "0"),
            ("AU", 61, "0"),
            ("CC", 61, "0"),
            ("CX", 61, "0"),
            ("ID", 62, "0"),
            ("PH", 63, "0"),
            ("NZ", 64, "0"),
            ("SG", 65, nil),
            ("TH", 66, "0"),
            ("TL", 670, nil),
            ("NF", 672, nil),
            ("BN", 673, nil),
            ("NR", 674, nil),
            ("PG", 675, nil),
            ("TO", 676, nil),
            ("SB", 677, nil),
            ("VU", 678, nil),
            ("FJ", 679, nil),
            ("PW", 680, nil),
            ("WF", 681, nil),
            ("CK", 682, nil),
            ("NU", 683, nil),
            ("WS", 685, nil),
            ("KI", 686, "0"),
            ("NC", 687, nil),
            ("TV", 688, nil),
            ("PF", 689, nil),
            ("TK", 690, nil),
            ("FM", 691, nil),
            ("MH", 692, "1"),
            ("RU", 7, "8"),
            ("KZ", 7, "8"),
            ("JP", 81, "0"),
            ("KR", 82, "0"),
            ("VN", 84, "0"),
            ("KP", 850, "0"),
            ("HK", 852, nil),
            ("MO", 853, nil),
            ("KH", 855, "0"),
            ("LA", 856, "0"),
            ("CN", 86, "0"),
            ("BD", 880, "0"),
            ("TW", 886, "0"),
            ("TR", 90, "0"),
            ("IN", 91, "0"),
            ("PK", 92, "0"),
            ("AF", 93, "0"),
            ("LK", 94, "0"),
            ("MM", 95, "0"),
            ("MV", 960, nil),
            ("LB", 961, "0"),
            ("JO", 962, "0"),
            ("SY", 963, "0"),
            ("IQ", 964, "0"),
            ("KW", 965, nil),
            ("SA", 966, "0"),
            ("YE", 967, "0"),
            ("OM", 968, nil),
            ("PS", 970, "0"),
            ("AE", 971, "0"),
            ("IL", 972, "0"),
            ("BH", 973, nil),
            ("QA", 974, nil),
            ("BT", 975, nil),
            ("MN", 976, "0"),
            ("NP", 977, "0"),
            ("IR", 98, "0"),
            ("TJ", 992, nil),
            ("TM", 993, "8"),
            ("AZ", 994, "0"),
            ("GE", 995, "0"),
            ("KG", 996, "0"),
            ("UZ", 998, "8")
        ]

        return data.map { (region, code, trunkPrefix) in
            Metadata(region: region, code: "+\(code)", trunkPrefix: trunkPrefix)
        }
    }

}
