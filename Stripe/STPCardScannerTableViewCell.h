//
//  STPCardScannerTableViewCell.h
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTheme;
@class STPCameraView;

NS_ASSUME_NONNULL_BEGIN

@interface STPCardScannerTableViewCell : UITableViewCell

@property (nonatomic, weak, readonly) STPCameraView *cameraView;
@property (nonatomic, copy) STPTheme *theme;

@end

NS_ASSUME_NONNULL_END
