//
//  STPPickerTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPPickerTableViewCell.h"

#import "STPFormTextField.h"
#import "STPTextFieldTableViewCell.h"

@interface STPPickerTableViewCell() <UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic) UIPickerView *pickerView;

@end

@implementation STPPickerTableViewCell

@synthesize contents = _contents;

- (instancetype)init {
    self = [super init];
    if (self) {
        UIPickerView *pickerView = [UIPickerView new];
        pickerView.delegate = self;
        pickerView.dataSource = self;
        _pickerView = pickerView;
        self.textField.inputView = pickerView;
    }
    return self;
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    self.textField.validText = self.textValidationBlock(contents, NO);
    NSInteger index = [self.pickerDataSource indexOfValue:contents];
    if (index == NSNotFound) {
        self.textField.text = @"";
    }
    else {
        [self.pickerView selectRow:index inComponent:0 animated:NO];
        self.textField.text = [self.pickerDataSource titleForRow:index];
    }
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(__unused UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(__unused NSInteger)component {
    if (!self.pickerDataSource) {
        return;
    }
    self.contents = [self.pickerDataSource valueForRow:row];
    self.textField.text = [self.pickerDataSource titleForRow:row];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    if (!self.pickerDataSource) {
        return @"";
    }
    return [self.pickerDataSource titleForRow:row];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    if (!self.pickerDataSource) {
        return 0;
    }
    return [self.pickerDataSource numberOfRows];
}

@end
