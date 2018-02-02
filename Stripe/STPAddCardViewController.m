//
//  STPAddCardViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddCardViewController.h"

#import "NSArray+Stripe.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPAddressViewModel.h"
#import "STPAnalyticsClient.h"
#import "STPCardIOProxy.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPEmailAddressValidator.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPhoneNumberValidator.h"
#import "STPPaymentCardTextFieldCell.h"
#import "STPPromise.h"
#import "STPSectionHeaderView.h"
#import "STPSourceParams.h"
#import "STPToken.h"
#import "STPWeakStrongMacros.h"
#import "StripeError.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIToolbar+Stripe_InputAccessory.h"
#import "UIView+Stripe_FirstResponder.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPAddCardViewController ()<
    STPAddressViewModelDelegate,
    STPCardIOProxyDelegate,
    STPPaymentCardTextFieldDelegate,
    UITableViewDelegate,
    UITableViewDataSource>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) BOOL hasUsedShippingAddress;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, weak) UIImageView *cardImageView;
@property (nonatomic) UIBarButtonItem *doneItem;
@property (nonatomic) STPSectionHeaderView *cardHeaderView;
@property (nonatomic) STPCardIOProxy *cardIOProxy;
@property (nonatomic) STPSectionHeaderView *addressHeaderView;
@property (nonatomic) STPPaymentCardTextFieldCell *paymentCell;
@property (nonatomic) BOOL loading;
@property (nonatomic) STPPaymentActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) STPPaymentActivityIndicatorView *lookupActivityIndicator;
@property (nonatomic) STPAddressViewModel *addressViewModel;
@property (nonatomic) UIToolbar *inputAccessoryToolbar;
@property (nonatomic) BOOL lookupSucceeded;
@end

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";

typedef NS_ENUM(NSUInteger, STPPaymentCardSection) {
    STPPaymentCardNumberSection = 0,
    STPPaymentCardBillingAddressSection = 1,
};

@implementation STPAddCardViewController

- (instancetype)init {
    return [self initWithConfiguration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (self) {
        [self commonInitWithConfiguration:configuration];
    }
    return self;
}

- (void)commonInitWithConfiguration:(STPPaymentConfiguration *)configuration {
    _configuration = configuration;
    _shippingAddress = nil;
    _hasUsedShippingAddress = NO;
    _apiClient = [[STPAPIClient alloc] initWithConfiguration:configuration];
    _addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:configuration.requiredBillingAddressFields];
    _addressViewModel.delegate = self;

    self.title = STPLocalizedString(@"Add a Card", @"Title for Add a Card view");
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.cardImageView = cardImageView;
    self.tableView.tableHeaderView = cardImageView;

    STPPaymentCardTextFieldCell *paymentCell = [[STPPaymentCardTextFieldCell alloc] init];
    paymentCell.paymentField.delegate = self;
    self.paymentCell = paymentCell;

    if (self.prefilledInformation.billingAddress != nil) {
        self.addressViewModel.address = self.prefilledInformation.billingAddress;
    }
    
    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];
    
    self.inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(paymentFieldNextTapped)];
    [self.inputAccessoryToolbar stp_setEnabled:NO];
    [self updateInputAccessoryVisiblity];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    STPSectionHeaderView *addressHeaderView = [STPSectionHeaderView new];
    addressHeaderView.theme = self.theme;
    addressHeaderView.title = STPLocalizedString(@"Billing Address", @"Title for billing address entry section");
    switch (self.configuration.shippingType) {
        case STPShippingTypeShipping:
            [addressHeaderView.button setTitle:STPLocalizedString(@"Use Shipping", @"Button to fill billing address from shipping address.")
                                      forState:UIControlStateNormal];
            break;
        case STPShippingTypeDelivery:
            [addressHeaderView.button setTitle:STPLocalizedString(@"Use Delivery", @"Button to fill billing address from delivery address.")
                                      forState:UIControlStateNormal];
            break;
    }
    [addressHeaderView.button addTarget:self action:@selector(useShippingAddress:)
                       forControlEvents:UIControlEventTouchUpInside];
    STPBillingAddressFields requiredFields = self.configuration.requiredBillingAddressFields;
    BOOL needsAddress = requiredFields != STPBillingAddressFieldsNone && !self.addressViewModel.isValid;
    BOOL buttonVisible = (needsAddress &&
                          [self.shippingAddress containsContentForBillingAddressFields:requiredFields]
                          && !self.hasUsedShippingAddress);
    addressHeaderView.buttonHidden = !buttonVisible;
    [addressHeaderView setNeedsLayout];
    _addressHeaderView = addressHeaderView;
    STPSectionHeaderView *cardHeaderView = [STPSectionHeaderView new];
    cardHeaderView.theme = self.theme;
    cardHeaderView.title = STPLocalizedString(@"Card", @"Title for credit card number entry field");
    cardHeaderView.buttonHidden = YES;
    _cardHeaderView = cardHeaderView;

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];

    [self setUpCardScanningIfAvailable];

    [[STPAnalyticsClient sharedClient] clearAdditionalInfo];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Resetting it re-calculates the size based on new view width
    // UITableView requires us to call setter again to actually pick up frame
    // change on footers
    if (self.tableView.tableFooterView) {
        self.customFooterView = self.tableView.tableFooterView;
    }
}

- (void)setUpCardScanningIfAvailable {
    if ([STPCardIOProxy isCardIOAvailable]) {
        self.cardIOProxy = [[STPCardIOProxy alloc] initWithDelegate:self];
        self.cardHeaderView.buttonHidden = NO;
        [self.cardHeaderView.button setTitle:STPLocalizedString(@"Scan Card", @"Text for button to scan a credit card") forState:UIControlStateNormal];
        [self.cardHeaderView.button addTarget:self action:@selector(presentCardIO) forControlEvents:UIControlEventTouchUpInside];
        [self.cardHeaderView setNeedsLayout];
    }
}

- (void)presentCardIO {
    [self.cardIOProxy presentCardIOFromViewController:self];
}

- (void)cardIOProxy:(__unused STPCardIOProxy *)proxy didFinishWithCardParams:(STPCardParams *)cardParams {
    if (cardParams) {
        self.paymentCell.paymentField.cardParams = cardParams;
    }
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
    
    self.cardImageView.tintColor = self.theme.accentColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
    
    self.paymentCell.theme = self.theme;
    
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.theme;
    }
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
    for (UITableViewCell *cell in [cells arrayByAddingObject:self.paymentCell]) {
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

    if (self.paymentCell.isEmpty) {
        return self.paymentCell;
    }
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleCancelTapped:(__unused id)sender {
    [self.delegate addCardViewControllerDidCancel:self];
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    STPCardParams *cardParams = self.paymentCell.paymentField.cardParams;
    cardParams.address = self.addressViewModel.address;
    cardParams.currency = self.managedAccountCurrency;
    if (cardParams) {
        // Create and return a card source
        if (self.configuration.createCardSources) {
            STPSourceParams *sourceParams = [STPSourceParams cardParamsWithCard:cardParams];
            [self.apiClient createSourceWithParams:sourceParams completion:^(STPSource * _Nullable source, NSError * _Nullable tokenizationError) {
                if (tokenizationError) {
                    [self handleCardTokenizationError:tokenizationError];
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(addCardViewController:didCreateSource:completion:)]) {
                        [self.delegate addCardViewController:self didCreateSource:source completion:^(NSError * _Nullable error) {
                            stpDispatchToMainThreadIfNecessary(^{
                                if (error) {
                                    [self handleCardTokenizationError:error];
                                }
                                else {
                                    self.loading = NO;
                                }
                            });
                        }];
                    }
                    else {
                        self.loading = NO;
                    }
                }
            }];
        }
        // Create and return a card token
        else {
            [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *tokenizationError) {
                if (tokenizationError) {
                    [self handleCardTokenizationError:tokenizationError];
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(addCardViewController:didCreateToken:completion:)]) {
                        [self.delegate addCardViewController:self didCreateToken:token completion:^(NSError * _Nullable error) {
                            stpDispatchToMainThreadIfNecessary(^{
                                if (error) {
                                    [self handleCardTokenizationError:error];
                                }
                                else {
                                    self.loading = NO;
                                }
                            });
                        }];
                    }
                    else {
                        self.loading = NO;
                    }
                }
            }];
        }
    }
}

- (void)handleCardTokenizationError:(NSError *)error {
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
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = (self.paymentCell.paymentField.isValid
                                                               && self.addressViewModel.isValid
                                                               );
}

- (void)updateInputAccessoryVisiblity {
    // The inputAccessoryToolbar switches from the paymentCell to the first address field.
    // It should only be shown when there *is* an address field. This compensates for the lack
    // of a 'Return' key on the number pad used for paymentCell entry
    BOOL hasAddressCells = self.addressViewModel.addressCells.count > 0;
    self.paymentCell.inputAccessoryView = hasAddressCells ? self.inputAccessoryToolbar : nil;
}

- (void)setCustomFooterView:(UIView *)footerView {
    _customFooterView = footerView;
    [self.stp_willAppearPromise voidOnSuccess:^{
        CGSize size = [footerView sizeThatFits:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX)];
        footerView.frame = CGRectMake(0, 0, size.width, size.height);

        self.tableView.tableFooterView = footerView;
    }];
}

#pragma mark - STPPaymentCardTextField

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    [self.inputAccessoryToolbar stp_setEnabled:textField.isValid];
    [self updateDoneButton];
}

- (void)paymentFieldNextTapped {
    [[self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:0] becomeFirstResponder];
}

- (void)paymentCardTextFieldDidBeginEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.cardImageView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        self.cardImageView.image = [STPImageLibrary largeCardBackImage];
                    } completion:nil];
}

- (void)paymentCardTextFieldDidEndEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.cardImageView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.cardImageView.image = [STPImageLibrary largeCardFrontImage];
                    } completion:nil];
}

#pragma mark - STPAddressViewModelDelegate

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel addedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPPaymentCardBillingAddressSection];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateInputAccessoryVisiblity];
}

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel removedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPPaymentCardBillingAddressSection];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateInputAccessoryVisiblity];
}

- (void)addressViewModelDidChange:(__unused STPAddressViewModel *)addressViewModel {
    [self updateDoneButton];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardNumberSection) {
        return 1;
    }
    else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case STPPaymentCardNumberSection:
            cell = self.paymentCell;
            break;
        case STPPaymentCardBillingAddressSection:
            cell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
            break;
        default:
            return [UITableViewCell new]; // won't be called; exists to make the static analyzer happy
    }
    cell.backgroundColor = self.theme.secondaryBackgroundColor;
    cell.contentView.backgroundColor = [UIColor clearColor];
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
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGSize fittingSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
    NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:section];
    if (section == STPPaymentCardNumberSection) {
        return [self.cardHeaderView sizeThatFits:fittingSize].height;
    } else if (section == STPPaymentCardBillingAddressSection && numberOfRows != 0) {
        return [self.addressHeaderView sizeThatFits:fittingSize].height;
    } else if (numberOfRows != 0) {
        return tableView.sectionHeaderHeight;
    }
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else {
        if (section == STPPaymentCardNumberSection) {
            return self.cardHeaderView;
        } else if (section == STPPaymentCardBillingAddressSection) {
            return self.addressHeaderView;
        }
    }
    return nil;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(__unused NSInteger)section {
    return [UIView new];
}

- (void)useShippingAddress:(__unused UIButton *)sender {
    [self.tableView beginUpdates];
    self.addressViewModel.address = self.shippingAddress;
    self.hasUsedShippingAddress = YES;
    [[self firstEmptyField] becomeFirstResponder];
    [UIView animateWithDuration:0.2f animations:^{
        self.addressHeaderView.buttonHidden = YES;
    }];
    [self.tableView endUpdates];
}

@end
