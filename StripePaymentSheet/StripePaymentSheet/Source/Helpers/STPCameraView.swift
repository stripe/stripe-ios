//
//  STPCameraView.swift
//  StripePaymentSheet
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
#if !os(visionOS)

import AVFoundation
import UIKit

@available(macCatalyst 14.0, *)
class STPCameraView: UIView {
    private var flashLayer: CALayer?

    var captureSession: AVCaptureSession? {
        get {
            return (videoPreviewLayer.session)!
        }
        set(captureSession) {
            videoPreviewLayer.session = captureSession
        }
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        flashLayer = CALayer()
        if let flashLayer = flashLayer {
            layer.addSublayer(flashLayer)
        }
        flashLayer?.masksToBounds = true
        flashLayer?.backgroundColor = UIColor.black.cgColor
        flashLayer?.opacity = 0.0
        layer.masksToBounds = true
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

#endif
