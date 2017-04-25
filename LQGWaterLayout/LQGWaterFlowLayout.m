//
//  LQGWaterFlowLayout.m
//  LQGWaterLayout
//
//  Created by quangang on 2017/4/18.
//  Copyright © 2017年 LQG. All rights reserved.
//

#import "LQGWaterFlowLayout.h"

@interface LQGWaterFlowLayout()

//存储每列的最大y值
@property (nonatomic, strong) NSMutableArray *maxColumnYMuArray;
//存储布局属性
@property (nonatomic, strong) NSMutableArray *attrsMuArray;
//当前布局的最后一个item
@property (nonatomic, assign) NSIndexPath *lastIndexPath;
/** 列数*/
@property (nonatomic, assign) NSInteger columnsCount;
/** 行距*/
@property (nonatomic, assign) CGFloat rowMargin;
/** 列距*/
@property (nonatomic, assign) CGFloat columnMargin;
/** 每组的间距*/
@property (nonatomic, assign) UIEdgeInsets sectionEdgeInset;
/** item的宽度*/
@property (nonatomic, assign) CGFloat itemWidth;

/** 
 * 获得item高度（必须实现）
 */
@property (nonatomic, copy) CGFloat(^itemHeightBlock)(NSIndexPath *itemIndex);

/**
 *  获得头视图高度（必须实现）
 */
@property (nonatomic, copy) CGSize(^headerSizeBlock)(NSIndexPath *headerIndex);

/**
 *  获得尾视图高度（必须实现）
 */
@property (nonatomic, copy) CGSize(^footerSizeBlock)(NSIndexPath *footerIndex);

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
        self.sectionEdgeInset = UIEdgeInsetsMake(((sectionEdgeInset.top < 0) ? 0 : sectionEdgeInset.top),
                                                 ((sectionEdgeInset.left < 0) ? 0 : sectionEdgeInset.left),
                                                 ((sectionEdgeInset.bottom < 0) ? 0 : sectionEdgeInset.bottom),
                                                 ((sectionEdgeInset.right < 0) ? 0 : sectionEdgeInset.right));
        self.columnMargin = ((columnMargin < 0) ? 0 : columnMargin);
        self.rowMargin = ((rowMargin < 0) ? 0 : rowMargin);
        self.columnsCount = ((columnsCount == 0) ? 1 : columnsCount);
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
 *  获取所有的布局属性
 */
- (void)prepareLayout{
    
    //添加每个item的布局到布局数组中
    for (NSInteger i = self.lastIndexPath.section; i < self.collectionView.numberOfSections; i++) {
        
        //添加header的布局属性
        UICollectionViewLayoutAttributes *headerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                             atIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
        [self.attrsMuArray addObject:headerAttri];
        
        //添加当前组的每一个item的布局属性
        for (NSInteger j = self.lastIndexPath.item; j < [self.collectionView numberOfItemsInSection:i]; j++) {
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            UICollectionViewLayoutAttributes *itemAttri = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
            [self.attrsMuArray addObject:itemAttri];
        }
        
        //添加footer的布局属性
        UICollectionViewLayoutAttributes *footerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                             atIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
        [self.attrsMuArray addObject:footerAttri];
    }
}

/**
 *  返回collectionview的contentsize
 */
- (CGSize)collectionViewContentSize{
    return CGSizeMake(0, [self getMaxY] + self.rowMargin);
}

/**
 *  返回每一个item的布局属性
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *attri = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    
    [self getMinColumnInfo:^(NSInteger minColumn, CGFloat minY) {
        CGFloat itemHeight = weakSelf.itemHeightBlock(indexPath);
        CGFloat itemX = weakSelf.sectionEdgeInset.left + minColumn * (weakSelf.columnMargin + [weakSelf itemWidth]);
        CGFloat itemY = minY + weakSelf.rowMargin;
        attri.frame = CGRectMake(itemX, itemY, [weakSelf itemWidth], itemHeight);
        weakSelf.maxColumnYMuArray[minColumn] = @(CGRectGetMaxY(attri.frame));
        weakSelf.lastIndexPath = indexPath;
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
    self.lastIndexPath = indexPath;
    return headerAttri;
}

/**
 *  获得尾部视图的布局属性
 */
- (UICollectionViewLayoutAttributes *)attributesForFooterAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *footerAttri = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                                                   withIndexPath:indexPath];
    CGSize footerSize = self.footerSizeBlock(indexPath);
    footerAttri.frame = CGRectMake(0, [self getMaxY] + self.sectionEdgeInset.bottom, footerSize.width, footerSize.height);
    [self updateMaxY:CGRectGetMaxY(footerAttri.frame)];
    return footerAttri;
}

#pragma mark - privateMethod

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

/**
 *  获取itemWidth
 */
- (CGFloat)itemWidth{
    static BOOL isFinish = NO;
    
    if (!isFinish) {
        isFinish = YES;
        CGFloat allGap = self.sectionEdgeInset.left + self.sectionEdgeInset.right + (self.columnsCount - 1) * self.columnMargin;
        _itemWidth = (CGRectGetWidth(self.collectionView.frame) - allGap) / self.columnsCount;
    }
    return _itemWidth;
}

#pragma mark - getter

- (NSMutableArray *)maxColumnYMuArray{
    if (!_maxColumnYMuArray) {
        _maxColumnYMuArray = [NSMutableArray arrayWithArray:@[@(self.sectionEdgeInset.top),
                                                              @(self.sectionEdgeInset.top),
                                                              @(self.sectionEdgeInset.top)]];
    }
    return _maxColumnYMuArray;
}

- (NSMutableArray *)attrsMuArray{
    if (!_attrsMuArray) {
        _attrsMuArray = [NSMutableArray new];
    }
    return _attrsMuArray;
}

@end


