
//
//  LQGWaterFlowLayout.m
//  LQGWaterLayout
//
//  Created by quangang on 2017/4/18.
//  Copyright © 2017年 LQG. All rights reserved.
//

#import "LQGWaterFlowLayout.h"

//每组的数据变更状态标识
typedef NS_ENUM(NSInteger, SectionStatus){
    allUpdate,      //全部重新计算或者从头开始计算
    littleUpdate,   //计算新增item和footer
    withOutUpdate   //不需要计算
};

@interface SectionModel : NSObject
@property (nonatomic, assign) SectionStatus sectionStatus;          //该组的数据变更状态
@property (nonatomic, assign) NSUInteger lastNum;                   //该组的item的个数
@property (nonatomic, strong) NSMutableArray *sectionAttriMuArray;  //该组对应的所有布局属性
@property (nonatomic, strong) NSMutableArray *maxYMuArray;          //该组最下面一行的最大Y值
@end

@implementation SectionModel

- (NSMutableArray *)sectionAttriMuArray{
    if (!_sectionAttriMuArray) {
        _sectionAttriMuArray = [NSMutableArray new];
    }
    return _sectionAttriMuArray;
}

- (NSMutableArray *)maxYMuArray{
    if (!_maxYMuArray) {
        _maxYMuArray = [NSMutableArray new];
    }
    return _maxYMuArray;
}

@end

@interface LQGWaterFlowLayout()

@property (nonatomic, strong) NSMutableArray *maxColumnYMuArray;            /** 存储每列的最大y值*/
@property (nonatomic, strong) NSMutableArray *attrsMuArray;                 /** 存储布局属性*/
@property (nonatomic, assign) NSInteger columnsCount;                       /** 列数*/
@property (nonatomic, assign) CGFloat rowMargin;                            /** 行距*/
@property (nonatomic, assign) CGFloat columnMargin;                         /** 列距*/
@property (nonatomic, assign) UIEdgeInsets sectionEdgeInset;                /** 每组的间距*/
@property (nonatomic, strong) NSNumber *itemWidth;                          /** item的宽度*/
@property (nonatomic, strong) NSMutableArray *sectionInfoMuArray;           /** 存储每个组上次的信息*/


@property (nonatomic, copy) CGFloat(^itemHeightBlock)(NSIndexPath *itemIndex);          /** 获得item高度（必须实现）*/
@property (nonatomic, copy) CGSize(^headerSizeBlock)(NSIndexPath *headerIndex);         /** 获得头视图高度（必须实现）*/
@property (nonatomic, copy) CGSize(^footerSizeBlock)(NSIndexPath *footerIndex);         /** 获得尾视图高度（必须实现）*/

@end

@implementation LQGWaterFlowLayout

#pragma mark - init方法

- (instancetype)initWithColumnsCount:(NSUInteger)columnsCount
                           rowMargin:(CGFloat)rowMargin
                       columnsMargin:(CGFloat)columnMargin
                    sectionEdgeInset:(UIEdgeInsets)sectionEdgeInset
                         getItemSize:(CGFloat(^)(NSIndexPath *itemIndex))itemHeightBlock
                       getHeaderSize:(CGSize(^)(NSIndexPath *headerIndex))headerSizeBlock
                       getFooterSize:(CGSize(^)(NSIndexPath *footerIndex))footerSizeBlock
{
    
    if (self = [super init]) {
        
        //赋值
        self.itemHeightBlock = itemHeightBlock;
        self.headerSizeBlock = headerSizeBlock;
        self.footerSizeBlock = footerSizeBlock;
        
        //容错并赋值
        self.columnMargin = ((columnMargin < 0) ? 0 : columnMargin);
        self.rowMargin = ((rowMargin < 0) ? 0 : rowMargin);
        self.columnsCount = ((columnsCount == 0) ? 1 : columnsCount);
        self.sectionEdgeInset = UIEdgeInsetsMake(((sectionEdgeInset.top < 0) ? 0 : sectionEdgeInset.top),
                                                 ((sectionEdgeInset.left < 0) ? 0 : sectionEdgeInset.left),
                                                 ((sectionEdgeInset.bottom < 0) ? 0 : sectionEdgeInset.bottom),
                                                 ((sectionEdgeInset.right < 0) ? 0 : sectionEdgeInset.right));
    }
    return self;
}

#pragma mark - 重写父类函数

/**
 *  当边界发生改变(一般是scroll到其他地方)时，是否应该刷新布局
 */
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return NO;
}

/**
 *  返回布局属性
 */
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return self.attrsMuArray;
}

/**
 *  返回collectionview的contentsize
 */
- (CGSize)collectionViewContentSize{
    return CGSizeMake(0, [self getMaxY] + self.rowMargin + self.sectionEdgeInset.bottom);
}

/**
 *  获取所有的布局属性
 */
- (void)prepareLayout{
    [super prepareLayout];
    
    [self updateSectionAttri];
    
    //如果是第一次布局计算，所有都进行计算
    //如果是第二次和之后的布局计算， 只计算新增的item和最后一个footer
    //添加每个item的布局到布局数组中
    for (NSInteger i = 0; i < self.collectionView.numberOfSections; i++) {
        SectionModel *tempModel = self.sectionInfoMuArray[i];
        
        //如果该组不需要更新，需要更新最大Y值数组为该组的footer的Y值
        if (tempModel.sectionStatus == withOutUpdate) {
            UICollectionViewLayoutAttributes *footerAttri = tempModel.sectionAttriMuArray.lastObject;
            [self updateMaxY:CGRectGetMaxY(footerAttri.frame)];
            continue;
        }
        
        //如果该组只需要部分更新，需要移除footer，并设置最大Y值数组
        if (tempModel.sectionStatus == littleUpdate) {
            [tempModel.sectionAttriMuArray removeLastObject];
            [self setMaxY:i];
        }
        
        //如果该组需要全部更新，需要计算header
        if (tempModel.sectionStatus == allUpdate) {
            [tempModel.sectionAttriMuArray removeAllObjects];
            
            //添加header的布局属性
            UICollectionViewLayoutAttributes *headerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                 atIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
            [tempModel.sectionAttriMuArray addObject:headerAttri];
        }
        
        //添加当前组的新增的item的布局属性
        for (NSInteger j = ((tempModel.sectionStatus == littleUpdate) ? tempModel.lastNum : 0);
             j < [self.collectionView numberOfItemsInSection:i];
             j++) {
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            UICollectionViewLayoutAttributes *itemAttri = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
            [tempModel.sectionAttriMuArray addObject:itemAttri];
        }
        
        //添加footer的布局属性
        UICollectionViewLayoutAttributes *footerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                             atIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
        [tempModel.sectionAttriMuArray addObject:footerAttri];
        
        //更新该组的item个数
        tempModel.lastNum = [self.collectionView numberOfItemsInSection:i];
    }
    
    //合并布局属性
    [self mergeWholeArr];
}

/**
 *  返回每一个item的布局属性
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    __block UICollectionViewLayoutAttributes *attri = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    
    [self getMinColumnInfo:^(NSInteger minColumn, CGFloat minY) {
        CGFloat itemHeight = weakSelf.itemHeightBlock(indexPath);
        CGFloat itemX = weakSelf.sectionEdgeInset.left + minColumn * (weakSelf.columnMargin + [weakSelf.itemWidth floatValue]);
        CGFloat itemY = minY + weakSelf.rowMargin;
        attri.frame = CGRectMake(itemX, itemY, [weakSelf.itemWidth floatValue], itemHeight);
        weakSelf.maxColumnYMuArray[minColumn] = @(CGRectGetMaxY(attri.frame));
    }];
    
    return attri;
}

/**
 *  返回头尾视图布局对象
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind
                                                                     atIndexPath:(NSIndexPath *)indexPath{
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self attributesForHeaderAtIndexPath:indexPath];
    }else{
        return [self attributesForFooterAtIndexPath:indexPath];
    }
}

/**
 *  获得头视图的布局属性
 */
- (UICollectionViewLayoutAttributes *)attributesForHeaderAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *headerAttri = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                                   withIndexPath:indexPath];
    CGSize headerSize = self.headerSizeBlock(indexPath);
    headerAttri.frame = CGRectMake(0, [self getMaxY] + self.sectionEdgeInset.top, headerSize.width, headerSize.height);
    [self updateMaxY:CGRectGetMaxY(headerAttri.frame)];
    return headerAttri;
}

/**
 *  获得尾部视图的布局属性
 */
- (UICollectionViewLayoutAttributes *)attributesForFooterAtIndexPath:(NSIndexPath *)indexPath{
    [self setSectionMaxY:indexPath.section];
    UICollectionViewLayoutAttributes *footerAttri = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPath];
    CGSize footerSize = self.footerSizeBlock(indexPath);
    footerAttri.frame = CGRectMake(0, [self getMaxY] + self.sectionEdgeInset.bottom, footerSize.width, footerSize.height);
    [self updateMaxY:CGRectGetMaxY(footerAttri.frame)];
    return footerAttri;
}

#pragma mark - privateMethod

/**
 *  判断每组的状态
 */
- (void)updateSectionAttri{
    
    for (int i = 0; i < self.collectionView.numberOfSections; i++) {
        
        if (self.sectionInfoMuArray.count < self.collectionView.numberOfSections) {
            [self.sectionInfoMuArray addObject:[SectionModel new]];
        }
        
        SectionModel *tempModel = self.sectionInfoMuArray[i];
        SectionModel *tempModel1 = i > 0 ? self.sectionInfoMuArray[i - 1] : nil;
        
        if (tempModel1) {
            if (tempModel1.sectionStatus != withOutUpdate) {
                tempModel.sectionStatus = allUpdate;
                continue;
            }
        }
        
        if (tempModel.lastNum == 0 && [self.collectionView numberOfItemsInSection:i] > 0) {
            tempModel.sectionStatus = allUpdate;
        }else if (tempModel.lastNum == [self.collectionView numberOfItemsInSection:i]) {
            tempModel.sectionStatus = withOutUpdate;
        }else if (tempModel.lastNum < [self.collectionView numberOfItemsInSection:i]) {
            tempModel.sectionStatus = littleUpdate;
        }
        
    }
}

/** 组合成一个完整的布局数组*/
- (void)mergeWholeArr{
    [self.attrsMuArray removeAllObjects];
    
    for (int i = 0; i < self.collectionView.numberOfSections; i++) {
        SectionModel *tempModel = self.sectionInfoMuArray[i];
        [self.attrsMuArray addObjectsFromArray:tempModel.sectionAttriMuArray];
    }
}

/**
 *  设置每组的最大Y值
 */
- (void)setSectionMaxY:(NSInteger)section{
    SectionModel *tempModel = self.sectionInfoMuArray[section];
    [tempModel.maxYMuArray removeAllObjects];
    [tempModel.maxYMuArray addObjectsFromArray:[self.maxColumnYMuArray copy]];
}

/**
 *  设置初始最大Y值
 */
- (void)setMaxY:(NSInteger)section{
    SectionModel *tempModel = self.sectionInfoMuArray[section];
    
    for (int i = 0; i < self.columnsCount; i++) {
        [self.maxColumnYMuArray replaceObjectAtIndex:i withObject:tempModel.maxYMuArray[i]];
    }
}

/**
 *  获取最短列的数据
 */
- (void)getMinColumnInfo:(void(^)(NSInteger minColumn, CGFloat minY))completeBlock{
    __block NSInteger minColumn = 0;    //最短那一列的序号
    __block CGFloat minY = [self.maxColumnYMuArray[0] floatValue];  //最短那一列的最大Y值
    
    [self.maxColumnYMuArray enumerateObjectsUsingBlock:^(NSNumber *columnY, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([columnY floatValue] < minY) {
            minY = [columnY floatValue];
            minColumn = idx;
        }
    }];
    
    completeBlock(minColumn, minY);
}

/**
 *  获取最大Y值
 */
- (CGFloat)getMaxY{
    __block CGFloat maxY = [self.maxColumnYMuArray[0] floatValue];
    
    [self.maxColumnYMuArray enumerateObjectsUsingBlock:^(NSNumber *columnY, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([columnY floatValue] > maxY) {
            maxY = [columnY floatValue];
        }
    }];
    
    return maxY;
}

/**
 *  更新最大Y值
 */
- (void)updateMaxY:(CGFloat)maxY{
    
    __weak typeof(self) weakSelf = self;
    
    [self.maxColumnYMuArray enumerateObjectsUsingBlock:^(NSNumber *columnY, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.maxColumnYMuArray replaceObjectAtIndex:idx withObject:@(maxY)];
    }];
}

#pragma mark - getter

- (NSMutableArray *)maxColumnYMuArray{
    if (!_maxColumnYMuArray) {
        NSMutableArray *tempMuArray = [NSMutableArray new];
        for (int i = 0; i < self.columnsCount; i++) {
            [tempMuArray addObject:@(self.sectionEdgeInset.top)];
        }
        _maxColumnYMuArray = tempMuArray;
    }
    return _maxColumnYMuArray;
}

- (NSMutableArray *)attrsMuArray{
    if (!_attrsMuArray) {
        _attrsMuArray = [NSMutableArray new];
    }
    return _attrsMuArray;
}

- (NSMutableArray *)sectionInfoMuArray{
    if (!_sectionInfoMuArray) {
        _sectionInfoMuArray = [NSMutableArray new];
        for (int i = 0; i < self.collectionView.numberOfSections; i++) {
            SectionModel *tempModel = [SectionModel new];
            [tempModel.maxYMuArray addObjectsFromArray:self.maxColumnYMuArray.copy];
            [_sectionInfoMuArray addObject:tempModel];
        }
    }
    return _sectionInfoMuArray;
}

- (NSNumber *)itemWidth{
    if (!_itemWidth) {
        CGFloat allGap = self.sectionEdgeInset.left + self.sectionEdgeInset.right + (self.columnsCount - 1) * self.columnMargin;
        _itemWidth = @((CGRectGetWidth(self.collectionView.frame) - allGap) / self.columnsCount);
    }
    return _itemWidth;
}

@end
