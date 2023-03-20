//
//  STDSCategoryLinker.m
//  Stripe3DS2
//
//  Created by David Estes on 11/18/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "STDSCategoryLinker.h"

#import "NSData+JWEHelpers.h"
#import "NSString+JWEHelpers.h"
#import "NSDictionary+DecodingHelpers.h"
#import "NSError+Stripe3DS2.h"
#import "NSString+EmptyChecking.h"
#import "NSLayoutConstraint+LayoutSupport.h"
#import "UIButton+CustomInitialization.h"
#import "UIColor+DefaultColors.h"
#import "UIColor+ThirteenSupport.h"
#import "UIFont+DefaultFonts.h"
#import "UIView+LayoutSupport.h"
#import "UIViewController+Stripe3DS2.h"

@implementation STDSCategoryLinker

+ (void)referenceAllCategories {
  // NSData+JWEHelpers.h"
  _stds_import_nsdata_jwehelpers();
  // NSString+JWEHelpers.h
  _stds_import_nsstring_jwehelpers();
  // NSDictionary+DecodingHelpers.h
  _stds_import_nsdictionary_decodinghelpers();
  // NSError+Stripe3DS2.h
  _stds_import_nserror_stripe3ds2();
  // NSString+EmptyChecking.h
  _stds_import_nsstring_emptychecking();
  // NSLayoutConstraint+LayoutSupport.h
  _stds_import_nslayoutconstraint_layoutsupport();
  // UIButton+CustomInitialization.h
  _stds_import_uibutton_custominitialization();
  // UIColor+DefaultColors.h
  _stds_import_uicolor_defaultcolors();
  // UIColor+ThirteenSupport.h
  _stds_import_uicolor_thirteensupport();
  // UIFont+DefaultFonts.h
  _stds_import_uifont_defaultfonts();
  // UIView+LayoutSupport.h
  _stds_import_uiview_layoutsupport();
  // UIViewController+Stripe3DS2.h
  _stds_import_uiviewcontroller_stripe3ds2();
}

@end
