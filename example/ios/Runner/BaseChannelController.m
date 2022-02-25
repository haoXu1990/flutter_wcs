//
//  BaseChannelController.m
//  Runner
//
//  Created by XuHao on 2022/2/25.
//

#import "BaseChannelController.h"


@interface BaseChannelController () <IESEditorLoggerDelegate,NLELoggerDelegate>

@property (nonatomic, strong) FlutterBasicMessageChannel *channel;

@end

static NSMutableDictionary *modelNameDic;


@implementation BaseChannelController

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFuncion:) name:@"ios.to.flutter" object:nil];
        self.channel = [[FlutterBasicMessageChannel alloc] initWithName:@"com.wcs.fire.BaseMessageChannel" binaryMessenger:messenger codec:nil];
//        self.channel = [FlutterMethodChannel methodChannelWithName:@"com.wcs.fire.BaseMessageChannel" binaryMessenger:messenger];

        __weak __typeof(self)weakSelf = self;

        [self.channel setMessageHandler:^(id  _Nullable message, FlutterReply  _Nonnull callback) {
            NSLog(@"%@", message);
        }];

//        [self.channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
//            if ([call.method isEqual:@"initSDK"]) {
//
//                [weakSelf initSDK];
//
//                [[VERootVCManger shareManager] swichRootVC];
//            }
//        }];
    }
    return self;
}

- (void)notificationFuncion: (NSNotification *) notification {
    // iOS 中其他页面向Flutter 中发送消息通过这里
    // 本页中 可以直接使用   [messageChannel sendMessage:dic];
    //处理消息
    NSLog(@"ios.to.flutter mesge: %@ ", notification.object);
//    [self.channel sendMessage:<#(id _Nullable)#>];
//    [self.channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
//
//    }];

}


- (void)initSDK {
    NSString *path = [@"labcv_test_20211027_20220427_com.bytedance.solution.ck_4.0.4.0.licbag" pathInBundle:@"licBundle"];
    NSString *testLocalPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.licbag"];

    NSFileManager *fileManager =  [NSFileManager defaultManager];
    //判断文件是否存在
    BOOL isExist = [fileManager fileExistsAtPath:testLocalPath];
    if (isExist) {
        path = testLocalPath;
    }

    if (VELicenseRegister(path)) {

    } else {
        [DVENotification showTitle:nil message:@"VE授权不正确，请检查"];
    }

    //设置鉴权回调，获取异常日志
    VESetLicenseCheckerCallback(licenseCheckerCallback);

    if (@available(iOS 14.2, *)) {
        [[VEConfigCenter sharedInstance] configVESDKABValue:@1 key:@"veabtest_VTEncodeMode" type:VEABKeyDataType_Int];
    }

    // 开启 composer 功能和 OpenGL ES 3.0
    [IESMMParamModule sharedInstance].composerMode  = 1;
    [IESMMParamModule sharedInstance].composerOrder = 0;
    [IESMMParamModule sharedInstance].infoStickerCanUseAmazing = YES;
    [IESMMParamModule sharedInstance].editorCanUseAmazing = YES;
    IESMMParamModule.sharedInstance.useNewAudioEditor = YES;
    IESMMParamModule.sharedInstance.useNewAudioAPI = YES;
    IESMMParamModule.sharedInstance.recordCanUseAmazing = YES;
    [self setResourceFinder];
    [VEPreloadModule prepareVEContext];


    [IESMMParamModule sharedInstance].capturePreviewUpTo1080P = YES;

    [[IESMMLogger sharedInstance] setLoggerDelegate:self];

    [[IESMMTrackerManager shareInstance] setAppLogCallback:@"" callback:^(NSString * _Nonnull event, NSDictionary * _Nonnull params, NSString * _Nonnull eventType) {

    }];

}

- (void)setResourceFinder
{
    [IESMMParamModule setResourceFinder:resource_finder];
}

char *resource_finder(__unused void *handle, __unused const char *dir, const char *name){
    //模型文件夹路径
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ModelResource" ofType:@"bundle"];
    path = [path stringByAppendingPathComponent:[NSString stringWithUTF8String:name]];


#if DEBUG
    if (!modelNameDic) {
        modelNameDic = [NSMutableDictionary new];
    }

    NSString *modelName = [NSString stringWithUTF8String:name];
    if ([modelNameDic valueForKey:modelName]) {

        [modelNameDic setValue:@([[modelNameDic valueForKey:modelName] integerValue] + 1) forKey:modelName];
    } else {
        [modelNameDic setValue:@(1) forKey:modelName];
    }

    NSLog(@"modelNameDic:%@",modelNameDic.UI_VEtoJsonString);
#endif

    path              = [@"file://" stringByAppendingString:path];
    char *result_path = malloc(strlen(path.UTF8String) + 1);
    strcpy(result_path, path.UTF8String ?: "");
    result_path[strlen(path.UTF8String)] = '\0';
    return result_path;
}


//鉴权回调，获取异常日志，不一定在主线程
void licenseCheckerCallback(NSString *message, int code) {
    NSLog(@"licenseCheckerCallback：%@", message);
    NSString *showMSG = @"鉴权不通过，请联系技术支持";
    switch (code) {
        case -1://LICBAG_API_FAIL
            showMSG = @"其他错误";
            break;
        case -2://LICBAG_API_NO_DEVICE_ID
            showMSG = @"LICBAG_API_NO_DEVICE_ID";
            break;
        case -122://LICBAG_API_TYPE_NOT_MATCH
            showMSG = @"授权包类型不匹配";
            break;
        case -123://LICBAG_API_INVALID_VERSION
            showMSG = @"无效的版本";
            break;
        case -124://LICBAG_API_INVALID_BLOCK_COUNT
            showMSG = @"无效的数据块";
            break;
        case -127://LICBAG_API_LICENSE_NO_FUNC
            showMSG = @"请求功能不匹配";
            break;
        case -401://LICBAG_API_FILE_ERROR
            showMSG = @"文件没找到或损坏";
            break;
        case -501://LICBAG_API_LICENSE_STATUS_INVALID
            showMSG = @"非法授权文件";
            break;
        case -502://LICBAG_API_LICENSE_STATUS_EXPIRED
            showMSG = @"授权文件过期";
            break;
        case -503://LICBAG_API_LICENSE_STATUS_NO_MATCH
            showMSG = @"授权包类型不匹配";
            break;
        case -504://LICBAG_API_LICENSE_STATUS_ID_NOT_MATCH
            showMSG = @"BundleID不匹配";
            break;
        case -601://LICBAG_API_LICENSE_INVALID_HANDLE
            showMSG = @"LICBAG_API_LICENSE_INVALID_HANDLE";
            break;
        case -1001://LicenseCheckNotRegisterError
            showMSG = @"未成功授权";
            break;
        case -1002://LicenseCheckParmError
            showMSG = @"参数错误";
            break;


        default:
            break;
    }

    showMSG = [showMSG stringByAppendingString:[NSString stringWithFormat:@"，错误码：%d",code]];
    dispatch_async(dispatch_get_main_queue(), ^{

        // 显示 msg
    });

}


- (void)IESEditorlogToLocal:(NSString *)logString andLevel:(IESMMlogLevel)level {
    NSLog(@"%@",logString);
}

- (void)logger:(nonnull NLELogger *)logger log:(NSString * _Nullable)tag level:(NLELogLevel)level file:(nonnull NSString *)file function:(nonnull NSString *)function line:(int)line message:(nonnull NSString *)message {


}

@end
