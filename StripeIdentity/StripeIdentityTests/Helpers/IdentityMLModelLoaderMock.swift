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
    let documentModelsPromise = Promise<AnyDocumentScanner>()
    private(set) var didStartLoadingDocumentModels = false

    var documentModelsFuture: Future<AnyDocumentScanner> {
        return documentModelsPromise
    }

    func startLoadingDocumentModels(from capturePageConfig: VerificationPageStaticContentDocumentCapturePage) {
        didStartLoadingDocumentModels = true
    }
}
