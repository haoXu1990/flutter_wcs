//
//  VEEStickerViewController.m
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "VEEStickerViewController.h"
#import "VEEStickerItem.h"


#define kVEEStickerItemIdentifier @"kVEEStickerItemIdentifier"

static const NSString *StickerBundleName = @"StickerResource";

@interface VEEStickerViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collecView;
@property (nonatomic, strong) NSArray *dataSourceArr;
@property (nonatomic, strong) DVEEffectValue *curValue;
@property (nonatomic, strong) DVEEffectValue *lastValue;

@end

@implementation VEEStickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.collecView];
    [self initDataSource];
}

- (void)initDataSource
{
    
    NSArray *stickerArr = @[@"shuihaimeigeqiutian",@"kongquegongzhu",@"zhaocaimao",@"biaobaiqixi",@"xiatiandefeng",@"zisemeihuo",@"qianduoduo",@"shenshi",@"meihaoxinqing",@"shangke",@"kidmakup",@"shuiliandong",@"konglongceshi",@"kejiganqueaixiong",@"mofabaoshi",@"jiamian",@"gongzhumianju",@"konglongshiguangji",@"huanlongshu",@"huanletuchiluobo",@"eldermakup",@"tiaowuhuoji",@"yanlidoushini",@"xiaribingshuang",@"maobing",@"haoqilongbao",@"nuannuandoupeng",@"huahua",@"jiancedanshenyinyuan",@"zhutouzhuer",@"zhuluojimaoxian",@"wochaotian",@"chitushaonv",@"landiaoxueying",@"lizishengdan",@"katongnan",@"dianjita",@"weilandongrizhuang",@"cinamiheti",@"heimaoyanjing",@"shengrikuaile",@"baibianfaxing",@"mengguiyaotang",@"katongnv"];
    NSMutableArray *valueArr = [NSMutableArray new];
    for (NSInteger i = 0; i < stickerArr.count; i ++) {
        DVEEffectValue *value = [DVEEffectValue new];
        value.name = stickerArr[i];
        value.indesty = 1;
        value.assetImage = [NSString stringWithFormat:@"icon_%@",stickerArr[i]].UI_VEToImage;
        value.sourcePath = [[@"stickers/" stringByAppendingString:stickerArr[i]] pathInBundle:StickerBundleName];
        [valueArr addObject:value];
    }
    
    self.dataSourceArr = valueArr.copy;
    [self.collecView reloadData];
}


- (UICollectionView *)collecView
{
    if (!_collecView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
        _collecView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 156) collectionViewLayout:flowLayout];
        _collecView.showsHorizontalScrollIndicator = NO;
        _collecView.showsVerticalScrollIndicator = NO;
        _collecView.delegate = self;
        _collecView.dataSource = self;
        _collecView.backgroundColor = [UIColor blackColor];
        _collecView.allowsMultipleSelection = NO;
        
        [_collecView registerClass:[VEEStickerItem class] forCellWithReuseIdentifier:kVEEStickerItemIdentifier];
    }
    
    return _collecView;
}



#pragma mark -- UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSourceArr.count;
    
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VEEStickerItem *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kVEEStickerItemIdentifier forIndexPath:indexPath];
    
    id obj = self.dataSourceArr[indexPath.section];
    
    DVEEffectValue *value = nil;
    if ([obj isKindOfClass:[NSArray class]]) {
        value = self.dataSourceArr[indexPath.section][indexPath.row];
    } else {
        value = self.dataSourceArr[indexPath.row];
    }
    cell.eValue = value;
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSourceArr.count > 0 ? 1 : 0;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    
    return nil;
}


#pragma mark -- UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(37, 37);
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(12, 12, 12,12);
   
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 25;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 25;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(0, 0);
}

#pragma mark -- UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = self.dataSourceArr[indexPath.section];
    
    DVEEffectValue *value = nil;
    if ([obj isKindOfClass:[NSArray class]]) {
        value = self.dataSourceArr[indexPath.section][indexPath.row];
    } else {
        value = self.dataSourceArr[indexPath.row];
    }
    
    if (self.lastValue && ![self.lastValue isEqual:value]) {
        self.lastValue.valueState = VEEffectValueStateNone;
    }
    
    if (value.valueState == VEEffectValueStateInUse) {
        value.valueState = VEEffectValueStateNone;
    } else {
        value.valueState = VEEffectValueStateInUse;
    }
    
    self.curValue = value;
    
    if (self.didSelectedBlock) {
        self.didSelectedBlock(value);
    }
    
    self.lastValue = value;
}

- (void)reset
{
    [self.collecView reloadData];
}


@end
