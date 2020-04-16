//
//  STPAUBECSDebitFormView+Testing.h
//  Stripe
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPAUBECSDebitFormView.h"

@interface STPAUBECSDebitFormView (Testing)

@property (nonatomic, readonly) STPFormTextField *nameTextField;
@property (nonatomic, readonly) STPFormTextField *emailTextField;
@property (nonatomic, readonly) STPFormTextField *bsbNumberTextField;
@property (nonatomic, readonly) STPFormTextField *accountNumberTextField;


@end
