//
//  STPThreeDSCustomization+Private.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSButtonCustomization.h"
#import "STPThreeDSUICustomization.h"

@class STDSButtonCustomization;
@class STDSUICustomization;

@interface STPThreeDSButtonCustomization ()
@property (nonatomic, strong) STDSButtonCustomization *buttonCustomization;
@end

@interface STPThreeDSUICustomization ()
@property (nonatomic, strong) STDSUICustomization *uiCustomization;
@end
