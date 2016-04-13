//
//  STPAddressFieldViewModel.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldViewModel.h"

@interface STPAddressFieldViewModel()

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, assign) STPAddressFieldViewModelType type;

@end

@implementation STPAddressFieldViewModel

+ (instancetype)viewModelWithLabel:(NSString *)label
                       placeholder:(NSString *)placeholder
                          contents:(NSString *)contents
                              type:(STPAddressFieldViewModelType)type {
    STPAddressFieldViewModel *viewModel = [STPAddressFieldViewModel new];
    viewModel.label = label;
    viewModel.placeholder = placeholder;
    viewModel.contents = contents;
    viewModel.type = type;
    viewModel.isValid = NO;
    return viewModel;
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    self.isValid = [contents length] > 0;
}

@end
