//
//  FinancialConnectionsOAuthPrepane.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/6/23.
//

import Foundation
@_spi(STP) import StripeUICore

struct FinancialConnectionsOAuthPrepane: Decodable {
    
    let institutionIcon: FinancialConnectionsImage
    let title: String
    let body: OauthPrepaneBody
    let partnerNotice: OauthPrepanePartnerNotice?
    let cta: OauthPrepaneCTA
    let dataAccessNotice: FinancialConnectionsDataAccessNotice
    
    struct OauthPrepaneBody: Decodable {
        let entries: [OauthPrepaneBodyEntry]?
        
        struct OauthPrepaneBodyEntry: Decodable {
            
            enum EntryType: String, SafeEnumCodable, Equatable {
                case text = "text"
                case image = "image"
                case unparsable
            }
            
            let type: EntryType
            private let content: Any?
            var text: String? {
                return content as? String
            }
            var image: FinancialConnectionsImage? {
                return content as? FinancialConnectionsImage
            }
            
            enum CodingKeys: String, CodingKey {
                case type = "type"
                case content = "content"
            }
            
            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                self.type = try values.decode(EntryType.self, forKey: .type)
                if let text = try? values.decode(String.self, forKey: .content) {
                    self.content = text
                } else if let image = try? values.decode(FinancialConnectionsImage.self, forKey: .content) {
                    self.content = image
                } else {
                    self.content = nil
                }
            }
        }
    }
    
    struct OauthPrepanePartnerNotice: Decodable {
        let partnerIcon: FinancialConnectionsImage?
        let text: String
    }
    
    struct OauthPrepaneCTA: Decodable {
        let text: String
        let icon: FinancialConnectionsImage?
    }
}
