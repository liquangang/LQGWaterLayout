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
 *      * 高度block必须实现，不实现就会崩溃，其余参数有默认值，如果参数错误会使用默认值（除列数未设置时默认为1，其余未设置时均默认为0）；
 *      * item的宽度是固定的，高度可自由设置
 *      * 尽量只计算新增的item的布局，因为新增item的问题，所有受影响的头尾视图也会重新计算布局
 *      * 该布局类只适合增加item的情况，有如下三种情况可以支持（其他情况未经测试，不建议使用）
 *       * 每次刷新每组都在增加item的情况
 *       * 每次刷新增加一组或几组item的情况
 *       * 只有一组，每次刷新增加item的情况
 *
 */

@interface LQGWaterFlowLayout : UICollectionViewLayout

/**
 布局类初始化方法

 @param columnsCount                        列数
 @param rowMargin                           行距
 @param columnMargin                        列距
 @param sectionEdgeInset                    组边距
 @param itemHeightBlock                     获取每个itemHeight的block
 @param headerSizeBlock                     获取每个headersize的block
 @param footerSizeBlock                     获取每个footersize的block
 @return                                    初始化完成的布局对象
 */
- (instancetype)initWithColumnsCount:(NSUInteger)columnsCount
                           rowMargin:(CGFloat)rowMargin
                       columnsMargin:(CGFloat)columnMargin
                    sectionEdgeInset:(UIEdgeInsets)sectionEdgeInset
                         getItemSize:(CGFloat(^)(NSIndexPath *itemIndex))itemHeightBlock
                       getHeaderSize:(CGSize(^)(NSIndexPath *headerIndex))headerSizeBlock
                       getFooterSize:(CGSize(^)(NSIndexPath *footerIndex))footerSizeBlock;

@end
