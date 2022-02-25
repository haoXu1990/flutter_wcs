//
//  AWESlidingTabbarView.m
//  AWEUIKit
//
//  Created by bytedance  on 2018/6/22.
//

#import "UIView+DVEAlbumMasonry.h"
#import "DVEAlbumSlidingTabbarView.h"
#import "DVEAlbumSlidingViewController.h"
#import "DVEAlbumMacros.h"
#import "DVEAlbumResourceUnion.h"
#import "UIView+DVEAlbumUIKit.h"
#import <Masonry/View+MASAdditions.h>

static const CGFloat kTitleMinLength = 48;   //文字最小显示长度
static const CGFloat kTitlePadding = 17;     //button内文字最小左右边距
static const CGFloat kIconPadding = 16;      //button内icon最小左右边距
static const CGFloat kTitleAndIconSpace = 2.f;
static const CGFloat kFixedTabBarPaddingWidth = 8; //固定样式左右边距
static const CGFloat kButtonMinLength = 60;
static const CGFloat kButtonFontSize = 14;
static const CGFloat kButtonHeight = 21;

@interface DVEAlbumSlidingTabButton ()

@property (nonatomic, assign) DVEAlbumSlidingTabButtonStyle buttonStyle;
@property (nonatomic, strong) UIView *circleDot;     //右上角的小点
@property (nonatomic, strong) UIImageView *iconImageView;    //图片型的 button 内包含的图片（SCIFSlidingTabButtonStyleImageAndTitle）
@property (nonatomic, strong) UILabel *iconTitleLabel;      //图片型的 button 内包含的标题（SCIFSlidingTabButtonStyleImageAndTitle）
@property (nonatomic, assign) CGFloat iconImageViewRatio;   // 0.0f为为选中状态，1.0f为选中状态
@property (nonatomic, assign) CGFloat buttonWidth;   //button宽度
@property (nonatomic, assign) CGFloat lineWidth;     //底部黄线宽度
@property (nonatomic, assign) CGFloat lineX;         //底部黄线x坐标
@property (nonatomic, strong) UIFont *normalFont;
@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, assign) CGFloat titlePadding;
@property (nonatomic, assign) BOOL enableSwitchAnimation;

@end

@implementation DVEAlbumSlidingTabButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:kButtonFontSize];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.imageView.contentMode = UIViewContentModeCenter;
        [self setTitleColor:TOCResourceColor(TOCUIColorTextTertiary) forState:UIControlStateNormal];
        [self setTitleColor:TOCResourceColor(TOCUIColorTextPrimary) forState:UIControlStateSelected];
        
        self.circleDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 6)];
        self.circleDot.clipsToBounds = YES;
        self.circleDot.layer.cornerRadius = 3;
        self.circleDot.hidden = YES;
        
        self.selectedFont = [UIFont systemFontOfSize:kButtonFontSize weight:UIFontWeightMedium];
        self.normalFont = [UIFont systemFontOfSize:kButtonFontSize];

        if (self.buttonStyle == SCIFSlidingTabButtonStyleOriginText) {
            self.titlePadding = 0;
        } else if (self.buttonStyle == SCIFSlidingTabButtonStyleTextAndLineEqualLength) {
            self.titlePadding = 13;
        } else {
            self.titlePadding = 16;
        }
        [self addSubview:self.circleDot];
    }
    return self;
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.circleDot.frame;
    frame.origin.x = self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width;
    frame.origin.y = self.center.y - 10;
    self.circleDot.frame = frame;
}

- (void)setImageAndTitleStyleButton {
    DVEAlbumMasMaker(self.iconImageView, {
        make.top.equalTo(self).with.offset(20.f);
        make.centerX.equalTo(self);
        make.width.height.equalTo(@44.f);
    });
    
    DVEAlbumMasMaker(self.iconTitleLabel, {
        make.top.equalTo(self.iconImageView.mas_bottom).with.offset(5.f);
        make.left.right.equalTo(self);
        make.height.equalTo(@15.f);
    });
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    if (self.buttonStyle == SCIFSlidingTabButtonStyleIcon) {
        return CGRectMake(kIconPadding, 0, contentRect.size.width - kIconPadding * 2, contentRect.size.height);
    } else if (self.buttonStyle == SCIFSlidingTabButtonStyleIconAndText) {
        return [super imageRectForContentRect:contentRect];
    } else {
        return CGRectZero;
    }
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    if (self.buttonStyle != SCIFSlidingTabButtonStyleIcon) {
        return [super titleRectForContentRect:contentRect];
    } else {
        return CGRectZero;
    }
}

- (void)setButtonStyle:(DVEAlbumSlidingTabButtonStyle)buttonStyle
{
    _buttonStyle = buttonStyle;
    if (buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
        if (self.iconImageView.superview) {
            [self.iconImageView removeFromSuperview];
        } else if (self.iconTitleLabel.superview) {
            [self.iconTitleLabel removeFromSuperview];
        }
        [self addSubview:self.iconImageView];
        [self addSubview:self.iconTitleLabel];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (!self.enableSwitchAnimation) { // enableSwitchAnimation为True时，选中状态保持font不变
        self.titleLabel.font = selected ? self.selectedFont : self.normalFont;
    }
}

- (void)showDot:(BOOL)show color:(UIColor *)color
{
    self.circleDot.hidden = !show;
    self.circleDot.backgroundColor = color;
}

- (BOOL)isDotShown
{
    return !self.circleDot.hidden;
}

- (void)configureText:(NSString *)text imageName:(nullable NSString *)imageName selectedText:(NSString *)selectedText selectedImageName:(nullable NSString *)selectedImageName
{
    UIImage *image = imageName ? [UIImage imageNamed:imageName] : nil;
    UIImage *selectedImage = selectedImageName ? [UIImage imageNamed:selectedImageName] : nil;
    [self configureText:text image:image selectedText:selectedText selectedImage:selectedImage];
}

- (void)configureText:(NSString *)text image:(nullable UIImage *)image selectedText:(NSString *)selectedText selectedImage:(nullable UIImage *)selectedImage
{
    [self setTitle:text forState:UIControlStateNormal];
    if (image) {
        [self setImage:image forState:UIControlStateNormal];
        self.titleEdgeInsets = UIEdgeInsetsMake(0, kTitleAndIconSpace/2.0, 0, 0);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, kTitleAndIconSpace/2.0);
    } else {
        [self setImage:nil forState:UIControlStateNormal];
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
    }
    [self setTitle:selectedText forState:UIControlStateSelected];
    [self setImage:selectedImage forState:UIControlStateSelected];
}

- (CGFloat)buttonOriginWidth
{
    CGFloat normalTitleWidth = [[self titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : self.normalFont}].width;
    CGFloat selectedTitleSize = [[self titleForState:UIControlStateSelected] sizeWithAttributes:@{NSFontAttributeName : self.selectedFont}].width;
    CGFloat titleWidth = (!self.enableSwitchAnimation && selectedTitleSize > normalTitleWidth) ? selectedTitleSize : normalTitleWidth;
    CGFloat imageWidth = [[self imageForState:UIControlStateNormal] size].width;
    if (self.buttonStyle != SCIFSlidingTabButtonStyleIcon) {
        CGFloat buttonWidth = (titleWidth > 0 ? titleWidth : 0) + (imageWidth > 0 ? imageWidth : 0) + 2 * self.titlePadding;
        return buttonWidth > kButtonMinLength ? buttonWidth : kButtonMinLength;
    } else {
        CGFloat buttonWidth = (imageWidth > 0 ? imageWidth : 0) + 2 * kIconPadding;
        return buttonWidth;
    }
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.layer.cornerRadius = 10;
        _iconImageView.layer.masksToBounds = YES;
    }
    return _iconImageView;
}

- (UILabel *)iconTitleLabel {
    if (!_iconTitleLabel) {
        _iconTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        if (@available(iOS 8.2, *)) {
            _iconTitleLabel.font = [UIFont systemFontOfSize:11.f weight:15.f];
        } else {
            _iconTitleLabel.font = [UIFont systemFontOfSize:11.f];
        }
        _iconTitleLabel.textColor = TOCUIColorFromRGBA(0x161823, .75);
        _iconTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _iconTitleLabel;
}

@end

@interface DVEAlbumSlidingTabbarView ()<UIScrollViewDelegate>

@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) NSMutableArray<DVEAlbumSlidingTabButton *> *buttonArray;
@property (nonatomic, strong) NSArray<UIView *> *btnSeperationLineArray;;
@property (nonatomic, assign) DVEAlbumSlidingTabButtonStyle buttonStyle;
@property (nonatomic, strong) DVEAlbumSlidingTabButton *selectedButton;

@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, assign) CGFloat titlePadding;
@property (nonatomic, assign) CGFloat titleMinLength;
@property (nonatomic, assign) CGFloat widthBoundary;

@property (nonatomic, assign) NSInteger arrowIndexForImageStyle;
@property (nonatomic, copy) NSString *arrowSeparatorTitleString;
@property (nonatomic, assign) CGFloat separatorViewWidth;
@property (nonatomic, strong) UIView *arrowSeparator;

@property (nonatomic, strong) UIFont *normalFont;
@property (nonatomic, strong) UIFont *selectedFont;

//与needOptimizeTrackPointForVisibleRect字段配合使用，用于2tab频道show埋点上报优化
@property (nonatomic, assign) CGRect visibleRect;

@end

@implementation DVEAlbumSlidingTabbarView
@synthesize slidingViewController = _slidingViewController;
@synthesize selectedIndex = _selectedIndex;


- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(DVEAlbumSlidingTabButtonStyle)buttonStyle
{
    self = [super initWithFrame:frame];
    if (self) {
        _titlePadding = kTitlePadding;
        _titleMinLength = kTitleMinLength;
        _contentInset = UIEdgeInsetsMake(0, kFixedTabBarPaddingWidth, 0, kFixedTabBarPaddingWidth);
        _widthBoundary = frame.size.width - _contentInset.left - _contentInset.right;
        if (buttonStyle == SCIFSlidingTabButtonStyleTextAndLineEqualLength) {
            _widthBoundary = frame.size.width;
        }
        _selectedIndex = 0;
        _buttonStyle = buttonStyle;
        _arrowIndexForImageStyle = -1;
        [self addSubview:self.scrollView];
        
        _selectedFont = [UIFont systemFontOfSize:kButtonFontSize weight:UIFontWeightMedium];
        _normalFont = [UIFont systemFontOfSize:kButtonFontSize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(DVEAlbumSlidingTabButtonStyle)buttonStyle dataArray:(NSArray<NSString *> *)dataArray selectedDataArray:(NSArray<NSString *> *)selectedDataArray
{
    self = [self initWithFrame:frame buttonStyle:buttonStyle];
    if (self) {
        [self resetDataArray:dataArray selectedDataArray:selectedDataArray];
    }
    return self;
}

- (void)resetDataArray:(NSArray *)dataArray selectedDataArray:(NSArray *)selectedDataArray
{
    self.scrollView.frame = self.bounds;
    self.btnSeperationLineArray = [self seperationLinesWithCount:dataArray.count];
    self.buttonArray = [self buttonsWithDataArray:dataArray selectedDataArray:selectedDataArray];
    [self configureButtonsFrame:self.buttonArray];
    [self setupSubviews];
    self.scrollView.scrollEnabled = self.scrollEnabled;
}

//-----由SMCheckProject工具删除-----
//- (void)insertSeparatorArrowAndTitle:(NSString *)titleString forImageStyleAtIndex:(NSInteger)index
//{
//    if (index < 0 || index >= self.buttonArray.count ) {
//        return;
//    }
//    
//    self.arrowIndexForImageStyle = index;
//    self.arrowSeparatorTitleString = titleString;
//    [self setupSubviews];
//    self.scrollView.scrollEnabled = self.scrollEnabled;
//}

//-----由SMCheckProject工具删除-----
//- (void)replaceButtonImage:(UIImage *)image atIndex:(NSInteger)index
//{
//    [self replaceButtonImgae:image title:@"" atIndex:index];
//}

//-----由SMCheckProject工具删除-----
//- (void)replaceButtonImgae:(UIImage *)image title:(NSString *)titleString atIndex:(NSInteger)index {
//    if (index < 0 || index >= self.buttonArray.count) {
//        return;
//    }
//    
//    self.buttonArray[index].iconImageView.image = image;
//    self.buttonArray[index].iconImageView.layer.borderWidth = 0.5f;
//    self.buttonArray[index].iconImageView.layer.borderColor = TOCResourceColor(TOCUIColorConstSDInverse).CGColor;
//    
//    self.buttonArray[index].iconTitleLabel.text = titleString;
//}

//-----由SMCheckProject工具删除-----
//- (void)insertAtFrontWithButtonImage:(UIImage *)image
//{
//    [self insertAtFrontWithButtonImage:image title:@""];
//}

//-----由SMCheckProject工具删除-----
//- (void)insertAtFrontWithButtonImage:(UIImage *)image title:(NSString *)titleString {
//    if (self.buttonStyle != SCIFSlidingTabButtonStyleImageAndTitle) {
//        return;
//    }
//    
//    DVEAlbumSlidingTabButton *tabButton = [[DVEAlbumSlidingTabButton alloc] init];
//    tabButton.buttonStyle = SCIFSlidingTabButtonStyleImageAndTitle;
//    tabButton.iconImageView.image = image;
//    tabButton.iconImageView.layer.borderWidth = 0.5f;
//    tabButton.iconImageView.layer.borderColor = TOCResourceColor(TOCUIColorConstSDInverse).CGColor;
//    tabButton.iconTitleLabel.text = titleString;
//    
//    if (!TOC_isEmptyArray(self.buttonArray)) {
//        [self.buttonArray insertObject:tabButton atIndex:0];
//    } else {
//        self.buttonArray = [@[tabButton] mutableCopy];
//    }
//    self.btnSeperationLineArray = [self seperationLinesWithCount:self.buttonArray.count];
//    
//    [self configureButtonsFrame:self.buttonArray];
//    [self setupSubviews];
//    self.scrollView.scrollEnabled = self.scrollEnabled;
//}

- (void)configureButtonTextColor:(UIColor *)color selectedTextColor:(UIColor *)selectedColor
{
    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
        [button setTitleColor:color forState:UIControlStateNormal];
        [button setTitleColor:selectedColor forState:UIControlStateSelected];
    }
}

//-----由SMCheckProject工具删除-----
//- (void)configureButtonTextFont:(UIFont *)font selectedFont:(UIFont *)selectedFont
//{
//    if (self.buttonStyle == SCIFSlidingTabButtonStyleIcon) {
//        return;
//    }
//    self.normalFont = font;
//    self.selectedFont = selectedFont;
//    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
//        button.normalFont = font;
//        button.selectedFont = selectedFont;
//        if (button.isSelected) {
//            button.titleLabel.font = selectedFont;
//        } else {
//            button.titleLabel.font = font;
//        }
//    }
//    [self configureButtonsFrame:self.buttonArray];
//
//}

//-----由SMCheckProject工具删除-----
//- (void)configureTitlePadding:(CGFloat)padding
//{
//    if (self.buttonStyle != SCIFSlidingTabButtonStyleOriginText){
//        return;
//    }
//    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
//        button.titlePadding = padding;
//    }
//    CGRect frame = self.lineView.frame;
//    frame.origin.x -= (self.titlePadding - padding);
//    frame.size.width = [self tabButtonWidth] - 2 * padding;
//    self.lineView.frame = frame;
//    self.titlePadding = padding;
//    [self configureButtonsFrame:self.buttonArray];
//}

//-----由SMCheckProject工具删除-----
//- (void)configureTitleMinLength:(CGFloat)titleMinLength
//{
//    if (self.buttonStyle != SCIFSlidingTabButtonStyleOriginText){
//        return;
//    }
//    _titleMinLength = titleMinLength;
//    [self configureButtonsFrame:self.buttonArray];
//}

//-----由SMCheckProject工具删除-----
//- (void)configureButtonTextFont:(UIFont *)font hasShadow:(BOOL)hasShadow
//{
//    if (self.buttonStyle == SCIFSlidingTabButtonStyleIcon) {
//        return;
//    }
//    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
//        button.titleLabel.font = font;
//        if (hasShadow) {
//            button.titleLabel.layer.shadowColor = TOCResourceColor(TOCUIColorConstLinePrimary).CGColor;
//            button.titleLabel.layer.shadowOffset = CGSizeMake(0, 1);
//            button.titleLabel.layer.shadowRadius = 2;
//            button.titleLabel.layer.shadowOpacity = 1.0f;
//        }
//    }
//    [self configureButtonsFrame:self.buttonArray];
//
//}

//-----由SMCheckProject工具删除-----
//- (void)configureText:(NSString *)text image:(nullable UIImage *)image selectedText:(NSString *)selectedText selectedImage:(nullable UIImage *)selectedImage index:(NSInteger)index
//{
//    if (index >= 0 && index < self.buttonArray.count) {
//        DVEAlbumSlidingTabButton *button = self.buttonArray[index];
//        [button configureText:text image:image selectedText:selectedText selectedImage:selectedImage];
//        [self configureButtonsFrame:self.buttonArray];
//    }
//    [self setupSubviews];
//}

- (void)showButtonDot:(BOOL)show index:(NSInteger)index color:(UIColor *)color
{
    if (index >= 0 && index < self.buttonArray.count) {
        DVEAlbumSlidingTabButton *button = self.buttonArray[index];
        [button showDot:show color:color];
    }
}

//-----由SMCheckProject工具删除-----
//- (BOOL)isButtonDotShownOnIndex:(NSInteger)index
//{
//    if (index >= 0 && index < self.buttonArray.count) {
//        DVEAlbumSlidingTabButton *button = self.buttonArray[index];
//        return [button isDotShown];
//    }
//    return NO;
//}

- (NSMutableArray *)buttonsWithDataArray:(NSArray *)dataArray selectedDataArray:(NSArray *)selectedDataArray
{
    if (dataArray.count <= 0) {
        return [@[] mutableCopy];
    }
    
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger i = 0; i < dataArray.count; i++) {
        id data = dataArray[i];
        id selectedData = nil;
        if (i < selectedDataArray.count) {
            selectedData = selectedDataArray[i];
        }
        if (!selectedData) {
            selectedData = data;
        }
        DVEAlbumSlidingTabButton *tabButton = [[DVEAlbumSlidingTabButton alloc] init];
        tabButton.buttonStyle = self.buttonStyle;
        tabButton.selectedFont = self.selectedFont;
        tabButton.normalFont = self.normalFont;
        tabButton.titlePadding = self.titlePadding;
        tabButton.enableSwitchAnimation = self.enableSwitchAnimation;
        tabButton.selected = self.selectedIndex == i;
        if (self.enableSwitchAnimation) {
            [tabButton setTitleColor:TOCResourceColor(TOCColorConstTextInverse4) forState:UIControlStateNormal];
            [tabButton setTitleColor:TOCResourceColor(TOCColorTextPrimary) forState:UIControlStateSelected];
            tabButton.titleLabel.font = self.normalFont;
            tabButton.alpha = tabButton.selected ? 1 : 0.5;
        }
        
        if (self.buttonStyle == SCIFSlidingTabButtonStyleText || self.buttonStyle == SCIFSlidingTabButtonStyleOriginText || self.buttonStyle == SCIFSlidingTabButtonStyleIconAndText || self.buttonStyle == SCIFSlidingTabButtonStyleTextAndLineEqualLength) {
            NSString *nameString = data;
            NSString *selectedNameString = selectedData;
            [tabButton setTitle:nameString forState:UIControlStateNormal];
            [tabButton setTitle:selectedNameString forState:UIControlStateSelected];
        } else if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
            if ([data isKindOfClass:[UIImage class]] && [selectedData isKindOfClass:[UIImage class]]) {
                UIImage *image = data;
                tabButton.iconImageView.image = image;
                
                NSString *titleString = selectedDataArray[i] ? selectedDataArray[i] : @"";
                tabButton.iconTitleLabel.text = titleString;
            }
        } else {
            NSString *nameString = data;
            NSString *selectedNameString = selectedData;
            [tabButton setImage:[UIImage imageNamed:nameString] forState:UIControlStateNormal];
            [tabButton setImage:[UIImage imageNamed:selectedNameString] forState:UIControlStateSelected];
        }
        [buttons addObject:tabButton];
    }
    return [buttons mutableCopy];
}

- (NSArray *)seperationLinesWithCount:(NSInteger)count
{
    NSMutableArray *lineArray = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = TOCResourceColor(TOCUIColorConstLineSecondary);
        [lineArray addObject:line];
    }
    return [lineArray copy];
}

- (void)setupSubviews
{
    for (UIView *subView in self.scrollView.subviews) {
        [subView removeFromSuperview];
    }
    
    __block CGFloat x = self.contentInset.left;
    if (self.buttonStyle == SCIFSlidingTabButtonStyleOriginText) {
        x = 0;
    } else if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
        x = 3;
    }
    [self.buttonArray enumerateObjectsUsingBlock:^(DVEAlbumSlidingTabButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle &&
            self.arrowIndexForImageStyle != -1
            && idx == self.arrowIndexForImageStyle) {
            if (self.arrowSeparator) {
                [self.arrowSeparator removeFromSuperview];
                self.arrowSeparator = nil;
            }
            CGFloat separatorViewWidth = 0;
            if (idx == 0) {
                separatorViewWidth = 51;
            } else {
                separatorViewWidth = 67;
            }
            self.separatorViewWidth = separatorViewWidth;
            self.arrowSeparator = [[UIView alloc] initWithFrame:CGRectMake(x, 0, separatorViewWidth, self.scrollView.frame.size.height)];
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            titleLabel.text = self.arrowSeparatorTitleString;
            if (@available(iOS 8.2, *)) {
                titleLabel.font = [UIFont systemFontOfSize:13.f weight:15.f];
            } else {
                titleLabel.font = [UIFont systemFontOfSize:13.f];
            }
            titleLabel.textColor = TOCUIColorFromRGBA(0xa6a7ab, 1.f);
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.numberOfLines = 0;
            [self.arrowSeparator addSubview:titleLabel];
            
            UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:TOCResourceImage(@"ic_arrow_small")];
            [self.arrowSeparator addSubview:arrowImageView];
            
            [self.scrollView addSubview:self.arrowSeparator];
            
            DVEAlbumMasMaker(titleLabel, {
                make.left.equalTo(self.arrowSeparator).with.offset(idx == 0 ? 13.f : 31.f);
                make.top.equalTo(self.arrowSeparator).with.offset(27.f);
                make.right.equalTo(self.arrowSeparator).with.offset(idx == 0 ? -11.f : -7.f);
                make.height.equalTo(@32.f);
            });
            
            DVEAlbumMasMaker(arrowImageView, {
                make.top.equalTo(titleLabel.mas_bottom).with.offset(6.f);
                make.centerX.equalTo(titleLabel);
                make.height.equalTo(@14.f);
                make.width.equalTo(@14.f);
            });
            x += separatorViewWidth;
        }
        
        button.frame = CGRectMake(x + 0.5, 0, button.buttonWidth - 1, kButtonHeight);
        button.tag = idx + 10001;
        [button addTarget:self action:@selector(tabButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:button];
        CGPoint btnCenter = button.center;
        btnCenter.y = self.scrollView.center.y;
        button.center = btnCenter;
        if (idx > 0) {
            UIView *line = self.btnSeperationLineArray[idx - 1];
            line.frame = CGRectMake(x, (self.scrollView.frame.size.height - 16) * 0.5, 0.5, 16);
            line.hidden = !self.shouldShowButtonSeperationLine;
            [self.scrollView addSubview:line];
        }
        x += button.buttonWidth;
        
        if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
            [button setImageAndTitleStyleButton];
        }
        if (self.selectedIndex == idx) {
            CGPoint scale = [self transformScaleWithButton:button];
            button.transform = CGAffineTransformMakeScale(1 + scale.x, 1 + scale.y);
        } else {
            button.transform = CGAffineTransformIdentity;
        }
    }];
    if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
        x += 3;
        self.scrollView.contentSize = CGSizeMake(x, 0);
    } else {
        self.scrollView.contentSize = CGSizeMake(x + self.contentInset.left, 0);
    }

    if (self.selectedIndex < self.buttonArray.count) {
        DVEAlbumSlidingTabButton *selectButton = self.buttonArray[self.selectedIndex];
        if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
            self.lineView.frame = CGRectMake(selectButton.lineX + selectButton.frame.origin.x, self.bounds.size.height - 4, selectButton.lineWidth, 3);
            self.lineView.layer.cornerRadius = 1.5;
            self.lineView.layer.masksToBounds = YES;
        } else {
            if (self.enableSwitchAnimation) {
                self.lineView.frame = CGRectMake(selectButton.frame.origin.x + (selectButton.frame.size.width - (self.selectionLineSize.width ? : selectButton.lineWidth)) / 2, self.bounds.size.height - 2, self.selectionLineSize.width ?  : selectButton.lineWidth, self.selectionLineSize.height ? : 2);
            } else {
                self.lineView.frame = CGRectMake(selectButton.lineX + selectButton.frame.origin.x, selectButton.frame.origin.y + selectButton.bounds.size.height + 2, selectButton.lineWidth, 2);
            }
        }
    }
    [self.scrollView addSubview:self.lineView];
    CGFloat lineHeight = 1 / [UIScreen mainScreen].scale;
    self.bottomLineView.frame = CGRectMake(0, self.bounds.size.height - lineHeight, self.bounds.size.width, lineHeight);
//    [self addSubview:self.bottomLineView];
    self.topLineView.frame = CGRectMake(0, 0, self.bounds.size.width, lineHeight);
//    [self addSubview:self.topLineView];
}

- (void)tabButtonClicked:(DVEAlbumSlidingTabButton *)sender
{
    NSInteger index = sender.tag - 10001;
    self.slidingViewController.selectedIndex = index;
}

- (void)slidingControllerDidScroll:(UIScrollView *)scrollView
{
    [self updateIrregularTextFrameWhenScroll:scrollView animated:YES];
}

- (CGPoint)transformScaleWithButton:(DVEAlbumSlidingTabButton *)button {
    CGSize normalTitleSize = [[button titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : self.normalFont}];
    CGSize selectedTitleSize = [[button titleForState:UIControlStateSelected] sizeWithAttributes:@{NSFontAttributeName : self.selectedFont}];
    if (normalTitleSize.width == 0 || normalTitleSize.height == 0 || normalTitleSize.width == 0 || normalTitleSize.height == 0) {
        return CGPointZero;
    } else {
        return CGPointMake((selectedTitleSize.width - normalTitleSize.width) / normalTitleSize.width, (selectedTitleSize.height - normalTitleSize.height) / normalTitleSize.height);
    }
}

- (void)updateIrregularTextFrameWhenScroll:(UIScrollView *)scrollView animated:(BOOL)animated
{
    NSInteger selectedIndex = scrollView.contentOffset.x / scrollView.bounds.size.width;   //不用self.selectedIndex，快速滑动时值不准确
    NSAssert(selectedIndex < self.buttonArray.count, @"index beyond bounds");
    if (selectedIndex >= self.buttonArray.count) {
        return;
    }
    DVEAlbumSlidingTabButton *selectButton = self.buttonArray[selectedIndex];
    DVEAlbumSlidingTabButton *nextButton;
    
    CGFloat ratio = (scrollView.contentOffset.x - selectedIndex * scrollView.bounds.size.width) / scrollView.bounds.size.width;
    CGFloat x;
    if (ratio > 0) {
        NSAssert(selectedIndex + 1 < self.buttonArray.count, @"index beyond bounds");
        if (selectedIndex + 1 >= self.buttonArray.count) {
            return;
        }
        nextButton = self.buttonArray[selectedIndex + 1];
        CGFloat diff = (selectButton.buttonWidth + selectButton.lineWidth + nextButton.buttonWidth - nextButton.lineWidth) / 2;
        if (selectedIndex + 1 == self.arrowIndexForImageStyle) {
            diff += self.separatorViewWidth;
        }
        if (self.enableSwitchAnimation) {
            CGPoint scale = [self transformScaleWithButton:selectButton];
            CGPoint nextScale  = [self transformScaleWithButton:nextButton];
            selectButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 + scale.x * (1 - ratio), 1 + scale.y * (1 - ratio));
            nextButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 + nextScale.x * ratio, 1 + nextScale.y * ratio);
            selectButton.alpha = 1 - 0.5 * ratio;
            nextButton.alpha = 0.5 + 0.5 * ratio;
            
            diff = ABS(selectButton.center.x - nextButton.center.x);
            x = selectButton.acc_left + (selectButton.frame.size.width - self.selectionLineSize.width) / 2  + ratio * diff;
            
        } else {
            x = ratio * diff + selectButton.frame.origin.x + selectButton.lineX;
        }
    } else if (ratio < 0) {
        NSAssert(selectedIndex - 1 < self.buttonArray.count && selectedIndex >= 1, @"index beyond bounds");
        if (selectedIndex - 1 >= self.buttonArray.count || selectedIndex < 1) {
            return;
        }
        nextButton = self.buttonArray[selectedIndex - 1];
        CGFloat diff = (nextButton.buttonWidth + nextButton.lineWidth + selectButton.buttonWidth - selectButton.lineWidth) / 2;
        if (selectedIndex - 1 == self.arrowIndexForImageStyle) {
            diff += self.separatorViewWidth;
        }
        x = ratio * diff + selectButton.frame.origin.x + selectButton.lineX;
    } else {
        if (self.enableSwitchAnimation) {
            [UIView animateWithDuration:0.25f animations:^{
                CGPoint scale = [self transformScaleWithButton:selectButton];
                [self.buttonArray enumerateObjectsUsingBlock:^(DVEAlbumSlidingTabButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (idx == selectedIndex) {
                        obj.transform = CGAffineTransformMakeScale(1 + scale.x, 1 + scale.y);
                    } else {
                        obj.transform = CGAffineTransformIdentity;
                    }
                    obj.alpha = idx == selectedIndex ? 1 : 0.5;
                }];
            }];
        }
        if (!CGSizeEqualToSize(self.selectionLineSize, CGSizeZero)) {
            x = (CGRectGetWidth(selectButton.frame) - self.selectionLineSize.width) / 2 + selectButton.frame.origin.x;
        } else {
            x = selectButton.frame.origin.x + selectButton.lineX;
        }
    }
    
    CGFloat width = selectButton.bounds.size.width - kTitlePadding*2;//fabs(ratio) * (nextButton.lineWidth - selectButton.lineWidth) + selectButton.lineWidth;
    CGRect frame = self.lineView.frame;
    frame.origin.x = selectButton.frame.origin.x + kTitlePadding;
    frame.size.width = selectButton.titleLabel.bounds.size.width ?: width;// self.selectionLineSize.width ? : width;
    
    CGPoint center = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
    CGFloat scrollCenter = self.scrollView.contentOffset.x + self.scrollView.frame.size.width / 2;
    CGFloat offset = self.scrollView.contentOffset.x + center.x - scrollCenter;
    CGFloat rightOffset = self.scrollView.contentSize.width - self.scrollView.bounds.size.width;
    
    if (offset < 0) {
        offset = 0;
    } else if (offset > rightOffset && rightOffset >= 0) {
        offset = rightOffset;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            self.lineView.frame = frame;
            if (self.scrollEnabled) {
                [self.scrollView setContentOffset:CGPointMake(offset, 0)];
            }
        }];
    } else {
        self.lineView.frame = frame;
        if (self.scrollEnabled) {
            [self.scrollView setContentOffset:CGPointMake(offset, 0)];
        }
    }
}

- (void)updateSelectedLineFrame
{
    [self updateIrregularTextFrameWhenScroll:self.slidingViewController.contentScrollView animated:NO];
}

- (void)configureButtonsFrame:(NSArray<DVEAlbumSlidingTabButton *> *)buttons
{
    if (buttons.count <= 0) {
        return;
    }
    
    if (self.buttonStyle == SCIFSlidingTabButtonStyleImageAndTitle) {
        for (DVEAlbumSlidingTabButton *button in buttons) {
            button.buttonWidth = 68;
            button.lineWidth = 24;
            button.lineX = (button.buttonWidth - button.lineWidth) / 2;
        }
    } else if (self.buttonStyle == SCIFSlidingTabButtonStyleTextAndLineEqualLength) {
        CGFloat widthTotal = 0;
        CGFloat widthMax = 0;
        for (NSInteger i = 0; i < buttons.count; i++) {
            DVEAlbumSlidingTabButton *button = buttons[i];
            CGSize normalTitleSize = [[button titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : button.normalFont}];
            CGSize selectedTitleSize = [[button titleForState:UIControlStateSelected] sizeWithAttributes:@{NSFontAttributeName : button.selectedFont}];
            CGFloat biggerWidth = selectedTitleSize.width > normalTitleSize.width ? selectedTitleSize.width : normalTitleSize.width;
            button.lineWidth = biggerWidth > self.titleMinLength ? biggerWidth : self.titleMinLength;
            button.buttonWidth = button.lineWidth;
            button.lineX = (button.buttonWidth - button.lineWidth) / 2;
            widthTotal += button.buttonWidth;
            if (button.buttonWidth > widthMax) {
                widthMax = button.buttonWidth;
            }
        }
        CGFloat x = 0;
        CGFloat offset = self.shouldShowButtonSeperationLine ? 0.5 : 0;
        for (DVEAlbumSlidingTabButton *button in buttons) {
            button.buttonWidth = [button buttonOriginWidth];
            button.lineX = (button.buttonWidth - (self.selectionLineSize.width ? : button.lineWidth)) / 2;
            button.frame = CGRectMake(x + offset, 0, button.buttonWidth - offset * 2, self.bounds.size.height);
            x += button.buttonWidth;
        }
    } else if (self.buttonStyle == SCIFSlidingTabButtonStyleOriginText) {
        CGFloat widthTotal = 0;
        CGFloat widthMax = 0;
        for (NSInteger i = 0; i < buttons.count; i++) {
            DVEAlbumSlidingTabButton *button = buttons[i];
            CGSize normalTitleSize = [[button titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : button.normalFont}];
            CGSize selectedTitleSize = [[button titleForState:UIControlStateSelected] sizeWithAttributes:@{NSFontAttributeName : button.selectedFont}];
            CGFloat biggerWidth = selectedTitleSize.width > normalTitleSize.width ? selectedTitleSize.width : normalTitleSize.width;
            button.lineWidth = biggerWidth > self.titleMinLength ? biggerWidth : self.titleMinLength;
            button.buttonWidth = button.lineWidth + 2 * self.titlePadding;
            button.lineX = (button.buttonWidth - button.lineWidth) / 2;
            widthTotal += button.buttonWidth;
            if (button.buttonWidth > widthMax) {
                widthMax = button.buttonWidth;
            }
        }
        CGFloat x = 0;
        CGFloat offset = self.shouldShowButtonSeperationLine ? 0.5 : 0;
        if (widthMax * buttons.count <= self.bounds.size.width) {
            for (DVEAlbumSlidingTabButton *button in buttons) {
                button.buttonWidth = self.bounds.size.width / buttons.count;
                button.lineX = (button.buttonWidth - button.lineWidth) / 2;
                button.frame = CGRectMake(x + offset, 0, button.buttonWidth - offset * 2, self.bounds.size.height);
                x += CGRectGetMaxX(button.frame);
            }
        } else if (widthTotal < self.bounds.size.width) {
            CGFloat extraSpace = (self.bounds.size.width - widthTotal) / buttons.count;
            for (DVEAlbumSlidingTabButton *button in buttons) {
                button.buttonWidth += extraSpace;
                button.lineX = (button.buttonWidth - button.lineWidth) / 2;
                button.frame = CGRectMake(x + offset, 0, button.buttonWidth - offset * 2, self.bounds.size.height);
                x += CGRectGetMaxX(button.frame);
            }
        }
    } else if (self.scrollEnabled) {
        for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
            button.lineWidth = [button buttonOriginWidth];
            button.buttonWidth = button.lineWidth;
            button.lineX = 0;
        }
    } else if ([self getMaxButtonWidth] * self.buttonArray.count < self.widthBoundary) {
        CGFloat x = 0;
        CGFloat offset = self.shouldShowButtonSeperationLine ? 0.5 : 0;
        for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
            button.lineWidth = self.widthBoundary/self.buttonArray.count;
            button.buttonWidth = button.lineWidth;
            button.lineX = 0;
            button.frame = CGRectMake(x + offset, 0, button.buttonWidth - offset * 2, self.bounds.size.height);
            x += CGRectGetMaxX(button.frame);
        }
    } else {
        CGFloat x = 0;
        CGFloat offset = self.shouldShowButtonSeperationLine ? 0.5 : 0;
        CGFloat vacantSpace = (self.widthBoundary - [self totalButtonWidth])/self.buttonArray.count;
        for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
            button.lineWidth = [button buttonOriginWidth] + vacantSpace;
            button.buttonWidth = button.lineWidth;
            button.lineX = 0;
            button.frame = CGRectMake(x + offset, 0, button.buttonWidth - offset * 2, self.bounds.size.height);
            x += CGRectGetMaxX(button.frame);
        }
    }
}

- (CGFloat)getMaxButtonWidth {
    CGFloat bottonMaxWidth = kButtonMinLength;
    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
        CGFloat buttonWidth = [button buttonOriginWidth];
        bottonMaxWidth = bottonMaxWidth > buttonWidth ? bottonMaxWidth : buttonWidth;
    }
    return bottonMaxWidth;
}

- (CGFloat)totalButtonWidth {
    CGFloat totalButtonWidth = 0;
    for (DVEAlbumSlidingTabButton *button in self.buttonArray) {
        totalButtonWidth += [button buttonOriginWidth];
    }
    if (self.arrowSeparator) {
        totalButtonWidth += 67;
    }
    return totalButtonWidth;
}

#pragma mark - Getters

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = TOCResourceColor(TOCUIColorPrimary2);
    }
    return _lineView;
}

- (UIView *)topLineView
{
    if (!_topLineView) {
        _topLineView = [[UIView alloc] init];
        _topLineView.hidden = NO;
        _topLineView.backgroundColor = TOCResourceColor(TOCUIColorLineSecondary2);
    }
    return _topLineView;
}

- (UIView *)bottomLineView
{
    if (!_bottomLineView) {
        _bottomLineView = [[UIView alloc] init];
        _bottomLineView.backgroundColor = TOCResourceColor(TOCColorPrimary);
    }
    return _bottomLineView;
}

- (CGFloat)tabButtonWidth
{
    NSInteger count = self.buttonArray.count;
    if (count == 0) {
        return 0.f;
    }
    CGFloat width = self.bounds.size.width / count;
    if (self.scrollEnabled) {  // 允许滚动，button宽度限制
        CGFloat maxWidth = (self.buttonStyle == SCIFSlidingTabButtonStyleIcon ? 80 : 94);
        return (width < maxWidth ? maxWidth : width);
    } else {
        return width;
    }
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.scrollEnabled = self.scrollEnabled;
        _scrollView.delegate = self;
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        _scrollView.scrollsToTop = NO;
    }
    return _scrollView;
}

- (BOOL)scrollEnabled {
    if (self.buttonStyle == SCIFSlidingTabButtonStyleOriginText){
        return NO;
    }
    return [self totalButtonWidth] >= self.widthBoundary;
}

# pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (fabs(velocity.x) <= 0.00001f) {
        [self scrollViewContentOffsetDidEndChanging];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewContentOffsetDidEndChanging];
}

- (void)scrollViewContentOffsetDidEndChanging
{
    CGRect scrollViewVisibleRect = CGRectMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    //needOptimizeTrackPointForVisibleRect设置为YES时，如果在操作结束的时刻，屏幕内的可视区域未发生变化，则不执行didEndDeceleratingBlock
    if (self.needOptimizeTrackPointForVisibleRect && [self isRect:self.visibleRect equalToRect:scrollViewVisibleRect]) {
        return;
    }
    __block NSInteger start = NSNotFound;
    __block NSInteger count = 0;
    [self.buttonArray enumerateObjectsUsingBlock:^(DVEAlbumSlidingTabButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectIntersectsRect(button.frame, scrollViewVisibleRect)) {
            if (start == NSNotFound) {
                start = idx;
            }
            count++;
        } else {
            if (start != NSNotFound) {
                *stop = YES;
            }
        }
    }];
    self.visibleRect = scrollViewVisibleRect;
    TOCBLOCK_INVOKE(self.didEndDeceleratingBlock, start, count);
}

- (BOOL)isRect:(CGRect)rect1 equalToRect:(CGRect)rect2
{
    return rect1.origin.x == rect2.origin.x &&
           rect1.origin.y == rect2.origin.y &&
           rect1.size.width == rect2.size.width &&
           rect1.size.height == rect2.size.height;
}

#pragma mark - Setters

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (!self.buttonArray || self.buttonArray.count == 0) {
        return;
    }
    
    if (selectedIndex < 0 || selectedIndex >= self.buttonArray.count) {
        return;
    }
    
    [self.buttonArray enumerateObjectsUsingBlock:^(DVEAlbumSlidingTabButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.selectedIndex != selectedIndex){
             [button setSelected:(idx == selectedIndex)];
        }
    }];
    
    _selectedIndex = selectedIndex;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollViewContentOffsetDidEndChanging];
    });
    if (self.shouldUpdateSelectButtonLine) {
        [self updateSelectedLineFrame];
    }
}

- (void)setShouldShowTopLine:(BOOL)shouldShowTopLine
{
    _shouldShowTopLine = shouldShowTopLine;
    self.topLineView.hidden = !shouldShowTopLine;
}

- (void)setShouldShowBottomLine:(BOOL)shouldShowBottomLine
{
    _shouldShowBottomLine = shouldShowBottomLine;
    self.bottomLineView.hidden = !shouldShowBottomLine;
}

- (void)setShouldShowSelectionLine:(BOOL)shouldShowSelectionLine
{
    _shouldShowSelectionLine = shouldShowSelectionLine;
    self.lineView.hidden = !shouldShowSelectionLine;
}

- (void)setSelectionLineColor:(UIColor *)selectionLineColor
{
    self.lineView.backgroundColor = selectionLineColor;
}

//-----由SMCheckProject工具删除-----
//- (void)setTopBottomLineColor:(UIColor *)topBottomLineColor
//{
//    self.topLineView.backgroundColor = topBottomLineColor;
//    self.bottomLineView.backgroundColor = topBottomLineColor;
//}

//-----由SMCheckProject工具删除-----
//- (void)setTopLineColor:(UIColor *)color
//{
//    self.topLineView.backgroundColor = color;
//}

//-----由SMCheckProject工具删除-----
//- (void)setBottomLineColor:(UIColor *)color
//{
//    self.bottomLineView.backgroundColor = color;
//}

- (void)setShouldShowButtonSeperationLine:(BOOL)shouldShowButtonSeperationLine
{
    _shouldShowButtonSeperationLine = shouldShowButtonSeperationLine;
    for (UIView *line in self.btnSeperationLineArray) {
        line.hidden = !shouldShowButtonSeperationLine;
    }
}

- (void)setSelectionLineCornerRadius:(CGFloat)selectionLineCornerRadius {
    if (_selectionLineCornerRadius != selectionLineCornerRadius) {
        _selectionLineCornerRadius = selectionLineCornerRadius;
        self.lineView.layer.masksToBounds = selectionLineCornerRadius != 0;
        if (self.lineView.layer.masksToBounds) {
            self.lineView.layer.cornerRadius = selectionLineCornerRadius;
        }
    }
}

@end














