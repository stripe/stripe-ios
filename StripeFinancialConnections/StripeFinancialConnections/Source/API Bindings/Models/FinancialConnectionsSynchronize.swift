//
//  FinancialConnectionsSynchronize.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/20/22.
//

import Foundation

struct FinancialConnectionsSynchronize: Decodable {
    
    let manifest: FinancialConnectionsSessionManifest
    let text: Text
    
    struct Text: Decodable {
        let consentPane: FinancialConnectionsConsent
        // let dataAccessNotice: FinancialConnectionsDataAccessNotice
    }
}

struct FinancialConnectionsConsent: Decodable {
    
    let title: String
    let body: Body
    let aboveCta: String
    let cta: String
    let belowCta: String?
    
    struct Body: Decodable {
        let bullets: [FinancialConnectionsBullet]
    }
}

struct FinancialConnectionsDataAccessNotice: Decodable {
    let title: String
    let body: Body
    let cta: String
    
    struct Body: Decodable {
        let bullets: [FinancialConnectionsBullet]
        let learnMore: String
    }
}

struct FinancialConnectionsBullet: Decodable {
    let icon: String
    let title: String?
    let content: String
}
