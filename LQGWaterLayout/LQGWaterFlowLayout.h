//
//  LQGWaterFlowLayout.h
//  LQGWaterLayout
//
//  Created by quangang on 2017/4/18.
//  Copyright © 2017年 LQG. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 *
 *      说明：
 *      高度block必须实现；
 *      其余的可以不设置；
 *      默认有1列，其余数据默认为0
 *
 */

@interface LQGWaterFlowLayout : UICollectionViewLayout

/**
 布局类初始化方法

 @param columnsCount 列数
 @param rowMargin 行距
 @param columnMargin 列距
 @param sectionEdgeInset 组边距
 @param itemHeightBlock 获取每个itemHeight的block
 @param headerSizeBlock 获取每个headersize的block
 @param footerSizeBlock 获取每个footersize的block
 @return 初始化完成的布局对象
 */
- (instancetype)initWithColumnsCount:(NSUInteger)columnsCount
                           rowMargin:(CGFloat)rowMargin
                       columnsMargin:(CGFloat)columnMargin
                    sectionEdgeInset:(UIEdgeInsets)sectionEdgeInset
                         getItemSize:(CGFloat(^)(NSIndexPath *itemIndex))itemHeightBlock
                       getHeaderSize:(CGSize(^)(NSIndexPath *headerIndex))headerSizeBlock
                       getFooterSize:(CGSize(^)(NSIndexPath *footerIndex))footerSizeBlock;

@end
