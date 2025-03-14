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

        enum Alignment: String, SafeEnumCodable {
            case left = "left"
            case center = "center"
            case right = "right"
            case unparsable
        }
    }

    struct Body: Decodable {

        let entries: [BodyEntry]

        enum BodyEntry: Decodable {
            case text(TextBodyEntry)
            case image(ImageBodyEntry)
            case bullets(BulletsBodyEntry)
            case unparasable

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                // Decode the type first
                let typeString = try container.decode(String.self, forKey: .type)

                // Now decode the appropriate model based on the type
                switch typeString {
                case "text":
                    let textEntry = try TextBodyEntry(from: decoder)
                    self = .text(textEntry)
                case "image":
                    let imageEntry = try ImageBodyEntry(from: decoder)
                    self = .image(imageEntry)
                case "bullets":
                    let bulletsEntry = try BulletsBodyEntry(from: decoder)
                    self = .bullets(bulletsEntry)
                default:
                    self = .unparasable
                }
            }

            // this struct is here
            private struct TypeDecodingContainer: Codable {
                let type: BodyEntryType

                enum BodyEntryType: String, Codable {
                    case text = "text"
                    case image = "image"
                    case bullets = "bullets"
                }

                enum CodingKeys: String, CodingKey {
                    case type
                }
            }

            private enum CodingKeys: String, CodingKey {
                case type
            }

        }

        struct TextBodyEntry: Decodable {

            let id: String
            let text: String
            let alignment: Alignment?
            let size: Size?

            enum Alignment: String, SafeEnumCodable {
                case left = "left"
                case center = "center"
                case right = "right"
                case unparsable
            }

            enum Size: String, SafeEnumCodable {
                case xsmall = "x-small"
                case small = "small"
                case medium = "medium"
                case unparsable
            }
        }

        struct ImageBodyEntry: Decodable {
            let id: String
            let image: FinancialConnectionsImage
            let alt: String
        }

        struct BulletsBodyEntry: Decodable { // TODO(kgaidis): implement the bullets body entry as a type
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
        let belowCta: String?

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

        enum VerticalAlignment: String, SafeEnumCodable {
            case `default` = "default"
            case centered = "centered"
            case unparsable
        }
    }
}
