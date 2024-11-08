//
//  ComponentAnalyticsClient+Mock.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

extension ComponentAnalyticsClient {
    static func mock(
        _ client: AnalyticsClientV2Protocol = MockAnalyticsClientV2(),
        _ commonFields: CommonFields = .mock
    ) -> ComponentAnalyticsClient {
        .init(client: client, commonFields: commonFields)
    }
}

extension ComponentAnalyticsClient.CommonFields {
    static let mock = ComponentAnalyticsClient.CommonFields(platformId: nil, livemode: nil, component: .onboarding, componentInstance: .init())
}
