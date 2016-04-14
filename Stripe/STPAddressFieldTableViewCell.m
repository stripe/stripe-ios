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

@interface STPAddressFieldTableViewCell() <STPFormTextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) STPLabeledFormField *formField;
@property (nonatomic, weak) id<STPAddressFieldTableViewCellDelegate> delegate;
@property (nonatomic, weak) STPAddressFieldViewModel *viewModel;
@property (nonatomic) UIToolbar *inputAccessoryToolbar;
@property (nonatomic) UIPickerView *countryPickerView;

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
        
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(nextTapped:)];
        toolbar.items = @[flexibleItem, nextItem];
        _inputAccessoryToolbar = toolbar;
        
        UIPickerView *pickerView = [UIPickerView new];
        pickerView.dataSource = self;
        pickerView.delegate = self;
        _countryPickerView = pickerView;
    }
    return self;
}

- (void)configureWithViewModel:(STPAddressFieldViewModel *)viewModel delegate:(id<STPAddressFieldTableViewCellDelegate>)delegate {
    self.viewModel = viewModel;
    self.delegate = delegate;
    self.formField.formTextField.placeholder = viewModel.placeholder;
    self.formField.formTextField.text = viewModel.contents;
    self.formField.captionLabel.text = viewModel.label;
    self.formField.formTextField.inputAccessoryView = nil;
    switch (viewModel.type) {
        case STPAddressFieldViewModelTypeText:
            self.formField.formTextField.keyboardType = UIKeyboardTypeDefault;
            break;
        case STPAddressFieldViewModelTypePhoneNumber:
            self.formField.formTextField.keyboardType = UIKeyboardTypePhonePad;
            self.formField.formTextField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
            self.formField.formTextField.inputAccessoryView = self.inputAccessoryToolbar;
            break;
        case STPAddressFieldViewModelTypeEmail:
            self.formField.formTextField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case STPAddressFieldViewModelTypeCountry:
            // TODO: country picker
            self.formField.formTextField.keyboardType = UIKeyboardTypeDefault;
            self.formField.formTextField.inputView = self.countryPickerView;
            break;
        case STPAddressFieldViewModelTypeZip:
            self.formField.formTextField.keyboardType = UIKeyboardTypeNumberPad;
            self.formField.formTextField.inputAccessoryView = self.inputAccessoryToolbar;
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.formField.frame = self.bounds;
    self.inputAccessoryToolbar.frame = CGRectMake(0, 0, self.bounds.size.width, 44);
}

- (BOOL)becomeFirstResponder {
    return [self.formField.formTextField becomeFirstResponder];
}

- (void)nextTapped:(__unused id)sender {
    [self.delegate addressFieldTableViewCellDidReturn:self];
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldTextDidChange:(STPFormTextField *)textField {
    self.viewModel.contents = textField.text;
    textField.validText = self.viewModel.isValid;
    [self.delegate addressFieldTableViewCellDidUpdateText:self];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    [self.delegate addressFieldTableViewCellDidReturn:self];
    return NO;
}

#pragma mark - UIPickerViewDelegate

#pragma mark - UIPickerViewDataSource

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.viewModel.contents = [NSLocale ISOCountryCodes][row];
    self.formField.formTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    NSString *countryCode = [NSLocale ISOCountryCodes][row];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode forKey: NSLocaleCountryCode]];
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return [NSLocale ISOCountryCodes].count;
}

@end
