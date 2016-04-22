//
//  STPPaymentCardEntryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardEntryViewController.h"
#import "STPPaymentCardTextField.h"
#import "STPToken.h"
#import "UIFont+Stripe.h"
#import "UIColor+Stripe.h"
#import "UIImage+Stripe.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPAddressViewModel.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"

@interface STPPaymentCardEntryViewController ()<STPPaymentCardTextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)UITableViewCell *cardNumberCell;
@property(nonatomic)NSArray<UITableViewCell *> *addressCells;
@property(nonatomic, copy)STPPaymentCardEntryBlock completion;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic)BOOL loading;
@property(nonatomic)STPAddressViewModel *addressViewModel;
@end

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";
static NSInteger STPPaymentCardNumberSection = 0;
static NSInteger STPPaymentCardBillingAddressSection = 1;

@implementation STPPaymentCardEntryViewController

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
                       completion:(STPPaymentCardEntryBlock)completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _completion = completion;
        _requiredBillingAddressFields = STPBillingAddressFieldFull;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.backgroundColor = [UIColor stp_backgroundGreyColor];
    tableView.sectionHeaderHeight = 30;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    [self stp_beginAvoidingKeyboardWithScrollView:tableView];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.navigationItem.rightBarButtonItem = doneItem;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.title = NSLocalizedString(@"Add Card", nil);

    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.tableView.tableHeaderView = cardImageView;
    
    UITableViewCell *cardNumberCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] init];
    textField.backgroundColor = [UIColor whiteColor];
    textField.cornerRadius = 0;
    textField.borderColor = [UIColor colorWithWhite:0.9f alpha:1];
    textField.delegate = self;
    [cardNumberCell addSubview:textField];
    self.textField = textField;
    self.cardNumberCell = cardNumberCell;
    
    // TODO remove
    self.requiredBillingAddressFields = STPBillingAddressFieldFull;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.textField.frame = self.cardNumberCell.bounds;
}

- (void)setRequiredBillingAddressFields:(STPBillingAddressField)requiredBillingAddressFields {
    _requiredBillingAddressFields = requiredBillingAddressFields;
    self.addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:requiredBillingAddressFields];
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    self.navigationItem.leftBarButtonItem.enabled = !loading;
    if (loading) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator startAnimating];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [self.navigationItem setRightBarButtonItem:loadingItem animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:self.doneItem animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
    self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)dealloc {
    
}

- (void)cancelPressed:(__unused id)sender {
    if (self.completion) {
        self.completion(nil, ^(NSError *error) {
            if (error) {
                [self handleError:error];
            }
        });
    }
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    [self.textField resignFirstResponder];
    [self.apiClient createTokenWithCard:self.textField.cardParams completion:^(STPToken *token, NSError *tokenError) {
        if (tokenError) {
            [self handleError:tokenError];
        } else {
            if (self.completion) {
                self.completion(token, ^(NSError *error) {
                    if (error) {
                        [self handleError:error];
                    }
                });
            }
        }
    }];
}

- (void)handleError:(NSError *)error {
    self.loading = NO;
    NSLog(@"%@", error);
    [self.textField becomeFirstResponder];
    // TODO handle error, probably by showing a UIAlertController
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    switch (self.requiredBillingAddressFields) {
        case STPBillingAddressFieldNone:
            return 1;
        case STPBillingAddressFieldZip:
        case STPBillingAddressFieldFull:
            return self.addressViewModel.addressCells.count == 0 ? 1 : 2;
    }
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardNumberSection) {
        return 1;
    } else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentCardNumberSection) {
        return self.cardNumberCell;
    } else if (indexPath.section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells[indexPath.row];
    }
    return nil;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return tableView.sectionHeaderHeight;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:15];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 15;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
    label.textColor = [UIColor stp_fieldLabelGreyColor];
    if (section == STPPaymentCardNumberSection) {
        label.attributedText = [[NSAttributedString alloc] initWithString:@"Card" attributes:attributes];
        return label;
    } else if (section == STPPaymentCardBillingAddressSection) {
        label.attributedText = [[NSAttributedString alloc] initWithString:@"Billing Address" attributes:attributes];
        return label;
    }
    return nil;
}

@end
