//
//  STPCardScanner.h
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCameraView.h"

NS_ASSUME_NONNULL_BEGIN

@class STPCardScanner, STPPaymentMethodCardParams;

extern NSString *const STPCardScannerErrorDomain;

typedef NS_ENUM(NSInteger, STPCardScannerError) {
    /**
     Camera not available.
     */
    STPCardScannerErrorCameraNotAvailable,
};

API_AVAILABLE(ios(13.0))
@protocol STPCardScannerDelegate <NSObject>
- (void)cardScanner:(STPCardScanner *)scanner didFinishWithCardParams:(nullable STPPaymentMethodCardParams *)cardParams error:(nullable NSError *)error;
@end

API_AVAILABLE(ios(13.0))
@interface STPCardScanner : NSObject

+ (BOOL)cardScanningAvailable;

@property (nonatomic, weak) STPCameraView *cameraView;
@property (atomic) UIDeviceOrientation deviceOrientation;

- (instancetype)init __attribute__((unavailable("Use initWithDelegate")));
- (instancetype)initWithDelegate:(id<STPCardScannerDelegate>)delegate;
- (void)start;
- (void)stop;

@end
NS_ASSUME_NONNULL_END
