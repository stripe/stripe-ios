//
//  VerificationPageDataDocumentFileData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//
import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataDocumentFileData: StripeEncodable, Equatable {

    enum FileUploadMethod: String, Encodable, Equatable {
        /// Document image was auto-captured from the camera feed using ML models
        case autoCapture = "auto_capture"
        /// Document image was captured from the camera feed manually
        case manualCapture = "manual_capture"
        /// Document was uploaded from the file system
        case fileUpload = "file_upload"
    }

    /// Method of getting the document image
    let method: FileUploadMethod
    /// File ID of uploaded image. If user auto-captured, this will be cropped to the bounds of the document.
    let userUpload: String
    /// If auto-captured, file ID of uploaded un-cropped image.
    let fullFrame: String?
    /// If auto-captured, probability score of 'passport' result from ML model.
    let passportScore: Decimal?
    /// If auto-captured, probability score of 'front_id' result from ML model.
    let frontCardScore: Decimal?
    /// If auto-captured, probability score of 'back' result from ML model.
    let backScore: Decimal?
    /// If auto-captured, probability score of 'invalid' result from ML model.
    let invalidScore: Decimal?
    /// If auto-captured, probability score of 'no_id' result from ML model.
    let noDocumentScore: Decimal?

    var _additionalParametersStorage: NonEncodableParameters?
}
