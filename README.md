#### 瀑布流布局开源库
1. 目前第一个版本已经可以正常使用
2. 下面是调用示例代码
```

#import "ViewController.h"
#import "LQGWaterFlowLayout.h"
#import <MJRefresh.h>
#import "TestSecondCollectionViewCell.h"

static NSString *itemResuableStr = @"TestSecondCollectionViewCell";
static NSString *headerResuableStr = @"UICollectionReusableView";
static NSInteger loadCount = 3;

@interface ViewController ()
<
    UICollectionViewDelegate,
    UICollectionViewDataSource
>

@property (nonatomic, strong) UICollectionView *selectImageCollectionView;
@property (nonatomic, strong) LQGWaterFlowLayout *waterLayout;
@property (nonatomic, assign) NSUInteger sectionCount;
@property (nonatomic, strong) NSMutableArray *dataSourceMuArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.selectImageCollectionView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return self.dataSourceMuArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.dataSourceMuArray[section] count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TestSecondCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemResuableStr forIndexPath:indexPath];
    cell.testLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.item)];
    cell.testLabel.frame = cell.contentView.frame;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerResuableStr forIndexPath:indexPath];
        header.backgroundColor = [UIColor redColor];
        return header;
    }else{
        UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:headerResuableStr forIndexPath:indexPath];
        footer.backgroundColor = [UIColor greenColor];
        return footer;
    }
}

#pragma mark - private method

/**
 *  随机数
 */
+ (int)getRandomNumber:(int)from to:(int)to{
    return (int)(from + (arc4random() % ((to) - (from) + 1)));
}

/** 增加测试元素*/
- (void)addTestObj{
    
    //每组都在增加的情况
//    for (NSInteger i = 0; i < self.dataSourceMuArray.count; i++) {
//    
//        NSMutableArray *tempArray = self.dataSourceMuArray[i];
//        
//        int tempNum = [ViewController getRandomNumber:4 to:60];
//        NSUInteger arrCount = tempArray.count;
//        
//        for (NSUInteger j = arrCount; j < arrCount + tempNum; j++) {
//            [tempArray addObject:@(1)];
//        }
//    }
    
    //增加组的情况
//    NSInteger sectionCount = self.dataSourceMuArray.count;
//    
//    for (NSInteger i = sectionCount; i < sectionCount + 2; i++) {
//        NSMutableArray *tempArray = [NSMutableArray new];
//        
//        int tempNum = [ViewController getRandomNumber:4 to:60];
//        
//        for (int j = 0; j < tempNum; j++) {
//            [tempArray addObject:@(1)];
//        }
//        
//        [self.dataSourceMuArray addObject:tempArray];
//    }
    
    //只有一组，每次增加item的情况
    NSMutableArray *tempArray = self.dataSourceMuArray[0];
    
    int tempNum = [ViewController getRandomNumber:4 to:60];
    
    for (int j = 0; j < tempNum; j++) {
        [tempArray addObject:@(1)];
    }
}

#pragma mark - getter

- (UICollectionView *)selectImageCollectionView{
    if (!_selectImageCollectionView) {
        UICollectionView *tempCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.waterLayout];
        tempCollectionView.delegate = self;
        tempCollectionView.dataSource = self;
        tempCollectionView.backgroundColor = [UIColor grayColor];
        [tempCollectionView registerClass:[TestSecondCollectionViewCell class] forCellWithReuseIdentifier:itemResuableStr];
        [tempCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerResuableStr];
        [tempCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:headerResuableStr];
       
        __weak typeof(self) weakSelf = self;
        
        tempCollectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [tempCollectionView.mj_footer endRefreshing];
                
                [weakSelf addTestObj];
                [tempCollectionView reloadData];
            });
        }];
        
        _selectImageCollectionView = tempCollectionView;
    }
    return _selectImageCollectionView;
}

- (LQGWaterFlowLayout *)waterLayout{
    if (!_waterLayout) {
        LQGWaterFlowLayout *tempWaterLayout = [[LQGWaterFlowLayout alloc] initWithColumnsCount:0 rowMargin:0 columnsMargin:0 sectionEdgeInset:UIEdgeInsetsMake(0, 0, 0, 0) getItemSize:^CGFloat(NSIndexPath *itemIndex) {
            return 100;
        } getHeaderSize:^CGSize(NSIndexPath *headerIndex) {
            return CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), 100);
        } getFooterSize:^CGSize(NSIndexPath *footerIndex) {
            return CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), 100);
        }];
        _waterLayout = tempWaterLayout;
    }
    return _waterLayout;
}

- (UICollectionViewFlowLayout *)osLayout{
    UICollectionViewFlowLayout *tempFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    tempFlowLayout.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width / 3, [UIScreen mainScreen].bounds.size.width / 3);
    tempFlowLayout.headerReferenceSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 100);
    tempFlowLayout.footerReferenceSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 100);
    return tempFlowLayout;
}

- (NSMutableArray *)dataSourceMuArray{
    if (!_dataSourceMuArray) {
        NSMutableArray *tempMuArray = [NSMutableArray new];
        
        
     
            NSMutableArray *tempArray = [NSMutableArray new];
            
            int tempNum = [ViewController getRandomNumber:4 to:60];
            
            for (int j = 0; j < tempNum; j++) {
                [tempArray addObject:@(1)];
            }
            
            [tempMuArray addObject:tempArray];
       
        
        _dataSourceMuArray = tempMuArray;
    }
    return _dataSourceMuArray;
}

@end

```
