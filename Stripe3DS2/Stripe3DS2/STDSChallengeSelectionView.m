//
//  STDSChallengeSelectionView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSLocalizedString.h"
#import "STDSBundleLocator.h"
#import "STDSChallengeSelectionView.h"
#import "STDSStackView.h"
#import "UIView+LayoutSupport.h"
#import "STDSSelectionButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeResponseSelectionRow: STDSStackView

typedef NS_ENUM(NSInteger, STDSChallengeResponseSelectionRowStyle) {
    
    /// A display style for showing a radio button.
    STDSChallengeResponseSelectionRowStyleRadio = 0,
    
    /// A display style for shows a checkbox.
    STDSChallengeResponseSelectionRowStyleCheckbox = 1,
};

typedef void (^STDSChallengeResponseRowSelectedBlock)(STDSChallengeResponseSelectionRow *);

@property (nonatomic, strong, readonly) id<STDSChallengeResponseSelectionInfo> challengeSelectInfo;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, strong) STDSLabelCustomization *labelCustomization;
@property (nonatomic, strong) STDSSelectionCustomization *selectionCustomization;

- (instancetype)initWithChallengeSelectInfo:(id<STDSChallengeResponseSelectionInfo>)challengeSelectInfo rowStyle:(STDSChallengeResponseSelectionRowStyle)rowStyle rowSelectedBlock:(STDSChallengeResponseRowSelectedBlock)rowSelectedBlock;

@end

@interface STDSChallengeResponseSelectionRow()

@property (nonatomic, strong) id<STDSChallengeResponseSelectionInfo> challengeSelectInfo;
@property (nonatomic, strong) STDSChallengeResponseRowSelectedBlock rowSelectedBlock;
@property (nonatomic) STDSChallengeResponseSelectionRowStyle rowStyle;
@property (nonatomic, strong) STDSSelectionButton *selectionButton;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UITapGestureRecognizer *valueLabelTapRecognizer;

@end

@implementation STDSChallengeResponseSelectionRow

- (instancetype)initWithChallengeSelectInfo:(id<STDSChallengeResponseSelectionInfo>)challengeSelectInfo rowStyle:(STDSChallengeResponseSelectionRowStyle)rowStyle rowSelectedBlock:(STDSChallengeResponseRowSelectedBlock)rowSelectedBlock {
    self = [super initWithAlignment:STDSStackViewLayoutAxisHorizontal];

    if (self) {
        _challengeSelectInfo = challengeSelectInfo;
        _rowStyle = rowStyle;
        _rowSelectedBlock = rowSelectedBlock;
        self.isAccessibilityElement = YES;
        self.accessibilityIdentifier = @"STDSChallengeResponseSelectionRow";

        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)_setupViewHierarchy {
    self.selectionButton = [[STDSSelectionButton alloc] initWithCustomization:self.selectionCustomization];
    self.selectionButton.customization = self.selectionCustomization;
    [self.selectionButton addTarget:self action:@selector(_rowWasSelected) forControlEvents:UIControlEventTouchUpInside];

    if (self.rowStyle == STDSChallengeResponseSelectionRowStyleCheckbox) {
        self.selectionButton.isCheckbox = YES;
    }

    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.text = self.challengeSelectInfo.value;
    self.valueLabel.userInteractionEnabled = YES;
    self.valueLabel.numberOfLines = 0;
    self.valueLabelTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_rowWasSelected)];
    [self.valueLabel addGestureRecognizer:self.valueLabelTapRecognizer];

    [self addArrangedSubview:self.selectionButton];
    [self addSpacer:15.0];
    [self addArrangedSubview:self.valueLabel];
    [self addArrangedSubview:[UIView new]];
}

- (void)_rowWasSelected {
    self.rowSelectedBlock(self);
}

- (BOOL)isSelected {
    /// Placeholder until visual and interaction design is complete.
    return self.selectionButton.isSelected;
}

- (void)setSelected:(BOOL)selected {
    /// Placeholder until visual and interaction design is complete.
    self.selectionButton.selected = selected;
}

- (void)setLabelCustomization:(STDSLabelCustomization *)labelCustomization {
    _labelCustomization = labelCustomization;
    
    self.valueLabel.font = labelCustomization.font;
    self.valueLabel.textColor = labelCustomization.textColor;
}

- (void)setSelectionCustomization:(STDSSelectionCustomization *)selectionCustomization {
    _selectionCustomization = selectionCustomization;
    
    self.selectionButton.customization = selectionCustomization;
}

#pragma mark - UIAccessibility

- (BOOL)accessibilityActivate {
    self.rowSelectedBlock(self);
    return YES;
}

- (nullable NSString *)accessibilityLabel {
    return self.valueLabel.text;
}

- (nullable NSString *)accessibilityValue {
    return self.selected ? STDSLocalizedString(@"Selected", @"Indicates that a button is selected.") : STDSLocalizedString(@"Unselected", @"Indicates that a button is not selected.");
}

- (UIAccessibilityTraits)accessibilityTraits {
    // remove the selected trait since we manually add that as an accessibilityValue above
    return (self.selectionButton.accessibilityTraits & ~UIAccessibilityTraitSelected);
}

@end

@interface STDSChallengeSelectionView()

@property (nonatomic, strong) STDSStackView *containerView;
@property (nonatomic, strong) NSArray<STDSChallengeResponseSelectionRow *> *challengeSelectionRows;

@property (nonatomic) STDSChallengeSelectionStyle selectionStyle;

@end

@implementation STDSChallengeSelectionView

static const CGFloat kChallengeSelectionViewTopPadding = 5;
static const CGFloat kChallengeSelectionViewBottomPadding = 20;
static const CGFloat kChallengeSelectionViewInterRowVerticalPadding = 16;

- (instancetype)initWithChallengeSelectInfo:(NSArray<id<STDSChallengeResponseSelectionInfo>> *)challengeSelectInfo selectionStyle:(STDSChallengeSelectionStyle)selectionStyle {
    self = [super init];
    
    if (self) {
        _selectionStyle = selectionStyle;
        _challengeSelectionRows = [self _rowsForChallengeSelectInfo:challengeSelectInfo];

        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)_setupViewHierarchy {
    self.containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    
    for (STDSChallengeResponseSelectionRow *selectionRow in self.challengeSelectionRows) {
        [self.containerView addArrangedSubview:selectionRow];
        
        if (selectionRow != self.challengeSelectionRows.lastObject) {
            [self.containerView addSpacer:kChallengeSelectionViewInterRowVerticalPadding];
        }
    }
    
    if (self.challengeSelectionRows.count > 0) {
        self.layoutMargins = UIEdgeInsetsMake(kChallengeSelectionViewTopPadding, 0, kChallengeSelectionViewBottomPadding, 0);
    } else {
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    [self addSubview:self.containerView];
    [self.containerView _stds_pinToSuperviewBounds];
}

- (NSArray<STDSChallengeResponseSelectionRow *> *)_rowsForChallengeSelectInfo:(NSArray<id<STDSChallengeResponseSelectionInfo>> *)challengeSelectInfo {
    NSMutableArray *challengeRows = [NSMutableArray array];
    STDSChallengeResponseSelectionRowStyle rowStyle = self.selectionStyle == STDSChallengeSelectionStyleSingle ? STDSChallengeResponseSelectionRowStyleRadio : STDSChallengeResponseSelectionRowStyleCheckbox;
    
    for (id<STDSChallengeResponseSelectionInfo> selectionInfo in challengeSelectInfo) {
        __weak typeof(self) weakSelf = self;
        STDSChallengeResponseSelectionRow *challengeRow = [[STDSChallengeResponseSelectionRow alloc] initWithChallengeSelectInfo:selectionInfo rowStyle:rowStyle rowSelectedBlock:^(STDSChallengeResponseSelectionRow * _Nonnull selectedRow) {
            __strong typeof(self) strongSelf = weakSelf;
            
            [strongSelf _rowWasSelected:selectedRow];
        }];
        
        if (selectionInfo == challengeSelectInfo.firstObject && self.selectionStyle == STDSChallengeSelectionStyleSingle) {
            challengeRow.selected = YES;
        }
        
        [challengeRows addObject:challengeRow];
    }
    
    return [challengeRows copy];
}

- (void)_rowWasSelected:(STDSChallengeResponseSelectionRow *)selectedRow {
    switch (self.selectionStyle) {
        case STDSChallengeSelectionStyleSingle:
            for (STDSChallengeResponseSelectionRow *row in self.challengeSelectionRows) {
                row.selected = row == selectedRow;
            }
            
            break;
        case STDSChallengeSelectionStyleMulti:
            selectedRow.selected = !selectedRow.isSelected;
            break;
    }
}

- (NSArray<id<STDSChallengeResponseSelectionInfo>> *)currentlySelectedChallengeInfo {
    NSMutableArray *selectedChallengeInfo = [NSMutableArray array];
    
    for (STDSChallengeResponseSelectionRow *selectionRow in self.challengeSelectionRows) {
        if (selectionRow.isSelected) {
            [selectedChallengeInfo addObject:selectionRow.challengeSelectInfo];
        }
    }
    
    return [selectedChallengeInfo copy];
}

- (void)setLabelCustomization:(STDSLabelCustomization *)labelCustomization {
    _labelCustomization = labelCustomization;
    
    for (STDSChallengeResponseSelectionRow *row in self.challengeSelectionRows) {
        row.labelCustomization = labelCustomization;
    }
}

- (void)setSelectionCustomization:(STDSSelectionCustomization *)selectionCustomization {
    _selectionCustomization = selectionCustomization;
    
    for (STDSChallengeResponseSelectionRow *row in self.challengeSelectionRows) {
        row.selectionCustomization = selectionCustomization;
    }
}

@end

NS_ASSUME_NONNULL_END
