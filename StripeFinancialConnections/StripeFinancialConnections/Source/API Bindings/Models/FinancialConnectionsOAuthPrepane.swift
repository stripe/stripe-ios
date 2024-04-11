//
//  FinancialConnectionsOAuthPrepane.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/6/23.
//

import Foundation
@_spi(STP) import StripeUICore

struct FinancialConnectionsOAuthPrepane: Decodable {

    let institutionIcon: FinancialConnectionsImage?
    let title: String
    let subtitle: String?
    let body: OauthPrepaneBody
    let partnerNotice: OauthPrepanePartnerNotice?
    let cta: OauthPrepaneCTA
    let dataAccessNotice: FinancialConnectionsDataAccessNotice

    struct OauthPrepaneBody: Decodable {
        let entries: [OauthPrepaneBodyEntry]?

        struct OauthPrepaneBodyEntry: Decodable {

            enum Content {
                case text(String)
                case image(FinancialConnectionsImage)
                case unparsable
            }

            let content: Content

            init(content: Content) {
                self.content = content
            }

            enum CodingKeys: String, CodingKey {
                case type
                case content
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)

                // check the `type` before we unwrap `content` because we
                // want to avoid cases where an unknown/new `type` has
                // the same underlying data-type (ex. String) as a known `type`
                guard let type = try? values.decode(String.self, forKey: .type) else {
                    self.content = .unparsable
                    return
                }

                if type == "text", let text = try? values.decode(String.self, forKey: .content) {
                    self.content = .text(text)
                } else if type == "image",
                    let image = try? values.decode(FinancialConnectionsImage.self, forKey: .content)
                {
                    self.content = .image(image)
                } else {
                    self.content = .unparsable
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
