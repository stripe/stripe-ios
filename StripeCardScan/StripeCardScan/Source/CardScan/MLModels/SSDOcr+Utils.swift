//
//  SSDOcr+Utils.swift
//  StripeCardScan
//
//  Created by Scott Grant on 7/7/22.
//

import CoreML

extension SSDOcr: MLModelClassType {
}

extension SSDOcr: AsyncMLModelLoading {
    typealias ModelClassType = SSDOcr

    static func createModelClass(using model: MLModel) -> SSDOcr {
        return SSDOcr(model: model)
    }
}
