//
//  CameraPreviewView.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/1/21.
//

import UIKit
import AVFoundation

@_spi(STP) public class CameraPreviewView: UIView {
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    public var captureSession: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    // MARK: Initialization
    
    public init() {
        super.init(frame: .zero)

        videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: UIView
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
