//
//  CameraPreviewView.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/1/21.
//

import UIKit
import AVFoundation

@_spi(STP) public class CameraPreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    /**
     Camera session that configures the video feed for this view.

     - Note:
     A session can only be used on one `PreviewView` at a time. Setting the same
     session on a different `PreviewView` will remove it from the previous one.
     */
    public weak var session: CameraSessionProtocol? {
        didSet {
            guard oldValue !== session else {
                return
            }
            oldValue?.previewView = nil
            session?.previewView = self
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

    // MARK: Internal

    /**
     Sets the video capture session in thread-safe way that doesn't block main
     thread when configuring the session.

     - Parameters:
       - captureSession: The capture session to set on this view
       - queue: Worker queue to configure the session
     */
    func setCaptureSession(_ captureSession: AVCaptureSession?, on queue: DispatchQueue) {
        // Get reference to videoPreviewLayer on main queue then dispatch to
        // worker queue to set session so it doesn't block main.

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            queue.async { [weak captureSession, weak videoPreviewLayer = self.videoPreviewLayer] in
                videoPreviewLayer?.session = captureSession
            }
        }
    }
}
