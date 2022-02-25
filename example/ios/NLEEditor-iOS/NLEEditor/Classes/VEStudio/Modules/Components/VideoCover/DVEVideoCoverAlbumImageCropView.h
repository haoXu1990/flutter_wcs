//
//  DVEVideoCoverAlbumImageCropView.h
//  NLEEditor
//
//  Created by bytedance on 2021/6/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEVideoCoverAlbumImageCropDelegate <NSObject>

- (void)presentCropAlbumImageForVideoCover:(UIImage * _Nullable)cropImage;

- (void)backImageResourcePickerView;

@end

@interface DVEVideoCoverAlbumImageCropView : UIView

@property (nonatomic, assign) float cropRatio;

- (instancetype)initWithImage:(UIImage *)image
                     delegate:(id<DVEVideoCoverAlbumImageCropDelegate>)delegate;

@end

FOUNDATION_EXTERN CGSize DVE_aspectFitSize(CGSize size, CGSize maxSize);
FOUNDATION_EXTERN CGRect DVE_fixCropRectForImage(CGRect rect, UIImage *image);

NS_ASSUME_NONNULL_END
