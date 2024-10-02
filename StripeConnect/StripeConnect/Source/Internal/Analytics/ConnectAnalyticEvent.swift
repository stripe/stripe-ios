//
//  ConnectAnalyticEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

import Foundation
@_spi(STP) @_spi(DashboardOnly) import StripeCore

enum AnalyticEventName: String, Encodable {
    case foo
}

struct BaseParams<Metadata: Codable>: Encodable {
    let eventName: AnalyticEventName

    let publishableKey: String?
    let platformId: String?
    let merchantId: String?
    let livemode: Bool?
    let component: ComponentType
    let componentInstance: UUID

    let eventMetadata: Metadata
}

extension BaseParams {
    init(eventName: AnalyticEventName,
         apiClient: STPAPIClient,
         component: ComponentType,
         merchantId: String?,
         componentInstance: UUID,
         eventMetadata: Metadata
    ) {
        // Reuse logic in ConnectJSURLParams
        let params = ConnectJSURLParams(component: component, apiClient: apiClient)

        self.init(
            eventName: eventName,
            publishableKey: params.publicKey,
            platformId: params.platformIdOverride,
            merchantId: params.merchantIdOverride ?? merchantId,
            livemode: params.livemodeOverride,
            component: params.component,
            componentInstance: componentInstance,
            eventMetadata: eventMetadata
        )
    }
}
