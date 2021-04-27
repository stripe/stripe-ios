//
//  STDSSelectionButton.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 6/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STDSSelectionCustomization;

NS_ASSUME_NONNULL_BEGIN

@interface STDSSelectionButton : UIButton

@property (nonatomic) STDSSelectionCustomization *customization;

/// This control can either be styled as a radio button or a checkbox
@property (nonatomic) BOOL isCheckbox;

- (instancetype)initWithCustomization:(STDSSelectionCustomization *)customization;

@end

NS_ASSUME_NONNULL_END
