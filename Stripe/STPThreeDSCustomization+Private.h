//
//  STPThreeDSCustomization+Private.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSButtonCustomization.h"
#import "STPThreeDSUICustomization.h"
#import "STPThreeDSFooterCustomization.h"
#import "STPThreeDSLabelCustomization.h"
#import "STPThreeDSNavigationBarCustomization.h"
#import "STPThreeDSSelectionCustomization.h"
#import "STPThreeDSTextFieldCustomization.h"

@class STDSButtonCustomization;
@class STDSUICustomization;
@class STDSFooterCustomization;
@class STDSLabelCustomization;
@class STDSNavigationBarCustomization;
@class STDSSelectionCustomization;
@class STDSTextFieldCustomization;

@interface STPThreeDSButtonCustomization ()
@property (nonatomic, strong) STDSButtonCustomization *buttonCustomization;
@end

@interface STPThreeDSUICustomization ()
@property (nonatomic, strong) STDSUICustomization *uiCustomization;
@end

@interface STPThreeDSFooterCustomization ()
@property (nonatomic, strong) STDSFooterCustomization *footerCustomization;
@end

@interface STPThreeDSLabelCustomization ()
@property (nonatomic, strong) STDSLabelCustomization *labelCustomization;
@end

@interface STPThreeDSNavigationBarCustomization ()
@property (nonatomic, strong) STDSNavigationBarCustomization *navigationBarCustomization;
@end

@interface STPThreeDSSelectionCustomization ()
@property (nonatomic, strong) STDSSelectionCustomization *selectionCustomization;
@end

@interface STPThreeDSTextFieldCustomization ()
@property (nonatomic, strong) STDSTextFieldCustomization *textFieldCustomization;
@end
