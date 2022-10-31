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
    }
}

struct FinancialConnectionsConsent: Decodable {
    
    let title: String
    let body: Body
    let aboveCta: String
    let cta: String
    let belowCta: String?
    
    let dataAccessNotice: FinancialConnectionsDataAccessNotice
    
    struct Body: Decodable {
        let bullets: [BulletItem]
        
        struct BulletItem: Decodable {
            let icon: FinancialConnectionsImage
            let content: String
        }
    }
}

struct FinancialConnectionsDataAccessNotice: Decodable {
    let title: String
    let body: Body
    let learnMore: String
    let cta: String
    
    struct Body: Decodable {
        let bullets: [BulletItem]
        
        struct BulletItem: Decodable {
            let icon: FinancialConnectionsImage
            let title: String?
            let content: String
        }
    }
}
