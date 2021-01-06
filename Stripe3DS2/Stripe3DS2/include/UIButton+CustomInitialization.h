//
//  UIButton+CustomInitialization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STDSUICustomization.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (CustomInitialization)

+ (UIButton *)_stds_buttonWithTitle:(NSString * _Nullable)title customization:(STDSButtonCustomization * _Nullable)customization;

@end

NS_ASSUME_NONNULL_END

void _stds_import_uibutton_custominitialization(void);
