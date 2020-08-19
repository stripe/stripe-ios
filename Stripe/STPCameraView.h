//
//  STPCameraView.h
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class AVCaptureSession, AVCaptureVideoPreviewLayer;

@interface STPCameraView : UIView

@property (nonatomic, strong, nullable) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
- (void)playSnapshotAnimation;

@end

NS_ASSUME_NONNULL_END
