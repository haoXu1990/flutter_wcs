//
//  DVETextSliderView.m
//  NLEEditor
//
//  Created by bytedance on 2021/6/22.
//

#import "DVETextSliderView.h"
#import "DVEMacros.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "NSString+VEToImage.h"

@implementation DVETextSliderView

static const int8_t kRightPadding = 40;
static const int kSliderWidth = 257;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self addSubview:self.textLabel];
        _textLabel.centerY = self.slider.centerY;
        
        self.slider.width = kSliderWidth;
        self.slider.right = self.right - kRightPadding;
        self.slider.imageCursor = @"btn_slidebar_gray".dve_toImage;
    }
    return self;
}

#pragma mark - Getter and Setter

- (UILabel *)textLabel {
    if (!_textLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 60, 20)];
        label.font = SCRegularFont(14);
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        _textLabel = label;
    }
    return _textLabel;
}
#pragma mark - Private


@end
