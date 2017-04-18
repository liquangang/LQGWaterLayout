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
 *  说明：高度block必须实现 使用set方法实现；其余的不设置，默认有1列，其余数据默认为0；
 *
 */

@interface LQGWaterFlowLayout : UICollectionViewLayout

//item的width
@property (nonatomic, assign) CGFloat itemWidth;

/** 列数*/
@property (nonatomic, assign) NSInteger columnsCount;
/** 行距*/
@property (nonatomic, assign) CGFloat rowMargin;
/** 列距*/
@property (nonatomic, assign) CGFloat columnMargin;
/** 每组的间距*/
@property (nonatomic, assign) UIEdgeInsets sectionEdgeInset;
/** 每次刷新增加的数据个数*/
@property (nonatomic, assign) NSInteger addNum;

/** 获得item高度（必须实现）*/
@property (nonatomic, copy) CGFloat(^itemHeightBlock)(NSIndexPath * itemIndex, CGFloat width);

/**
 *  获得头视图高度（必须实现）
 */
@property (nonatomic, copy) CGSize(^headerSizeBlock)(NSIndexPath *headerIndex);

/**
 *  获得尾视图高度（必须实现）
 */
@property (nonatomic, copy) CGSize(^footerSizeBlock)(NSIndexPath *footerIndex);

@end
