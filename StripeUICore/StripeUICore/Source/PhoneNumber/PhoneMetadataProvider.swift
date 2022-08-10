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

    let metadata: [Metadata]

    private lazy var metadataByRegion: [String: Metadata] = {
        return .init(uniqueKeysWithValues: metadata.map { ($0.region, $0) })
    }()

    private init() {
        self.metadata = Self.loadMetadata()
    }

    func metadata(for region: String) -> Metadata? {
        return metadataByRegion[region]
    }

}

// MARK: - Loading

private extension PhoneMetadataProvider {

    static func loadMetadata() -> [Metadata] {
        let resourcesBundle = StripeUICoreBundleLocator.resourcesBundle

        guard
            let url = resourcesBundle.url(
                forResource: "phone_metadata",
                withExtension: "json.lzfse"
            )
        else {
            assertionFailure("phone_metadata.json.lzfse is missing")
            return getFallbackMetadata()
        }

        do {
            let data = try Data.fromLZFSEFile(at: url)

            let jsonDecoder = JSONDecoder()
            return try jsonDecoder.decode([Metadata].self, from: data)
        } catch {
            assertionFailure(error.localizedDescription)
            return getFallbackMetadata()
        }
    }

    static func getFallbackMetadata() -> [Metadata] {
        let codes: [String: String] = [
            "US": "1",
            "AG": "1",
            "AI": "1",
            "AS": "1",
            "BB": "1",
            "BM": "1",
            "BS": "1",
            "CA": "1",
            "DM": "1",
            "DO": "1",
            "GD": "1",
            "GU": "1",
            "JM": "1",
            "KN": "1",
            "KY": "1",
            "LC": "1",
            "MP": "1",
            "MS": "1",
            "PR": "1",
            "SX": "1",
            "TC": "1",
            "TT": "1",
            "VC": "1",
            "VG": "1",
            "VI": "1",
            "EG": "20",
            "SS": "211",
            "MA": "212",
            "EH": "212",
            "DZ": "213",
            "TN": "216",
            "LY": "218",
            "GM": "220",
            "SN": "221",
            "MR": "222",
            "ML": "223",
            "GN": "224",
            "CI": "225",
            "BF": "226",
            "NE": "227",
            "TG": "228",
            "BJ": "229",
            "MU": "230",
            "LR": "231",
            "SL": "232",
            "GH": "233",
            "NG": "234",
            "TD": "235",
            "CF": "236",
            "CM": "237",
            "CV": "238",
            "ST": "239",
            "GQ": "240",
            "GA": "241",
            "CG": "242",
            "CD": "243",
            "AO": "244",
            "GW": "245",
            "IO": "246",
            "AC": "247",
            "SC": "248",
            "SD": "249",
            "RW": "250",
            "ET": "251",
            "SO": "252",
            "DJ": "253",
            "KE": "254",
            "TZ": "255",
            "UG": "256",
            "BI": "257",
            "MZ": "258",
            "ZM": "260",
            "MG": "261",
            "RE": "262",
            "YT": "262",
            "ZW": "263",
            "NA": "264",
            "MW": "265",
            "LS": "266",
            "BW": "267",
            "SZ": "268",
            "KM": "269",
            "ZA": "27",
            "SH": "290",
            "TA": "290",
            "ER": "291",
            "AW": "297",
            "FO": "298",
            "GL": "299",
            "GR": "30",
            "NL": "31",
            "BE": "32",
            "FR": "33",
            "ES": "34",
            "GI": "350",
            "PT": "351",
            "LU": "352",
            "IE": "353",
            "IS": "354",
            "AL": "355",
            "MT": "356",
            "CY": "357",
            "FI": "358",
            "AX": "358",
            "BG": "359",
            "HU": "36",
            "LT": "370",
            "LV": "371",
            "EE": "372",
            "MD": "373",
            "AM": "374",
            "BY": "375",
            "AD": "376",
            "MC": "377",
            "SM": "378",
            "UA": "380",
            "RS": "381",
            "ME": "382",
            "XK": "383",
            "HR": "385",
            "SI": "386",
            "BA": "387",
            "MK": "389",
            "IT": "39",
            "VA": "39",
            "RO": "40",
            "CH": "41",
            "CZ": "420",
            "SK": "421",
            "LI": "423",
            "AT": "43",
            "GB": "44",
            "GG": "44",
            "IM": "44",
            "JE": "44",
            "DK": "45",
            "SE": "46",
            "NO": "47",
            "SJ": "47",
            "PL": "48",
            "DE": "49",
            "FK": "500",
            "BZ": "501",
            "GT": "502",
            "SV": "503",
            "HN": "504",
            "NI": "505",
            "CR": "506",
            "PA": "507",
            "PM": "508",
            "HT": "509",
            "PE": "51",
            "MX": "52",
            "CU": "53",
            "AR": "54",
            "BR": "55",
            "CL": "56",
            "CO": "57",
            "VE": "58",
            "GP": "590",
            "BL": "590",
            "MF": "590",
            "BO": "591",
            "GY": "592",
            "EC": "593",
            "GF": "594",
            "PY": "595",
            "MQ": "596",
            "SR": "597",
            "UY": "598",
            "CW": "599",
            "BQ": "599",
            "MY": "60",
            "AU": "61",
            "CC": "61",
            "CX": "61",
            "ID": "62",
            "PH": "63",
            "NZ": "64",
            "SG": "65",
            "TH": "66",
            "TL": "670",
            "NF": "672",
            "BN": "673",
            "NR": "674",
            "PG": "675",
            "TO": "676",
            "SB": "677",
            "VU": "678",
            "FJ": "679",
            "PW": "680",
            "WF": "681",
            "CK": "682",
            "NU": "683",
            "WS": "685",
            "KI": "686",
            "NC": "687",
            "TV": "688",
            "PF": "689",
            "TK": "690",
            "FM": "691",
            "MH": "692",
            "RU": "7",
            "KZ": "7",
            "JP": "81",
            "KR": "82",
            "VN": "84",
            "KP": "850",
            "HK": "852",
            "MO": "853",
            "KH": "855",
            "LA": "856",
            "CN": "86",
            "BD": "880",
            "TW": "886",
            "TR": "90",
            "IN": "91",
            "PK": "92",
            "AF": "93",
            "LK": "94",
            "MM": "95",
            "MV": "960",
            "LB": "961",
            "JO": "962",
            "SY": "963",
            "IQ": "964",
            "KW": "965",
            "SA": "966",
            "YE": "967",
            "OM": "968",
            "PS": "970",
            "AE": "971",
            "IL": "972",
            "BH": "973",
            "QA": "974",
            "BT": "975",
            "MN": "976",
            "NP": "977",
            "IR": "98",
            "TJ": "992",
            "TM": "993",
            "AZ": "994",
            "GE": "995",
            "KG": "996",
            "UZ": "998"
        ]

        return codes.map { (region: String, prefix: String) in
            Metadata(region: region, prefix: `prefix`, lengths: [], formats: [])
        }
    }

}
