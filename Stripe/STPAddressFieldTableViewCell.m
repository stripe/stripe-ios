//
//  STPAddressFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"
#import "STPAddressFieldViewModel.h"
#import "STPFormTextField.h"
#import "UIColor+Stripe.h"

@interface STPAddressFieldTableViewCell() <STPFormTextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic, weak) UILabel *captionLabel;
@property(nonatomic, weak) STPFormTextField *textField;
@property(nonatomic, weak) id<STPAddressFieldTableViewCellDelegate> delegate;
@property(nonatomic, weak) STPAddressFieldViewModel *viewModel;
@property(nonatomic) UIToolbar *inputAccessoryToolbar;
@property(nonatomic) UIPickerView *countryPickerView;
@property(nonatomic, strong) NSArray *countryCodes;

@end

@implementation STPAddressFieldTableViewCell

- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *captionLabel = [UILabel new];
        captionLabel.textColor = [UIColor stp_fieldLabelGreyColor];
        _captionLabel = captionLabel;
        [self addSubview:captionLabel];
        
        STPFormTextField *textField = [[STPFormTextField alloc] init];
        textField.formDelegate = self;
        textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        textField.placeholderColor = [UIColor stp_fieldPlaceholderGreyColor];
        textField.textColor = [UIColor stp_darkTextColor];
        _textField = textField;
        [self addSubview:textField];
        
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(nextTapped:)];
        toolbar.items = @[flexibleItem, nextItem];
        _inputAccessoryToolbar = toolbar;

        NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSMutableArray *otherCountryCodes = [[NSLocale ISOCountryCodes] mutableCopy];
        [otherCountryCodes removeObject:countryCode];
        _countryCodes = [@[@"", countryCode] arrayByAddingObjectsFromArray:otherCountryCodes];
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
    self.textField.placeholder = viewModel.placeholder;
    self.textField.text = viewModel.contents;
    self.captionLabel.text = viewModel.label;
    self.textField.inputAccessoryView = nil;
    switch (viewModel.type) {
        case STPAddressFieldViewModelTypeText:
        case STPAddressFieldViewModelTypeOptionalText:
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        case STPAddressFieldViewModelTypePhoneNumber:
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            self.textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
            if (!self.viewModel.lastInList) {
                self.textField.inputAccessoryView = self.inputAccessoryToolbar;
            }
            break;
        case STPAddressFieldViewModelTypeEmail:
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case STPAddressFieldViewModelTypeCountry: {
            self.textField.keyboardType = UIKeyboardTypeDefault;
            self.textField.inputView = self.countryPickerView;
            NSInteger index = [self.countryCodes indexOfObject:self.viewModel.contents];
            if (index == NSNotFound) {
                self.viewModel.contents = @"";
                self.textField.text = @"";
            }
            else {
                [self.countryPickerView selectRow:index inComponent:0 animated:NO];
            }
            break;
        }
        case STPAddressFieldViewModelTypeZip:
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            if (!self.viewModel.lastInList) {
                self.textField.inputAccessoryView = self.inputAccessoryToolbar;
            }
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captionLabel.frame = CGRectMake(15, 0, 80, self.bounds.size.height);
    CGFloat textFieldX = CGRectGetMaxX(self.captionLabel.frame) + 10;
    self.textField.frame = CGRectMake(textFieldX, 0, self.bounds.size.width - textFieldX, self.bounds.size.height);
    self.inputAccessoryToolbar.frame = CGRectMake(0, 0, self.bounds.size.width, 44);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
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

#pragma mark - UIPickerView

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.viewModel.contents = self.countryCodes[row];
    self.textField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    NSString *countryCode = self.countryCodes[row];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode forKey: NSLocaleCountryCode]];
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return self.countryCodes.count;
}

@end
