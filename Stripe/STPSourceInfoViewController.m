//
//  STPSourceInfoViewController.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceInfoViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPCoreTableViewController+Private.h"
#import "STPLocalizationUtils.h"
#import "STPSourceParams.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "STPBankPickerDataSource.h"
#import "STPCountryPickerDataSource.h"
#import "STPPickerTableViewCell.h"
#import "STPSource+Private.h"
#import "STPTextFieldTableViewCell.h"

@interface STPSourceInfoViewController () <UITableViewDelegate, UITableViewDataSource, STPTextFieldTableViewCellDelegate>

@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)STPSourceParams *sourceParams;
@property(nonatomic)NSArray<STPTextFieldTableViewCell *>*cells;

@end

@implementation STPSourceInfoViewController

+ (BOOL)canCollectInfoForSourceType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeBancontact:
        case STPSourceTypeGiropay:
        case STPSourceTypeIDEAL:
        case STPSourceTypeSofort:
            return YES;
        default:
            return NO;
    }
}

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                               theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (![[self class] canCollectInfoForSourceType:sourceParams.type]) {
        return nil;
    }
    if (self) {
        _sourceParams = sourceParams;
        self.title = [self titleForSourceType:sourceParams.type];
    }
    return self;
}

- (NSString *)titleForSourceType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeBancontact:
            return STPLocalizedString(@"Bancontact Info", @"Title for form to collect Bancontact account info");
        case STPSourceTypeGiropay:
            return STPLocalizedString(@"Giropay Info", @"Title for form to collect Giropay account info");
        case STPSourceTypeIDEAL:
            return STPLocalizedString(@"iDEAL Info", @"Title for form to collect iDEAL account info");
        case STPSourceTypeSofort:
            return STPLocalizedString(@"Sofort Info", @"Title for form to collect Sofort account info");
        default:
            return @"";
    }
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self createAndSetupCells];

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];
}

- (void)createAndSetupCells {
    STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
    nameCell.placeholder = STPLocalizedString(@"Name", @"Caption for Name field on bank info form");
    if (self.sourceParams.owner) {
        nameCell.contents = self.sourceParams.owner[@"name"];
    }
    switch (self.sourceParams.type) {
        case STPSourceTypeBancontact:
        case STPSourceTypeGiropay: {
            self.cells = @[nameCell];
            break;
        }
        case STPSourceTypeIDEAL: {
            STPPickerTableViewCell *bankCell = [[STPPickerTableViewCell alloc] init];
            bankCell.placeholder = STPLocalizedString(@"Bank", @"Caption for Bank field on bank info form");
            bankCell.pickerDataSource = [STPBankPickerDataSource iDEALBankDataSource];
            NSDictionary *idealDict = self.sourceParams.additionalAPIParameters[@"ideal"];
            if (idealDict) {
                bankCell.contents = idealDict[@"bank"];
            }
            self.cells = @[nameCell, bankCell];
            break;
        }
        case STPSourceTypeSofort: {
            STPPickerTableViewCell *countryCell = [[STPPickerTableViewCell alloc] init];
            countryCell.placeholder = STPLocalizedString(@"Country", @"Caption for Country field on bank info form");
            NSArray *sofortCountries = @[@"AT", @"BE", @"FR", @"DE", @"NL"];
            countryCell.pickerDataSource = [[STPCountryPickerDataSource alloc] initWithCountryCodes:sofortCountries];
            NSDictionary *sofortDict = self.sourceParams.additionalAPIParameters[@"sofort"];
            if (sofortDict) {
                countryCell.contents = sofortDict[@"country"];
            }
            self.cells = @[countryCell];
            break;
        }
        default:
            break;
    }
    STPTextFieldTableViewCell *lastCell = [self.cells lastObject];
    for (STPTextFieldTableViewCell *cell in self.cells) {
        cell.delegate = self;
        cell.lastInList = (cell == lastCell);
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

    for (STPTextFieldTableViewCell *cell in self.cells) {
        cell.theme = self.theme;
    }

    self.tableView.allowsSelection = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {
    for (STPTextFieldTableViewCell *cell in self.cells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate sourceInfoViewControllerDidCancel:self];
}

- (void)nextPressed:(__unused id)sender {
    STPSourceParams *params = [self completedSourceParams];
    [self.delegate sourceInfoViewController:self
                  didFinishWithSourceParams:params];
}

- (void)updateDoneButton {
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = self.validContents;
}

- (BOOL)validContents {
    BOOL valid = YES;
    for (STPTextFieldTableViewCell *cell in self.cells) {
        valid = valid && (cell.contents.length > 0);
    }
    return valid;
}

- (STPTextFieldTableViewCell *)cellBeforeCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.cells indexOfObject:cell];
    return [self.cells stp_boundSafeObjectAtIndex:index - 1];
}

- (STPTextFieldTableViewCell *)cellAfterCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.cells indexOfObject:cell];
    return [self.cells stp_boundSafeObjectAtIndex:index + 1];
}

- (STPSourceParams *)completedSourceParams {
    STPSourceParams *params = [self.sourceParams copy];
    NSMutableDictionary *owner = nil;
    if (params.owner) {
        owner = [params.owner mutableCopy];
    } else {
        owner = [NSMutableDictionary new];
    }
    NSMutableDictionary *additionalParams = nil;
    if (params.additionalAPIParameters) {
        additionalParams = [params.additionalAPIParameters mutableCopy];
    } else {
        additionalParams = [NSMutableDictionary new];
    }
    switch (self.sourceParams.type) {
        case STPSourceTypeBancontact:
        case STPSourceTypeGiropay: {
            STPTextFieldTableViewCell *nameCell = [self.cells stp_boundSafeObjectAtIndex:0];
            owner[@"name"] = nameCell.contents;
            params.owner = owner;
            break;
        }
        case STPSourceTypeIDEAL: {
            STPTextFieldTableViewCell *nameCell = [self.cells stp_boundSafeObjectAtIndex:0];
            owner[@"name"] = nameCell.contents;
            params.owner = owner;
            NSMutableDictionary *idealDict = nil;
            if (additionalParams[@"ideal"]) {
                idealDict = additionalParams[@"ideal"];
            } else {
                idealDict = [NSMutableDictionary new];
            }
            STPTextFieldTableViewCell *bankCell = [self cellAfterCell:nameCell];
            idealDict[@"bank"] = bankCell.contents;
            additionalParams[@"ideal"] = idealDict;
            params.additionalAPIParameters = additionalParams;
            break;
        }
        case STPSourceTypeSofort: {
            NSMutableDictionary *sofortDict = nil;
            if (additionalParams[@"sofort"]) {
                sofortDict = additionalParams[@"sofort"];
            } else {
                sofortDict = [NSMutableDictionary new];
            }
            STPTextFieldTableViewCell *countryCell = [self.cells stp_boundSafeObjectAtIndex:0];
            sofortDict[@"country"] = countryCell.contents;
            additionalParams[@"sofort"] = sofortDict;
            params.additionalAPIParameters = additionalParams;
            break;
        }
        default:
            break;
    }
    return params;
}

#pragma mark - STPTextFieldTableViewCellDelegate

- (void)textFieldTableViewCellDidUpdateText:(__unused STPTextFieldTableViewCell *)cell {
    [self updateDoneButton];
}

- (void)textFieldTableViewCellDidReturn:(STPTextFieldTableViewCell *)cell {
    [[self cellAfterCell:cell] becomeFirstResponder];
}

- (void)textFieldTableViewCellDidBackspaceOnEmpty:(STPTextFieldTableViewCell *)cell {
    [[self cellBeforeCell:cell] becomeFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.cells count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.cells stp_boundSafeObjectAtIndex:indexPath.row];
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

@end
