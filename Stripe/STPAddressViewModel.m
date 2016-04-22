//
//  STPAddressViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressViewModel.h"
#import "STPAddressFieldViewModel.h"

@interface STPAddressViewModel()

@property(nonatomic)STPBillingAddressField requiredBillingAddressFields;
@property(nonatomic)NSArray<STPAddressFieldTableViewCell *> *addressCells;

@end

@implementation STPAddressViewModel

- (instancetype)initWithRequiredBillingFields:(STPBillingAddressField)requiredBillingAddressFields {
    self = [super init];
    if (self) {
        _requiredBillingAddressFields = requiredBillingAddressFields;
        NSArray *viewModels;
        switch (requiredBillingAddressFields) {
            case STPBillingAddressFieldNone:
                viewModels = @[];
                break;
            case STPBillingAddressFieldZip:
                viewModels = @[[STPAddressFieldViewModel viewModelWithLabel:@"ZIP Code" placeholder:@"12345" contents:@"" type:STPAddressFieldViewModelTypeZip]];
                break;
            case STPBillingAddressFieldFull:
                viewModels = @[
                               [STPAddressFieldViewModel viewModelWithLabel:@"Street" placeholder:@"123 Address St" contents:@"" type:STPAddressFieldViewModelTypeText],
                               [STPAddressFieldViewModel viewModelWithLabel:@"Cont'd" placeholder:@"Apartment?" contents:@"" type:STPAddressFieldViewModelTypeOptionalText],
                               [STPAddressFieldViewModel viewModelWithLabel:@"City" placeholder:@"San Francisco" contents:@"" type:STPAddressFieldViewModelTypeText],
                               [STPAddressFieldViewModel viewModelWithLabel:@"State" placeholder:@"CA" contents:@"" type:STPAddressFieldViewModelTypeText],
                               [STPAddressFieldViewModel viewModelWithLabel:@"ZIP Code" placeholder:@"12345" contents:@"" type:STPAddressFieldViewModelTypeZip],
                               [STPAddressFieldViewModel viewModelWithLabel:@"Country" placeholder:@"United States" contents:@"" type:STPAddressFieldViewModelTypeCountry]
                            ];
                break;
        }
        [viewModels.lastObject setLastInList:YES];
        NSMutableArray *cells = [NSMutableArray array];
        for (STPAddressFieldViewModel *viewModel in viewModels) {
            STPAddressFieldTableViewCell *cell = [[STPAddressFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell configureWithViewModel:viewModel delegate:nil];
            [cells addObject:cell];
        }
        _addressCells = cells;
    }
    return self;
}

- (STPAddressFieldTableViewCell *)cellAtIndex:(NSInteger)index {
    return self.addressCells[index];
}

@end
