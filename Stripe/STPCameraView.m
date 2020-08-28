//
//  STPCameraView.m
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPCameraView.h"
#import <AVFoundation/AVFoundation.h>

@implementation STPCameraView {
    CALayer *_flashLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _flashLayer = [[CALayer alloc] init];
    [self.layer addSublayer:_flashLayer];
    _flashLayer.masksToBounds = YES;
    _flashLayer.backgroundColor = [[UIColor blackColor] CGColor];
    _flashLayer.opacity = 0.0;
    self.layer.masksToBounds = YES;
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    return self;
}

- (AVCaptureSession *)captureSession {
    return [self.videoPreviewLayer session];
}

- (void)setCaptureSession:(AVCaptureSession *)captureSession {
    return [self.videoPreviewLayer setSession:captureSession];
}

- (void)playSnapshotAnimation {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    _flashLayer.frame = CGRectMake(0, 0, self.layer.bounds.size.width, self.layer.bounds.size.height);
    _flashLayer.opacity = 1.0;
    [CATransaction commit];
    dispatch_async(dispatch_get_main_queue(), ^{
        CABasicAnimation* fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnim.fromValue = [NSNumber numberWithFloat:1.0];
        fadeAnim.toValue = [NSNumber numberWithFloat:0.0];
        fadeAnim.duration = 1.0;
        [self->_flashLayer addAnimation:fadeAnim forKey:@"opacity"];
        self->_flashLayer.opacity = 0.0;
    });
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

@end
