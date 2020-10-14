//
//  STDSCustomization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// This class provides a common set of customization parameters, used to customize elements of the UI.
@interface STDSCustomization : NSObject <NSCopying>

/// The font to use for text.
@property (nonatomic, nullable) UIFont *font;

/// The color to use for the text.
@property (nonatomic, nullable) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
