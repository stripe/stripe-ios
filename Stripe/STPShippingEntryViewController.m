//
//  STPShippingEntryViewController.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import "STPShippingEntryViewController.h"
#import "STPAddress.h"
#import "STPAddressFieldViewModel.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "STPAddressFieldTableViewCell.h"

static NSString *STPShippingAddressFieldName = @"name";
static NSString *STPShippingAddressFieldEmail = @"email";
static NSString *STPShippingAddressFieldPhoneNumber = @"phone";
static NSString *STPShippingAddressFieldLine1 = @"line1";
static NSString *STPShippingAddressFieldLine2 = @"line2";
static NSString *STPShippingAddressFieldCity = @"city";
static NSString *STPShippingAddressFieldState = @"state";
static NSString *STPShippingAddressFieldPostalCode = @"postalCode";
static NSString *STPShippingAddressFieldCountry = @"country";

static NSString *const STPAddressFieldTableViewCellReuseIdentifier = @"STPAddressFieldTableViewCellReuseIdentifier";

@interface STPShippingEntryViewController () <UITableViewDelegate, UITableViewDataSource, STPAddressFieldTableViewCellDelegate>

@property (nonatomic, weak) id<STPShippingEntryViewControllerDelegate> delegate;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) PKAddressField requiredAddressFields;
@property (nonatomic, strong) NSMutableDictionary<NSString *, STPAddressFieldViewModel *> *keyToFieldViewModel;
@property (nonnull, strong) NSArray *fieldViewModelKeys;

@end

@implementation STPShippingEntryViewController

- (instancetype)initWithAddress:(STPAddress *)address
                       delegate:(id<STPShippingEntryViewControllerDelegate>)delegate
          requiredAddressFields:(PKAddressField)requiredAddressFields
{
    NSCAssert(requiredAddressFields != PKAddressFieldNone, @"must have some fields");
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
        _requiredAddressFields = requiredAddressFields;
        NSMutableArray *fieldViewModelKeys = [NSMutableArray new];
        NSMutableDictionary *keyToFieldViewModel = [NSMutableDictionary new];
        if (requiredAddressFields & PKAddressFieldName) {
            STPAddressFieldViewModel *viewModel = [STPAddressFieldViewModel viewModelWithLabel:@"Name" placeholder:@"John Appleseed" contents:address.name type:STPAddressFieldViewModelTypeText];
            keyToFieldViewModel[STPShippingAddressFieldName] = viewModel;
            [fieldViewModelKeys addObject:STPShippingAddressFieldName];
        }
        if (requiredAddressFields & PKAddressFieldEmail) {
            STPAddressFieldViewModel *viewModel = [STPAddressFieldViewModel viewModelWithLabel:@"Email" placeholder:@"name@example.com" contents:address.email type:STPAddressFieldViewModelTypeEmail];
            keyToFieldViewModel[STPShippingAddressFieldEmail] = viewModel;
            [fieldViewModelKeys addObject:STPShippingAddressFieldEmail];
        }
        if (requiredAddressFields & PKAddressFieldPhone) {
            STPAddressFieldViewModel *viewModel = [STPAddressFieldViewModel viewModelWithLabel:@"Phone" placeholder:@"(888) 555-1212" contents:address.phone type:STPAddressFieldViewModelTypePhoneNumber];
            keyToFieldViewModel[STPShippingAddressFieldPhoneNumber] = viewModel;
            [fieldViewModelKeys addObject:STPShippingAddressFieldPhoneNumber];
        }
        if (requiredAddressFields & PKAddressFieldPostalAddress) {
            STPAddressFieldViewModel *line1 = [STPAddressFieldViewModel viewModelWithLabel:@"Street" placeholder:@"123 Address St" contents:address.line1 type:STPAddressFieldViewModelTypeText];
            keyToFieldViewModel[STPShippingAddressFieldLine1] = line1;
            [fieldViewModelKeys addObject:STPShippingAddressFieldLine1];
            STPAddressFieldViewModel *line2 = [STPAddressFieldViewModel viewModelWithLabel:@"Cont'd" placeholder:@"Apartment?" contents:address.line2 type:STPAddressFieldViewModelTypeOptionalText];
            keyToFieldViewModel[STPShippingAddressFieldLine2] = line2;
            [fieldViewModelKeys addObject:STPShippingAddressFieldLine2];
            STPAddressFieldViewModel *city = [STPAddressFieldViewModel viewModelWithLabel:@"City" placeholder:@"San Francisco" contents:address.city type:STPAddressFieldViewModelTypeText];
            keyToFieldViewModel[STPShippingAddressFieldCity] = city;
            [fieldViewModelKeys addObject:STPShippingAddressFieldCity];
            STPAddressFieldViewModel *state = [STPAddressFieldViewModel viewModelWithLabel:@"State" placeholder:@"CA" contents:address.state type:STPAddressFieldViewModelTypeText];
            keyToFieldViewModel[STPShippingAddressFieldState] = state;
            [fieldViewModelKeys addObject:STPShippingAddressFieldState];
            STPAddressFieldViewModel *zip = [STPAddressFieldViewModel viewModelWithLabel:@"ZIP Code" placeholder:@"12345" contents:address.postalCode type:STPAddressFieldViewModelTypeZip];
            keyToFieldViewModel[STPShippingAddressFieldPostalCode] = zip;
            [fieldViewModelKeys addObject:STPShippingAddressFieldPostalCode];
            STPAddressFieldViewModel *country = [STPAddressFieldViewModel viewModelWithLabel:@"Country" placeholder:@"United States" contents:address.country type:STPAddressFieldViewModelTypeCountry];
            keyToFieldViewModel[STPShippingAddressFieldCountry] = country;
            [fieldViewModelKeys addObject:STPShippingAddressFieldCountry];
        }
        STPAddressFieldViewModel *lastViewModel = keyToFieldViewModel[fieldViewModelKeys.lastObject];
        lastViewModel.lastInList = YES;
        _fieldViewModelKeys = fieldViewModelKeys;
        _keyToFieldViewModel = keyToFieldViewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPAddressFieldTableViewCell class]
      forCellReuseIdentifier:STPAddressFieldTableViewCellReuseIdentifier];
    _tableView = tableView;
    [self.view addSubview:tableView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self action:@selector(done:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[self.tableView cellForRowAtIndexPath:indexPath] becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)cancel:(__unused id)sender {
    [self.delegate shippingEntryViewControllerDidCancel:self];
}

- (void)done:(__unused id)sender {
    [self.delegate shippingEntryViewController:self
                       didEnterShippingAddress:[self currentAddress]
                                    completion:^(NSError * _Nullable error) {
        if (error) {
            // TODO: handle error
            return;
        }
    }];
}

- (STPAddress *)currentAddress {
    STPAddress *address = [STPAddress new];
    address.name = self.keyToFieldViewModel[STPShippingAddressFieldName].contents;
    address.email = self.keyToFieldViewModel[STPShippingAddressFieldEmail].contents;
    address.phone = self.keyToFieldViewModel[STPShippingAddressFieldPhoneNumber].contents;
    address.line1 = self.keyToFieldViewModel[STPShippingAddressFieldLine1].contents;
    address.line2 = self.keyToFieldViewModel[STPShippingAddressFieldLine2].contents;
    address.city = self.keyToFieldViewModel[STPShippingAddressFieldCity].contents;
    address.state = self.keyToFieldViewModel[STPShippingAddressFieldState].contents;
    address.postalCode = self.keyToFieldViewModel[STPShippingAddressFieldPostalCode].contents;
    address.country = self.keyToFieldViewModel[STPShippingAddressFieldCountry].contents;
    return address;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return [self.keyToFieldViewModel count];
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [self.fieldViewModelKeys stp_boundSafeObjectAtIndex:indexPath.row];
    STPAddressFieldViewModel *viewModel = self.keyToFieldViewModel[key];
    STPAddressFieldTableViewCell *cell = (STPAddressFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:STPAddressFieldTableViewCellReuseIdentifier];
    [cell configureWithViewModel:viewModel delegate:self];
    return cell;
}

#pragma mark - STPAddressFieldTableViewCellDelegate

- (void)addressFieldTableViewCellDidUpdateText:(__unused STPAddressFieldTableViewCell *)cell {
    BOOL isValid = YES;
    for (STPAddressFieldViewModel *viewModel in self.keyToFieldViewModel.allValues) {
        if (!viewModel.isValid) {
            isValid = NO;
            break;
        }
    }
    self.navigationItem.rightBarButtonItem.enabled = isValid;
}

- (void)addressFieldTableViewCellDidReturn:(STPAddressFieldTableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [[self.tableView cellForRowAtIndexPath:newPath] becomeFirstResponder];
}

@end
