//
//  FinancialConnectionsGenericInfoScreen.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/20/24.
//

import Foundation

struct FinancialConnectionsGenericInfoScreen: Decodable {

    let id: String
    let header: Header?
    let body: Body?
    let footer: Footer?
    let options: Options?

    struct Header: Decodable {
        let title: String?
        let subtitle: String?
        let icon: FinancialConnectionsImage?
        let alignment: Alignment?

        enum Alignment: String, Decodable {
            case left = "left"
            case center = "center"
            case right = "right"
        }
    }

    struct Body: Decodable {

        let entries: [BodyEntry]

        enum BodyEntry: Decodable {
            case text(TextBodyEntry)
            case image(ImageBodyEntry)
            case unparasable

            public init(from decoder: Decoder) throws {
                let type = try? decoder
                    .container(keyedBy: TypeDecodingContainer.CodingKeys.self)
                    .decode(TypeDecodingContainer.self, forKey: .type)
                    .type
                let container = try decoder.singleValueContainer()
                if type == .text, let value = try? container.decode(TextBodyEntry.self) {
                    self = .text(value)
                } else {
                    self = .unparasable
                }
            }

            // this struct is here
            private struct TypeDecodingContainer: Codable {
                let type: BodyEntryType

                enum BodyEntryType: String, Codable {
                    case text = "text"
                    case image = "image"
                }

                enum CodingKeys: String, CodingKey {
                    case type
                }
            }
        }

        struct TextBodyEntry: Decodable {

            let id: String
            let text: String
            let alignment: Alignment?
            let size: Size?

            enum Alignment: String, Decodable {
                case left = "left"
                case center = "center"
                case right = "right"
            }

            enum Size: String, Decodable {
                case xsmall = "x-small"
                case small = "small"
                case medium = "medium"
            }
        }

        struct ImageBodyEntry: Decodable {
            let id: String
            let image: FinancialConnectionsImage
            let alt: String
        }

        struct BulletsBodyEntry: Decodable {
            let id: String
            let bullets: [GenericBulletPoint]

            struct GenericBulletPoint: Decodable {
                let id: String
                let icon: FinancialConnectionsImage?
                let title: String?
                let content: String?
            }
        }
    }

    struct Footer: Decodable {
        let disclaimer: String?
        let primaryCta: GenericInfoAction?
        let secondaryCta: GenericInfoAction?
        let belowCta: GenericInfoAction?

        struct GenericInfoAction: Decodable {
            let id: String
            let label: String
            let icon: FinancialConnectionsImage?
            let action: String?
            let testId: String?
        }
    }

    struct Options: Decodable {
        let fullWidthContent: Bool?
        let verticalAlignment: VerticalAlignment?

        enum VerticalAlignment: String, Decodable {
            case `default` = "default"
            case centered = "centered"
        }
    }
}
