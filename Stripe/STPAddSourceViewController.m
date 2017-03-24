//
//  STPAddSourceViewController.m
//  Stripe
//
//  Created by Ben Guo on 2/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAddSourceViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "NSString+Stripe.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPAddressViewModel.h"
#import "STPCoreTableViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPIBANTableViewCell.h"
#import "STPIBANValidator.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPInfoFooterView.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPRememberMePaymentCell.h"
#import "STPSectionHeaderView.h"
#import "STPTextFieldTableViewCell.h"
#import "UIBarButtonItem+Stripe.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIToolbar+Stripe_InputAccessory.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

typedef NS_ENUM(NSUInteger, STPAddSourceSection) {
    STPAddSourceFirstSection = 0,
    STPAddSourceAddressSection = 1,
};

@interface STPAddSourceViewController ()<STPAddressViewModelDelegate, UITableViewDelegate, UITableViewDataSource, STPPaymentCardTextFieldDelegate, STPTextFieldTableViewCellDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)STPAddressViewModel *addressViewModel;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic, weak)UIImageView *imageView;
@property(nonatomic)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic)STPSectionHeaderView *firstSectionHeaderView;
@property(nonatomic)STPSectionHeaderView *addressHeaderView;
@property(nonatomic)STPTextFieldTableViewCell *nameCell;
@property(nonatomic)STPIBANTableViewCell *ibanCell;
@property(nonatomic)STPRememberMePaymentCell *cardCell;
@property(nonatomic)STPInfoFooterView *sepaFooterView;
@property(nonatomic)UIToolbar *inputAccessoryToolbar;
@property(nonatomic)STPSourceType sourceType;
@property(nonatomic)BOOL loading;

@end

@implementation STPAddSourceViewController

+ (BOOL)canCreateSourceWithType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeCard:
        case STPSourceTypeSEPADebit:
            return YES;
        default:
            return NO;
    }
}

- (nullable instancetype)initWithSourceType:(STPSourceType)sourceType
                              configuration:(STPPaymentConfiguration *)configuration
                                      theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (![[self class] canCreateSourceWithType:sourceType]) {
        return nil;
    }
    if (self) {
        _sourceType = sourceType;
        [self commonInitWithConfiguration:configuration];
    }
    return self;
}

- (void)commonInitWithConfiguration:(STPPaymentConfiguration *)configuration {
    _configuration = configuration;
    _apiClient = [[STPAPIClient alloc] initWithConfiguration:configuration];
    STPAddressViewModel *addressViewModel;
    if (self.sourceType == STPSourceTypeCard) {
        self.title = STPLocalizedString(@"Add a Card", @"Title for Add a Card view");
        addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:configuration.requiredBillingAddressFields];
    } else if (self.sourceType == STPSourceTypeSEPADebit) {
        self.title = STPLocalizedString(@"Add a SEPA Debit Account", @"Title for SEPA Debit Account form");
        addressViewModel = [[STPAddressViewModel alloc] initWithSEPADebitFields];
    }
    addressViewModel.delegate = self;
    _addressViewModel = addressViewModel;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    if (self.prefilledInformation.billingAddress != nil) {
        self.addressViewModel.address = self.prefilledInformation.billingAddress;
    }

    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;

    STPRememberMePaymentCell *cardCell = [[STPRememberMePaymentCell alloc] init];
    cardCell.paymentField.delegate = self;
    self.cardCell = cardCell;

    STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
    nameCell.placeholder = STPLocalizedString(@"Name", @"Caption for Name field on address form");
    nameCell.delegate = self;
    self.nameCell = nameCell;

    STPIBANTableViewCell *ibanCell = [[STPIBANTableViewCell alloc] init];
    ibanCell.delegate = self;
    self.ibanCell = ibanCell;

    STPInfoFooterView *footerView = [[STPInfoFooterView alloc] init];
    NSString *template = STPLocalizedString(@"By providing your IBAN and confirming this payment, you are authorizing %@ and Stripe, our payment service provider, to send instructions to your bank to debit your account and your bank to debit your account in accordance with those instructions. You are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited.", @"SEPA legal authorization text – must use official translations");
    footerView.textView.text = [NSString stringWithFormat:template, self.configuration.companyName];
    self.sepaFooterView = footerView;

    UIToolbar *inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(firstSectionNextTapped)];
    [inputAccessoryToolbar stp_setEnabled:NO];
    self.inputAccessoryToolbar = inputAccessoryToolbar;
    self.cardCell.inputAccessoryView = self.inputAccessoryToolbar;

    STPSectionHeaderView *firstSectionHeader = [STPSectionHeaderView new];
    firstSectionHeader.buttonHidden = YES;
    self.firstSectionHeaderView = firstSectionHeader;

    STPSectionHeaderView *addressHeaderView = [STPSectionHeaderView addressHeaderWithConfiguration:self.configuration
                                                                                        sourceType:self.sourceType
                                                                                  addressViewModel:self.addressViewModel
                                                                                   shippingAddress:self.shippingAddress];
    [addressHeaderView.button addTarget:self action:@selector(useShippingAddress:)
                       forControlEvents:UIControlEventTouchUpInside];
    self.addressHeaderView = addressHeaderView;

    UIImage *image;
    if (self.sourceType == STPSourceTypeCard) {
        self.addressViewModel.previousField = cardCell;
        self.firstSectionHeaderView.title = STPLocalizedString(@"Card", @"Title for credit card number entry field");
        image = [STPImageLibrary largeCardFrontImage];
    } else if (self.sourceType == STPSourceTypeSEPADebit) {
        self.addressViewModel.previousField = ibanCell;
        self.firstSectionHeaderView.title = STPLocalizedString(@"Bank Account Information", @"Title for IBAN entry field");
        image = [STPImageLibrary largeShippingImage]; // TODO: replace placeholder image
    }
    [self.firstSectionHeaderView setNeedsLayout];
    [self.addressHeaderView setNeedsLayout];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, imageView.bounds.size.height + (57 * 2));
    self.imageView = imageView;
    self.tableView.tableHeaderView = imageView;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];
}

- (void)endEditing {
    [self.view endEditing:NO];
}

- (void)updateAppearance {
    [super updateAppearance];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.doneItem stp_setTheme:navBarTheme];
    self.tableView.allowsSelection = NO;

    self.imageView.tintColor = self.theme.accentColor;
    self.activityIndicator.tintColor = self.theme.accentColor;

    self.firstSectionHeaderView.theme = self.theme;
    self.addressHeaderView.theme = self.theme;

    self.cardCell.theme = self.theme;
    self.ibanCell.theme = self.theme;
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.theme;
    }
    self.sepaFooterView.theme = self.theme;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.stp_navigationItemProxy setHidesBackButton:loading animated:YES];
    self.stp_navigationItemProxy.leftBarButtonItem.enabled = !loading;
    self.activityIndicator.animating = loading;
    if (loading) {
        [self.tableView endEditing:YES];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        [self.stp_navigationItemProxy setRightBarButtonItem:loadingItem animated:YES];
    } else {
        [self.stp_navigationItemProxy setRightBarButtonItem:self.doneItem animated:YES];
    }
    NSArray *cells = self.addressViewModel.addressCells;
    for (UITableViewCell *cell in [cells arrayByAddingObjectsFromArray:@[self.cardCell, self.ibanCell]] ) {
        cell.userInteractionEnabled = !loading;
        [UIView animateWithDuration:0.1f animations:^{
            cell.alpha = loading ? 0.7f : 1.0f;
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {
    if (self.sourceType == STPSourceTypeCard && self.cardCell.isEmpty) {
        return self.cardCell;
    }
    if (self.sourceType == STPSourceTypeSEPADebit) {
        for (STPTextFieldTableViewCell *cell in @[self.nameCell, self.ibanCell]) {
            if (cell.contents.length == 0) {
                return cell;
            }
        }
    }
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate addSourceViewControllerDidCancel:self];
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    STPSourceParams *params;
    if (self.sourceType == STPSourceTypeCard) {
        STPCardParams *cardParams = self.cardCell.paymentField.cardParams;
        cardParams.address = self.addressViewModel.address;
        params = [STPSourceParams cardParamsWithCard:cardParams];
    } else if (self.sourceType == STPSourceTypeSEPADebit) {
        STPAddress *address = self.addressViewModel.address;
        params = [STPSourceParams sepaDebitParamsWithName:self.nameCell.contents
                                                     iban:self.ibanCell.contents
                                             addressLine1:address.line1
                                                     city:address.city
                                               postalCode:address.postalCode
                                                  country:address.country];
    }
    [self.apiClient createSourceWithParams:params completion:^(STPSource *source, NSError *sourceError) {
        if (sourceError) {
            [self handleError:sourceError];
        } else {
            [self.delegate addSourceViewController:self didCreateSource:source completion:^(NSError *error) {
                stpDispatchToMainThreadIfNecessary(^{
                    if (error) {
                        [self handleError:error];
                    }
                    else {
                        self.loading = NO;
                    }
                });
            }];
        }
    }];
}

- (void)handleError:(NSError *)error {
    self.loading = NO;
    [[self firstEmptyField] becomeFirstResponder];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:STPLocalizedString(@"OK", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)updateDoneButton {
    BOOL enabled = YES;
    if (self.sourceType == STPSourceTypeCard) {
        enabled = enabled && self.cardCell.paymentField.isValid;
    } else if (self.sourceType == STPSourceTypeSEPADebit){
        enabled = enabled && self.nameCell.isValid && self.ibanCell.isValid;
    }
    enabled = enabled && self.addressViewModel.isValid;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = enabled;
}

#pragma mark - Card/IBAN section

- (void)textFieldTableViewCellDidUpdateText:(STPTextFieldTableViewCell *)cell {
    [self.inputAccessoryToolbar stp_setEnabled:cell.isValid];
    if (cell == self.ibanCell && cell.contents.length >= 2 &&
        [STPIBANValidator stringIsValidPartialIBAN:cell.contents]) {
        STPAddress *address = self.addressViewModel.address;
        NSString *country = [[cell.contents stp_safeSubstringToIndex:2] uppercaseString];
        if (address.country != country) {
            address.country = country;
            self.addressViewModel.address = address;
        }
    }
    [self updateDoneButton];
}

- (void)textFieldTableViewCellDidBackspaceOnEmpty:(STPTextFieldTableViewCell *)cell {
    if (cell == self.ibanCell) {
        [self.nameCell becomeFirstResponder];
    }
}

- (void)textFieldTableViewCellDidReturn:(STPTextFieldTableViewCell *)cell {
    if (cell == self.nameCell) {
        [self.ibanCell becomeFirstResponder];
    } else if (cell == self.ibanCell) {
        [self firstSectionNextTapped];
    }
}

- (void)firstSectionNextTapped {
    [[self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:0] becomeFirstResponder];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    [self.inputAccessoryToolbar stp_setEnabled:textField.isValid];
    [self updateDoneButton];
}

- (void)paymentCardTextFieldDidBeginEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.imageView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        self.imageView.image = [STPImageLibrary largeCardBackImage];
                    } completion:nil];
}

- (void)paymentCardTextFieldDidEndEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.imageView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.imageView.image = [STPImageLibrary largeCardFrontImage];
                    } completion:nil];
}

#pragma mark - STPAddressViewModelDelegate

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel addedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPAddSourceAddressSection];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel removedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPAddSourceAddressSection];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addressViewModelDidChange:(__unused STPAddressViewModel *)addressViewModel {
    [self updateDoneButton];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case STPAddSourceFirstSection:
            switch (self.sourceType) {
                case STPSourceTypeCard: return 1;
                case STPSourceTypeSEPADebit: return 2;
                default: return 0;
            }
        case STPAddSourceAddressSection:
            return self.addressViewModel.addressCells.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case STPAddSourceFirstSection:
            if (self.sourceType == STPSourceTypeCard) {
                cell = self.cardCell;
            } else if (self.sourceType == STPSourceTypeSEPADebit) {
                if (indexPath.row == 0) {
                    cell = self.nameCell;
                } else {
                    cell = self.ibanCell;
                }
            }
            break;
        case STPAddSourceAddressSection:
            cell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
            break;
        default:
            cell = [UITableViewCell new];
            break;
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == STPAddSourceAddressSection && self.sourceType == STPSourceTypeSEPADebit) {
        return [self.sepaFooterView heightForWidth:CGRectGetWidth(self.tableView.frame)];
    } else if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    } else {
        return 27.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGSize fittingSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
    NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:section];
    if (section == STPAddSourceFirstSection) {
        return [self.firstSectionHeaderView sizeThatFits:fittingSize].height;
    } else if (section == STPAddSourceAddressSection && numberOfRows != 0) {
        return [self.addressHeaderView sizeThatFits:fittingSize].height;
    }
    return 0.01f;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else if (section == STPAddSourceFirstSection) {
        return self.firstSectionHeaderView;
    } else if (section == STPAddSourceAddressSection) {
        return self.addressHeaderView;
    }
    return nil;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(__unused NSInteger)section {
    if (section == STPAddSourceAddressSection && self.sourceType == STPSourceTypeSEPADebit) {
        return self.sepaFooterView;
    } else {
        return [UIView new];
    }
}

- (void)useShippingAddress:(__unused UIButton *)sender {
    [self.tableView beginUpdates];
    self.addressViewModel.address = self.shippingAddress;
    [[self firstEmptyField] becomeFirstResponder];
    [UIView animateWithDuration:0.2f animations:^{
        self.addressHeaderView.buttonHidden = YES;
    }];
    [self.tableView endUpdates];
}

@end
