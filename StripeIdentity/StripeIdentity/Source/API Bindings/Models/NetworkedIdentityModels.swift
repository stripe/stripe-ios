//
//  NetworkedIdentityModels.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

enum NetworkedIdentityDocumentType: String, SafeEnumDecodable, Equatable {
    case passport
    case drivingLicense = "driving_license"
    case idCard = "id_card"
    case unparsable
}

struct NetworkedIdentityDocument: Decodable, Equatable {
    let id: String
    let documentType: NetworkedIdentityDocumentType
    let redactedDocumentNumber: String?
    let expirationDate: Int?
    let liveCaptured: Bool?
}

struct NetworkedIdentityDocumentListResponse: Decodable, Equatable {
    let data: [NetworkedIdentityDocument]
}

struct NetworkedIdentityAssociationTokenResponse: Decodable, Equatable {
    let associationToken: String
}
