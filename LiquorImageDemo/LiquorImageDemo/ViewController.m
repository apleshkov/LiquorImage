//
//  ViewController.m
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import "ViewController.h"
#import <LiquorImage.h>
#import "FlickrImage.h"
#import "ImageCollectionViewCell.h"
#import "PreloadingView.h"
#import <PureLayout.h>


@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, getter=isLoading) BOOL loading;
@property (nonatomic, copy, nullable) NSArray<FlickrImage *> *images;
@property (nonatomic, readonly, nonnull) UICollectionView *collectionView;
@property (nonatomic, readonly, nonnull) UIRefreshControl *refreshControl;
@property (nonatomic, readonly, nonnull) PreloadingView *preloadingView;

@end


static NSString *const _kImageCellIdentifier = @"ImageCell";
static const NSInteger _kColCount = 2;


@implementation ViewController

- (void)refreshControlUpdated {
    [self loadData];
}

- (void)loadData {
    if (self.isLoading) {
        return;
    }
    self.loading = YES;
    [self.refreshControl beginRefreshing];
    typeof(self) __weak weakSelf = self;
    [FlickrImage loadImagesWithCompletion:^(NSArray<FlickrImage *> * _Nullable images, NSError * _Nullable error) {
        [weakSelf didLoadImages:images withError:error];
    }];
}

- (void)didLoadImages:(NSArray<FlickrImage *> *)images withError:(NSError *)error {
    self.loading = NO;
    [self.refreshControl endRefreshing];
    
    self.images = images;
    
    NSMutableArray<NSURL *> *preloads = [NSMutableArray array];
    [images enumerateObjectsUsingBlock:^(FlickrImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.imageURL) {
            [preloads addObject:obj.imageURL];
        }
    }];
    if (preloads.count > 0) {
        self.preloadingView.textLabel.text = @"Preloading...";
        self.preloadingView.hidden = NO;
        typeof(self) __weak weakSelf = self;
        [[LQImageLoader shared] preloadImageURLs:preloads withProgress:^(LQImageLoaderPreloadingContext * _Nonnull context) {
            weakSelf.preloadingView.textLabel.text = [NSString stringWithFormat:@"Preloading:\n\n%lu / %lu", (unsigned long)context.completedCount, (unsigned long)context.totalCount];
        } completion:^(LQImageLoaderPreloadingContext * _Nonnull context) {
            weakSelf.preloadingView.hidden = YES;
            [weakSelf.collectionView reloadData];
        }];
    }
}

- (void)loadView {
    [super loadView];
    
    _collectionView = ({
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        view.backgroundColor = [UIColor whiteColor];
        [view registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:_kImageCellIdentifier];
        view.dataSource = self;
        view.delegate = self;
        view;
    });
    _refreshControl = ({
        UIRefreshControl *refreshControl = [UIRefreshControl new];
        [refreshControl addTarget:self action:@selector(refreshControlUpdated) forControlEvents:UIControlEventValueChanged];
        refreshControl;
    });
    [_collectionView addSubview:_refreshControl];
    _preloadingView = [PreloadingView new];
    
    [self.view addSubview:_collectionView];
    [self.view addSubview:_preloadingView];
    
    [_collectionView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [_collectionView autoPinToTopLayoutGuideOfViewController:self withInset:0];
    
    [_preloadingView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    _preloadingView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.images.count == 0) {
        [self loadData];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_kImageCellIdentifier forIndexPath:indexPath];
    [cell displayImage:self.images[indexPath.row]];
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat contentWidth = (CGRectGetWidth(collectionView.bounds));
    CGFloat d = ((_kColCount - 1) * [(UICollectionViewFlowLayout *)collectionViewLayout minimumInteritemSpacing]);
    CGFloat width = ((contentWidth - d) / _kColCount);
    if (width <= 0) {
        return CGSizeMake(10, 10);
    }
    return CGSizeMake(width, width);
}

@end
