//
//  UxModel+Utils.swift
//  StripeCardScan
//
//  Created by Scott Grant on 7/7/22.
//

import CoreML

extension UxModel: MLModelClassType {
}

extension UxModel: AsyncMLModelLoading {
    typealias ModelClassType = UxModel

    static func createModelClass(using model: MLModel) -> UxModel {
        return UxModel(model: model)
    }
}
