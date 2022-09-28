//
//  STPAnalyticsClient+PhoneMetadata.swift
//  StripeUICore
//
//  Created by Ramon Torres on 9/28/22.
//

import Foundation

@_spi(STP) import StripeCore

extension STPAnalyticsClient {

    struct PhoneMetadataAnalytic: Analytic {
        let event: STPAnalyticEvent
        let params: [String : Any]
    }

    func logPhoneMetadataEvent(_ event: STPAnalyticEvent) {
        log(analytic: PhoneMetadataAnalytic(event: event, params: [:]))
    }

    func logPhoneMetadataMissingError() {
        logPhoneMetadataEvent(.phoneMetadataLoadMissingError)
    }

    func logPhoneMetadataLoadingError(_ error: Error) {
        switch error {
        case is Data.LZFSEDecompressionError:
            logPhoneMetadataEvent(.phoneMetadataLoadDecompressionError)
        case is DecodingError:
            logPhoneMetadataEvent(.phoneMetadataLoadDecodingError)
        default:
            logPhoneMetadataEvent(.phoneMetadataLoadUnknownError)
        }
    }

}
