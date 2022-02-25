//
//  DVEAnimationBar.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVEBaseBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEAnimationBar : DVEBaseBar

@property (nonatomic, assign) VEVCModuleCutSubTypeAnimationType type;

- (void)showInView:(UIView *)view withType:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
