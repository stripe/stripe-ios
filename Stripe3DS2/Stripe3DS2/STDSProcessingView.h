//
//  STDSProcessingView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/19/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class STDSUICustomization;

@interface STDSProcessingView : UIView

/// Defaults to NO
@property (nonatomic) BOOL shouldDisplayBlurView;
/// Defaults to YES
@property (nonatomic) BOOL shouldDisplayDSLogo;

- (instancetype)initWithCustomization:(STDSUICustomization *)customization directoryServerLogo:(nullable UIImage *)directoryServerLogo;

@end

NS_ASSUME_NONNULL_END
