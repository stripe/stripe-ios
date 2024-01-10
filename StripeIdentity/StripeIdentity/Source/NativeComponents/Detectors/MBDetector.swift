//
//  MBDetector.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/9/24.
//

import Foundation
import CaptureCore

final class MBDetector: NSObject {
    
    override init() {
        print("BGLM - initalizing MBDetector")
        super.init()
        
        // initialize license
        MBCCCaptureCoreSDK.shared().setLicenseKey("sRwCAB5jb20uc3RyaXBlLlN0cmlwZUlkZW50aXR5VGVzdHMBbGV5SkRjbVZoZEdWa1QyNGlPakUzTURRNE16SXpNRFEyTURBc0lrTnlaV0YwWldSR2IzSWlPaUppWWpFM056RXdOeTAyWVRKbExUUTFaREF0T1RWbU55MDFZbUkzT1RrMU9UQXhNVEFpZlE9PeHR5ilO1B9ExqSov6yOm3dR7mwTmnageJ+hbbAMNCRr6o4HYdZ8je1wavLbbigrgO5/gU+kUMAiNUgxyLURYUaUFIwKjWky2K0Ngpl0C6WRfOPUD5pHeV3FQut4dMg=") { error in
            print("BGLM - \(error) occurs")
        };
        
        
        // initialize MBCAnalyzer
        let settings = MBCCAnalyzerSettings()
        settings.captureSingleSide = false
        settings.captureStrategy = .default
        MBCCAnalyzerRunner.shared().settings = settings
        
        MBCCAnalyzerRunner.shared().delegate = self
    }
    
    // from AVCapture
    func analyze(sampleBuffer: CMSampleBuffer) {
        print("BGLM - processing new images from CMSampleBuffer")
        let image = MBCCSampleBufferImage(sampleBuffer: sampleBuffer)
        // For portrait
        image.imageOrientation = .right
        
        MBCCAnalyzerRunner.shared().analyzeStreamImage(image)
        
    }
    
    // from image picker
    func analyze(uiImage: UIImage) {
        print("BGLM - processing new images from UIImage")
        let image = MBCCImage(uiImage: uiImage)
        MBCCAnalyzerRunner.shared().analyzeStreamImage(image)
    }
}

extension MBDetector : MBCCAnalyzerRunnerDelegate {
    func analyzerRunner(_ analyzerRunner: MBCCAnalyzerRunner, didAnalyzeFrameWith frameAnalysisResult: MBCCFrameAnalysisResult) {
        print("BGLM: analyzeRunner got new result")
    }
    
    func analyzerRunner(_ analyzerRunner: MBCCAnalyzerRunner, didFailWithAnalyzerError analyzerError: MBCCAnalyzerRunnerError) {
        print("BGLM: analyzeRunner got new error")
    }
    
    
}
