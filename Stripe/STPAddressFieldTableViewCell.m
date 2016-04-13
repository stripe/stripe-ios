//
//  STPAddressFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"
#import "STPAddressFieldViewModel.h"
#import "STPLabeledFormField.h"
#import "STPFormTextField.h"

@interface STPAddressFieldTableViewCell() <STPFormTextFieldDelegate>

@property (nonatomic, weak) STPLabeledFormField *formField;
@property (nonatomic, weak) id<STPAddressFieldTableViewCellDelegate> delegate;

@end

@implementation STPAddressFieldTableViewCell

- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        STPLabeledFormField *formField = [[STPLabeledFormField alloc] init];
        formField.formTextField.formDelegate = self;
        formField.formTextField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        _formField = formField;
        [self addSubview:formField];
    }
    return self;
}

- (void)configureWithViewModel:(STPAddressFieldViewModel *)viewModel delegate:(id<STPAddressFieldTableViewCellDelegate>)delegate {
    self.viewModel = viewModel;
    self.formField.formTextField.placeholder = viewModel.placeholder;
    self.formField.formTextField.text = viewModel.contents;
    self.formField.captionLabel.text = viewModel.label;
    self.delegate = delegate;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.formField.frame = self.bounds;
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldTextDidChange:(STPFormTextField *)textField {
    self.viewModel.contents = textField.text;
    textField.validText = self.viewModel.isValid;
    [self.delegate addressFieldTableViewCellDidUpdateText:self];
}

@end
