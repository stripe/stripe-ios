//
//  IdentityMLModelLoaderMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable import StripeIdentity

final class IdentityMLModelLoaderMock: IdentityMLModelLoaderProtocol {

    var documentModelsResult: Result<AnyDocumentScanner, Error> = .failure(
        IdentityMLModelLoaderError.mlModelNeverLoaded
    )
    var faceModelsResult: Result<AnyFaceScanner, Error> = .failure(
        IdentityMLModelLoaderError.mlModelNeverLoaded
    )

    private(set) var didStartLoadingDocumentModels = false
    private(set) var didStartLoadingFaceModels = false

    func documentModels() async -> Result<AnyDocumentScanner, Error> {
        documentModelsResult
    }

    func faceModels() async -> Result<AnyFaceScanner, Error> {
        faceModelsResult
    }

    func startLoadingDocumentModels(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        with sheetController: StripeIdentity.VerificationSheetControllerProtocol
    ) {
        didStartLoadingDocumentModels = true
    }

    func startLoadingFaceModels(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    ) {
        didStartLoadingFaceModels = true
    }
}
