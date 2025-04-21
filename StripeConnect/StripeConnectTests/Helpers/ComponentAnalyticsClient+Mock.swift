//
//  ComponentAnalyticsClient+Mock.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect

extension ComponentAnalyticsClient.CommonFields {
    static let mock = ComponentAnalyticsClient.CommonFields(platformId: nil, livemode: nil, component: .onboarding, componentInstance: .init())
}
