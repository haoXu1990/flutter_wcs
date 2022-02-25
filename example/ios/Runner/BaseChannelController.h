//
//  BaseChannelController.h
//  Runner
//
//  Created by XuHao on 2022/2/25.
//

#import <Foundation/Foundation.h>
#import "Runner-Bridging-Header.h"
NS_ASSUME_NONNULL_BEGIN

@interface BaseChannelController : NSObject
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

NS_ASSUME_NONNULL_END
