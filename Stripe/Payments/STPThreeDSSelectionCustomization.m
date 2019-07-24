//
//  STPThreeDSSelectionCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSSelectionCustomization.h"
#import "STPThreeDSCustomization+Private.h"

#import <Stripe/STDSSelectionCustomization.h>

@implementation STPThreeDSSelectionCustomization

+ (instancetype)defaultSettings {
    return [STPThreeDSSelectionCustomization new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectionCustomization = [STDSSelectionCustomization defaultSettings];
    }
    return self;
}

- (UIColor *)primarySelectedColor {
    return self.selectionCustomization.primarySelectedColor;
}

- (void)setPrimarySelectedColor:(UIColor *)primarySelectedColor {
    self.selectionCustomization.primarySelectedColor = primarySelectedColor;
}

- (UIColor *)secondarySelectedColor {
    return self.selectionCustomization.secondarySelectedColor;
}

- (void)setSecondarySelectedColor:(UIColor *)secondarySelectedColor {
    self.selectionCustomization.secondarySelectedColor = secondarySelectedColor;
}

- (UIColor *)unselectedBackgroundColor {
    return self.selectionCustomization.unselectedBackgroundColor;
}

- (void)setUnselectedBackgroundColor:(UIColor *)unselectedBackgroundColor {
    self.selectionCustomization.unselectedBackgroundColor = unselectedBackgroundColor;
}

- (UIColor *)unselectedBorderColor {
    return self.selectionCustomization.unselectedBorderColor;
}

- (void)setUnselectedBorderColor:(UIColor *)unselectedBorderColor {
    self.selectionCustomization.unselectedBorderColor = unselectedBorderColor;
}

@end
