//
//  STPPaymentMethodsStore.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsStore.h"
#import "STPBackendAPIAdapter.h"
#import "STPCardPaymentMethod.h"
#import "STPApplePayPaymentMethod.h"

@interface STPPaymentMethodsStore ()

@property (nonatomic, readwrite) STPPaymentMethodType supportedPaymentMethods;
@property (nonatomic, readwrite) id<STPBackendAPIAdapter> apiAdapter;

@end

@implementation STPPaymentMethodsStore

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods
                                     apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    self = [super init];
    if (self) {
        _supportedPaymentMethods = supportedPaymentMethods;
        NSMutableArray *paymentMethods = [NSMutableArray new];
        if (supportedPaymentMethods & STPPaymentMethodTypeApplePay) {
            [paymentMethods addObject:[[STPApplePayPaymentMethod alloc] init]];
        }
        _paymentMethods = paymentMethods;
        _selectedPaymentMethod = nil;
        _apiAdapter = apiAdapter;
    }
    return self;
}

- (void)loadSources:(STPErrorBlock)completion {
    // 1. load remote sources
    // 2. load local settings (saved apple pay preference)

    [self.apiAdapter retrieveSources:^(id<STPSource> selectedSource, NSArray<id<STPSource>> * sources, NSError * error) {
        if (error) {
            completion(error);
            return;
        }
        if (selectedSource) {
            self.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithSource:selectedSource];
        }
        if ([sources count] > 0) {
            NSMutableArray *paymentMethods = [NSMutableArray new];
            for (id<STPSource> source in sources) {
                [paymentMethods addObject:[[STPCardPaymentMethod alloc] initWithSource:source]];
            }
            self.paymentMethods = paymentMethods;
        }
        completion(nil);
    }];
}


@end
