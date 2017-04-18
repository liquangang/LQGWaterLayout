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

@end

@implementation LQGWaterFlowLayout

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
    
    CGFloat itemHeight = self.itemHeightBlock(indexPath, self.itemWidth);
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

#pragma mark - 功能模块
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

#pragma mark - 懒加载

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

- (NSInteger)columnsCount{
    if (_columnsCount == 0) {
        _columnsCount = 1;
    }
    return _columnsCount;
}

- (CGFloat)itemWidth{
    if (_itemWidth == 0) {
        CGFloat allGap = self.sectionEdgeInset.left + self.sectionEdgeInset.right + (self.columnsCount - 1) * self.columnMargin;
        _itemWidth = (CGRectGetWidth(self.collectionView.frame) - allGap) / self.columnsCount;
    }
    return _itemWidth;
}

@end
