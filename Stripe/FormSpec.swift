//
//  FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// A decodable representation that can used to construct a `FormElement`
struct FormSpec: Decodable {
    /// The types of Elements we support
    enum ElementType: String, Decodable {
        case name
        case email
        case address
    }

    struct ElementSpec: Decodable, Equatable {
        let type: ElementType
    }
    
    let elements: [ElementSpec]
}
