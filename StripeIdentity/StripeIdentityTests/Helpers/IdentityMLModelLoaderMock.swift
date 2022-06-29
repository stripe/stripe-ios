//
//  IdentityMLModelLoaderMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/2/22.
//

import Foundation
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class IdentityMLModelLoaderMock: IdentityMLModelLoaderProtocol {

    let documentModelsPromise = Promise<AnyDocumentScanner>(
        error: IdentityMLModelLoaderError.mlModelNeverLoaded
    )
    let faceModelsPromise = Promise<AnyFaceScanner>(
        error: IdentityMLModelLoaderError.mlModelNeverLoaded
    )

    private(set) var didStartLoadingDocumentModels = false
    private(set) var didStartLoadingFaceModels = false

    var documentModelsFuture: Future<AnyDocumentScanner> {
        return documentModelsPromise
    }

    var faceModelsFuture: Future<AnyFaceScanner> {
        return faceModelsPromise
    }

    func startLoadingDocumentModels(from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage) {
        didStartLoadingDocumentModels = true
    }

    func startLoadingFaceModels(from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage) {
        didStartLoadingFaceModels = true
    }
}
