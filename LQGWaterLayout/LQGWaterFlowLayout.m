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
//当前布局的section
@property (nonatomic, assign) NSInteger section;
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
        
        self.itemHeightBlock = itemHeightBlock;
        self.headerSizeBlock = headerSizeBlock;
        self.footerSizeBlock = footerSizeBlock;
        
        //对sectionEdgeInset进行容错处理
        //所有的属性不能小于0，如果小于0就使用默认0
        //如果未设置也使用默认0
        if (sectionEdgeInset.top < 0) {
            sectionEdgeInset.top = 0;
        }
        
        if (sectionEdgeInset.bottom < 0) {
            sectionEdgeInset.bottom = 0;
        }
        
        if (sectionEdgeInset.left < 0) {
            sectionEdgeInset.left = 0;
        }
        
        if (sectionEdgeInset.right < 0) {
            sectionEdgeInset.right = 0;
        }
        self.sectionEdgeInset = sectionEdgeInset;
        
        //对columnMargin进行容错
        if (columnMargin < 0) {
            columnMargin = 0;
        }
        self.columnMargin = columnMargin;
        
        //对rowMargin进行容错
        if (rowMargin < 0) {
            rowMargin = 0;
        }
        self.rowMargin = rowMargin;
        
        //对columnsCount进行容错
        self.columnsCount = columnsCount;
        if (columnsCount == 0) {
            self.columnsCount = 1;
        }
        
        CGFloat allGap = self.sectionEdgeInset.left + self.sectionEdgeInset.right + (self.columnsCount - 1) * self.columnMargin;
        self.itemWidth = (CGRectGetWidth(self.collectionView.frame) - allGap) / self.columnsCount;
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
    
    //设置初始的每列的最大y值
    if (self.maxColumnYMuArray.count > 0) {
        [self.maxColumnYMuArray removeAllObjects];
    }
    
    for (int i = 0; i < self.columnsCount; i++) {
        [self.maxColumnYMuArray addObject:@(self.sectionEdgeInset.top)];
    }
    
    self.section = 0;
    [self.attrsMuArray removeAllObjects];
    NSInteger sectionNum = self.collectionView.numberOfSections;
    
    for (int i = 0; i < sectionNum; i++) {
        
        //获取header的布局属性
        NSIndexPath *sectionHeaderIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
        UICollectionViewLayoutAttributes *headerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                             atIndexPath:sectionHeaderIndexPath];
        [self.attrsMuArray addObject:headerAttri];
        
        //获取当前组的item数量
        NSInteger itemNum = [self.collectionView numberOfItemsInSection:i];
        
        //获取当前组的每一个item的布局属性
        for (int j = 0; j < itemNum; j++) {
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            UICollectionViewLayoutAttributes *itemAttri = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
            [self.attrsMuArray addObject:itemAttri];
        }
        
        //获取footer的布局属性
        NSIndexPath *sectionFooterIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
        UICollectionViewLayoutAttributes *footerAttri = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                             atIndexPath:sectionFooterIndexPath];
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
    
    //最短那一列的序号
    __block NSInteger minColumn = 0;
    
    //最短那一列的最大Y值
    __block CGFloat minY = [self.maxColumnYMuArray[0] floatValue];
    [self.maxColumnYMuArray enumerateObjectsUsingBlock:^(NSNumber *columnY, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([columnY floatValue] < minY) {
            minY = [columnY floatValue];
            minColumn = idx;
        }
    }];
    
    CGFloat itemHeight = self.itemHeightBlock(indexPath);
    CGFloat itemX = self.sectionEdgeInset.left + minColumn * (self.columnMargin + self.itemWidth);
    CGFloat itemY = minY + self.rowMargin;
    
    attri.frame = CGRectMake(itemX, itemY, self.itemWidth, itemHeight);
    self.maxColumnYMuArray[minColumn] = @(CGRectGetMaxY(attri.frame));
    return attri;
}

/**
 *  反回头尾视图
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
    CGFloat maxY = [self getMaxY];
    if (self.section != indexPath.section) {
        headerAttri.frame = CGRectMake(0, maxY + self.sectionEdgeInset.top, headerSize.width, headerSize.height);
        self.section = indexPath.section;
    }else{
        headerAttri.frame = CGRectMake(0, maxY, headerSize.width, headerSize.height);
    }
    [self updateMaxY:CGRectGetMaxY(headerAttri.frame)];
    return headerAttri;
}

/**
 *  获得尾部视图的布局属性
 */
- (UICollectionViewLayoutAttributes *)attributesForFooterAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *footerAttri = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                                                   withIndexPath:indexPath];
    CGSize footerSize = self.footerSizeBlock(indexPath);
    CGFloat maxY = [self getMaxY];
    footerAttri.frame = CGRectMake(0, maxY + self.sectionEdgeInset.bottom, footerSize.width, footerSize.height);
    [self updateMaxY:CGRectGetMaxY(footerAttri.frame)];
    return footerAttri;
}

#pragma mark - privateMethod

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
    if (self.maxColumnYMuArray.count > 0) {
        [self.maxColumnYMuArray removeAllObjects];
    }
    
    for (int i = 0; i < self.columnsCount; i++) {
        [self.maxColumnYMuArray addObject:@(maxY)];
    }
}

#pragma mark - getter

- (NSMutableArray *)maxColumnYMuArray{
    if (!_maxColumnYMuArray) {
        _maxColumnYMuArray = [NSMutableArray new];
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
