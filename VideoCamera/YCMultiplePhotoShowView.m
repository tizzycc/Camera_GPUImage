//
//  YCMultiplePhotoShowView.m
//   
//
//  Created by  yc on 16/10/14.
//  Copyright © 2016年  yc. All rights reserved.
//

#import "YCMultiplePhotoShowView.h"
#import <Photos/Photos.h>
#define kImageViewM      10 //照片中间的间隔
#define kPhotoScrollW    (KSCREENWIDTH + kImageViewM * 2)

#define kLoadSucceed     @"kLoadSucceed"
#define kLoadFailed      @"kLoadFailed"

#define kAnimateDuration 0.2f

#define kMinZoom         1.0f
#define kMaxZoom         4.0f

@implementation YCMultiplePhotoShowView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"动态点击看大图 - initWithFrame");

        [self addSubviews];
        [self addObservers];
        [self addTapGestureOnSelf];
    }
    return self;
}

- (void)addSubviews
{
    NSLog(@"动态点击看大图 - addSubviews");

    self.backgroundColor = [UIColor blackColor];
    
    self.photoScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(-kImageViewM, 0, kPhotoScrollW, KSCREENHEIGHT)];
    self.photoScroll.pagingEnabled = YES;
    self.photoScroll.showsHorizontalScrollIndicator = NO;
    self.photoScroll.showsVerticalScrollIndicator = NO;
    [self addSubview:self.photoScroll];
}

- (void)addObservers
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissMultiplePhotoShow) name:YC_VideoChatisShowing object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissMultiplePhotoShow)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)updateMultiplePhotoShowView
{
    NSLog(@"动态点击看大图 - updateMultiplePhotoShowView");
    
    self.isShowing = YES;
    
    self.currentIndex = self.index;

    [self firstImageAnimate];

    for (int i = 0; i < self.photoArray.count; i++) {
        
        UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(kPhotoScrollW * i + kImageViewM, 0, KSCREENWIDTH, KSCREENHEIGHT)];
        [self.photoScroll addSubview:backView];
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, KSCREENWIDTH, KSCREENHEIGHT)];
        scrollView.minimumZoomScale = kMinZoom;
        scrollView.maximumZoomScale = kMaxZoom;
        scrollView.delegate = self;
        [self addTapRecognizerOnScrollView:scrollView];
        [backView addSubview:scrollView];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, KSCREENWIDTH, KSCREENHEIGHT)];
        imageView.multipleTouchEnabled = YES;
        [self addLongGestureOnImageView:imageView];
        [scrollView addSubview:imageView];
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        activity.center = self.center;
        [backView addSubview:activity];
        
        NSString *photo = [NSString stringWithFormat:@"%@",self.photoArray[i]];
        photo = [photo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self.loadImageDic setObject:kLoadFailed forKey:photo];
    }
    
    self.photoScroll.contentSize = CGSizeMake((CGRectGetWidth(self.photoScroll.frame)) * self.photoArray.count, KSCREENHEIGHT);
    [self.photoScroll setContentOffset:CGPointMake(self.index * CGRectGetWidth(self.photoScroll.frame), 0) animated:NO];
    
    [self updateCurrentImage];
    
    self.photoScroll.delegate = self; //防止刚进来就走跳到下一个的方法
    
    if (self.photoArray.count > 1) {
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, KSCREENHEIGHT - 50, KSCREENWIDTH, 30)];
        self.pageControl.numberOfPages = self.photoArray.count;
        self.pageControl.currentPage = self.index;
        self.pageControl.userInteractionEnabled = NO;
        self.pageControl.currentPageIndicatorTintColor = kPageControlCurrentColor;
        self.pageControl.pageIndicatorTintColor = kPageControlDefaultColor;
        [self addSubview:self.pageControl];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.photoScroll) {
        
        CGFloat x = scrollView.contentOffset.x;
        
        NSInteger page = 0;
        if (x > 0) {
            page = (x + KSCREENWIDTH / 2) / KSCREENWIDTH;
        }else {
            page = (x - KSCREENWIDTH / 2) / KSCREENWIDTH;
        }
        
        if (page > self.currentIndex && page < self.photoArray.count) {
            
            self.currentIndex = page;
            self.pageControl.currentPage = self.currentIndex;
            
            [self scrollToNextPage];
            
        }else if (page < self.currentIndex && page >= 0) {
            
            self.currentIndex = page;
            self.pageControl.currentPage = self.currentIndex;
            
            [self scrollToPreviousPage];
        }
    }
}

#pragma mark - 赋值
- (void)updateCurrentImage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIView *currentView = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentView photo:self.photoArray[index] placeholder:self.placeholderArray[index]];
    }
    
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex < self.photoArray.count) {
        UIView *nextView = self.photoScroll.subviews[nextIndex];
        [self setImageWithScrollView:nextView photo:self.photoArray[nextIndex] placeholder:self.placeholderArray[nextIndex]];
    }
    
    NSInteger previousIndex = self.currentIndex - 1;
    if (previousIndex < self.photoArray.count) {
        UIView *previousView = self.photoScroll.subviews[previousIndex];
        [self setImageWithScrollView:previousView photo:self.photoArray[previousIndex] placeholder:self.placeholderArray[previousIndex]];
    }
}

- (void)scrollToNextPage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIView *currentView = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentView photo:self.photoArray[index] placeholder:self.placeholderArray[index]];
    }
    
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex < self.photoArray.count) {
        UIView *nextView = self.photoScroll.subviews[nextIndex];
        [self setImageWithScrollView:nextView photo:self.photoArray[nextIndex] placeholder:self.placeholderArray[nextIndex]];
    }
}

- (void)scrollToPreviousPage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIView *currentView = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentView photo:self.photoArray[index] placeholder:self.placeholderArray[index]];
    }
    
    NSInteger previousIndex = self.currentIndex - 1;
    if (previousIndex < self.photoArray.count) {
        UIView *previousView = self.photoScroll.subviews[previousIndex];
        [self setImageWithScrollView:previousView photo:self.photoArray[previousIndex] placeholder:self.placeholderArray[previousIndex]];
    }
}

- (void)setImageWithScrollView:(UIView *)backView photo:(NSString *)photo placeholder:(NSString *)placeholder
{
    NSLog(@"动态点击看大图 - setImageWithScrollView photo = %@",photo);
    
    UIScrollView *scrollView = (UIScrollView *)backView.subviews.firstObject;
    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)backView.subviews[1];

    UIImageView *imageView = (UIImageView *)scrollView.subviews.firstObject;
    
    if (photo == nil) {
        imageView.image = nil;
        return;
    }
    
    photo = [photo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    photo = [YCPicProcessHelper resizePath:photo
                                     withW:nil
                                      andH:nil
                                cropCenter:NO
                                   andWebp:YES];
    
    NSString *loadResult = [self.loadImageDic objectForKeyYC:photo];
    if ([loadResult isEqualToString:kLoadSucceed]) {
        self.canScale = YES;
        return;
    }
    
    UIImage *placeholderImage = nil;
    placeholderImage = [YCBDataHelper getImageWithStr:placeholder];
    imageView.contentMode = UIViewContentModeScaleToFill;
    
    if (placeholderImage != nil) {
        
        CGFloat tmpHeight = KSCREENWIDTH * placeholderImage.size.height / placeholderImage.size.width;
        imageView.frame = CGRectMake(0, 0, KSCREENWIDTH, tmpHeight);
        
        if (tmpHeight <= [UIScreen mainScreen].bounds.size.height) {
            imageView.center = self.center;
        }else {
            scrollView.contentSize = CGSizeMake(KSCREENWIDTH, tmpHeight);
        }
    }

    self.canScale = NO;
    
    [activity startAnimating];
    

    
    [imageView sd_setImageWithURL:[NSURL URLWithString:photo] placeholderImage:placeholderImage options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        [activity stopAnimating];
        
        if (image == nil) { //图片失败了
            
            if (placeholderImage == nil) {
                self.canScale = NO;
                imageView.contentMode = UIViewContentModeCenter;
                
                scrollView.maximumZoomScale = 1.0;
                imageView.image = [UIImage imageNamed:@"chat_pic_loadfailed"];
            }
            
        }else {
            
            self.canScale = YES;
            imageView.contentMode = UIViewContentModeScaleToFill;
            
            [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
            
            CGFloat tmpHeight = KSCREENWIDTH*image.size.height / image.size.width;
            imageView.frame = CGRectMake(0, 0, KSCREENWIDTH, tmpHeight);
            
            if (tmpHeight < KSCREENHEIGHT) {
                CGFloat tmpZoom = KSCREENHEIGHT / tmpHeight;
                
                if (tmpZoom < kMaxZoom) {
                    tmpZoom = kMaxZoom;
                }
                scrollView.maximumZoomScale = tmpZoom;
   
            }else {
                scrollView.maximumZoomScale = kMaxZoom;
            }
            
            if (tmpHeight <= [UIScreen mainScreen].bounds.size.height) {
                imageView.center = self.center;
            }else {
                scrollView.contentSize = CGSizeMake(KSCREENWIDTH, tmpHeight);
            }
            
            imageView.image = image;
            
            NSString *tmpStr = imageURL.absoluteString;
            [self.loadImageDic setObject:kLoadSucceed forKey:tmpStr];
        }
    }];
}

- (void)dismissMultiplePhotoShow
{
    self.isShowing = NO;
    if ([YCDynamicsDataHelper shared].multiplePhotoShowView != nil) {
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [UIApplication sharedApplication].statusBarHidden = NO;
        [[YCDynamicsDataHelper shared].multiplePhotoShowView removeFromSuperview];
        [YCDynamicsDataHelper shared].multiplePhotoShowView = nil;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (self.canScale) {
        return (UIImageView *)scrollView.subviews.firstObject;
    }
    return nil;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (!self.canScale) {
        return;
    }
    UIImageView *imageView = (UIImageView *)scrollView.subviews.firstObject;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                   scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)addTapRecognizerOnScrollView:(UIScrollView *)scrollView
{
    UITapGestureRecognizer *tapSingle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapEvent:)];
    tapSingle.numberOfTapsRequired = 1;
    tapSingle.numberOfTouchesRequired = 1;
    [scrollView addGestureRecognizer:tapSingle];
    
    UITapGestureRecognizer *tapDouble = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapEvent:)];
    tapDouble.numberOfTapsRequired = 2;
    tapDouble.numberOfTouchesRequired = 1;
    [scrollView addGestureRecognizer:tapDouble];
    
    [tapSingle requireGestureRecognizerToFail:tapDouble];
}

- (void)handleTapEvent:(UITapGestureRecognizer *)tap
{
    UIScrollView *scrollView = (UIScrollView *)tap.view;
    
    if (tap.numberOfTapsRequired == 2) {
        
        if (self.canScale) {
            if (scrollView.zoomScale < scrollView.maximumZoomScale) {
                [scrollView setZoomScale:scrollView.maximumZoomScale animated:YES];
            }else {
                [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
            }
        }
        
    }else {
        
        [self dismissMultiplePhotoShowAnimate];
    }
}

- (void)addLongGestureOnImageView:(UIImageView *)imageView
{
    imageView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(photoImageLongPressGesture:)];
    longPressGesture.minimumPressDuration = 0.8;
    [imageView addGestureRecognizer:longPressGesture];
}

- (void)photoImageLongPressGesture:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        self.saveImageView = (UIImageView *)longPress.view;
        
        if (IS_IOS8) {
            
            __weak typeof(self)weakSelf = self;
            self.savePhotoAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            UIAlertAction *destructiveAction1 = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf actionSheetPhoto];
            }];
            [self.savePhotoAlertController addAction:cancelAction];
            [self.savePhotoAlertController addAction:destructiveAction1];
            
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate.tabBarViewController presentViewController:self.savePhotoAlertController animated:YES completion:^{
                
            }];
        }else {
            if (self.actionSheetSavePhoto == nil) {
                self.actionSheetSavePhoto = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存", nil];
            }
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [self.actionSheetSavePhoto showFromTabBar:appDelegate.tabBarViewController.tabBar];
        }
    }
}

- (void)addTapGestureOnSelf
{
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMultiplePhotoShowAnimate)];
    [self addGestureRecognizer:self.tapGesture];
}

#pragma mark - 看大图动画
- (void)firstImageAnimate
{
    [self configureFrameArray];
    
    [self hidePhotoScroll];

    UIImage *destImage = nil;
    if (self.index < self.photoArray.count) {
        destImage = [YCBDataHelper getImageWithStr:self.photoArray[self.index]];
    }else {
        NSLog(@"动态看大图 - 越界 self.index = %ld self.photoArray = %@",self.index,self.photoArray);
    }
    
    if (destImage == nil) {
        if (self.index < self.placeholderArray.count) {
            destImage = [YCBDataHelper getImageWithStr:self.placeholderArray[self.index]];
        }else {
            NSLog(@"动态看大图 - 越界 self.index = %ld placeholderArray = %@",self.index,self.placeholderArray);
        }
    }
    
    if (destImage == nil) {
        
        [self showPhotoScroll];
        
    }else {
        
        if (self.index < self.frameArray.count) {
            
            NSString *rect = [NSString stringWithFormat:@"%@",[self.frameArray objectAtIndex:self.index]];
            CGRect originRect = CGRectFromString(rect);
            
            CGFloat desH = 0;
            CGFloat desY = 0;
            
            desH = destImage.size.height / destImage.size.width * KSCREENWIDTH;
            
            desY = (KSCREENHEIGHT - desH) / 2;
            if (desY < 0) {
                desY = 0;
            }
            
            CGRect desRect = CGRectMake(0, desY, KSCREENWIDTH, desH);
            
            UIImageView *tmpImageView = [[UIImageView alloc] init];
            tmpImageView.image = destImage;
            [self addSubview:tmpImageView];
            
            tmpImageView.frame = originRect;
            
            [UIView animateWithDuration:kAnimateDuration animations:^{
                
                tmpImageView.frame = desRect;
                
            } completion:^(BOOL finished) {
                
                [tmpImageView removeFromSuperview];
                [self showPhotoScroll];
                
            }];
        }else {
            
            NSLog(@"动态看大图 - 越界 self.index = %ld frameArray = %@",self.index,self.frameArray);
            [self showPhotoScroll];
        }
    }
}

- (void)dismissMultiplePhotoShowAnimate
{
    [self hidePhotoScroll];
    [UIApplication sharedApplication].statusBarHidden = NO;

    UIImage *desImage = nil;
    
    if (self.currentIndex < self.photoArray.count) {
        desImage = [YCBDataHelper getImageWithStr:self.photoArray[self.currentIndex]];
    }else {
        NSLog(@"动态看大图 - 收回越界 self.currentIndex = %ld self.photoArray = %@",(long)self.currentIndex,self.photoArray);
    }
    
    if (desImage == nil) {
        if (self.currentIndex < self.placeholderArray.count) {
            desImage = [YCBDataHelper getImageWithStr:self.placeholderArray[self.currentIndex]];
        }else {
            NSLog(@"动态看大图 - 收回越界 self.currentIndex = %ld self.placeholderArray = %@",(long)self.currentIndex,self.placeholderArray);
        }
    }

    if (desImage == nil) {
        
        [self dismissMultiplePhotoShow];
        
    }else {
        
        if (self.currentIndex < self.frameArray.count) {
            
            NSString *rect = [NSString stringWithFormat:@"%@",[self.frameArray objectAtIndex:self.currentIndex]];
            CGRect originRect = CGRectFromString(rect);
            CGFloat desY = 0;
            CGFloat desH = 0;
            
            desH = desImage.size.height / desImage.size.width * KSCREENWIDTH;
            
            desY = (KSCREENHEIGHT - desH) / 2;
            if (desY < 0) {
                desY = 0;
            }
            
            CGRect desRect = CGRectMake(0, desY, KSCREENWIDTH, desH);
            
            UIView *tmpView = [[UIView alloc] init];
            [self addSubview:tmpView];
            tmpView.layer.masksToBounds = YES;
            
            UIImageView *tmpImageView = [[UIImageView alloc] init];
            tmpImageView.image = desImage;
            [tmpView addSubview:tmpImageView];
            
            tmpView.frame = desRect;
            tmpImageView.frame = CGRectMake(0, 0, desRect.size.width, desRect.size.height);
            
            CGFloat imgX = 0;
            CGFloat imgY = 0;
            CGFloat imgW = 0;
            CGFloat imgH = 0;
            
            if (desRect.size.width > desRect.size.height) {
                imgH = originRect.size.height;
                imgW = desRect.size.width / desRect.size.height * imgH;
                imgX = (originRect.size.width - imgW) / 2;
                imgY = 0;
            }else if (desRect.size.height > desRect.size.width) {
                imgW = originRect.size.width;
                imgH = desRect.size.height / desRect.size.width * imgW;
                imgY = (originRect.size.height - imgH) / 2;
                imgX = 0;
            }else {
                imgX = 0;
                imgY = 0;
                imgW = originRect.size.width;
                imgH = originRect.size.height;
            }
            
            CGRect imgRect = CGRectMake(imgX, imgY, imgW, imgH);
            
            [UIView animateWithDuration:kAnimateDuration animations:^{
                
                tmpView.frame = originRect;
                tmpImageView.frame = imgRect;
                self.backgroundColor = [UIColor clearColor];
                
            } completion:^(BOOL finished) {
                
                [tmpView removeFromSuperview];
                [self dismissMultiplePhotoShow];
                
            }];
        }else {
            NSLog(@"动态看大图 - 收回越界 self.currentIndex = %ld frameArray = %@",(long)self.currentIndex,self.frameArray);
            [self dismissMultiplePhotoShow];
        }
    }
}

- (void)showPhotoScroll
{
    self.photoScroll.hidden = NO;
    self.pageControl.hidden = NO;
    self.tapGesture.enabled = YES;
}

- (void)hidePhotoScroll
{
    self.photoScroll.hidden = YES;
    self.pageControl.hidden = YES;
    self.tapGesture.enabled = NO;
}


- (void)configureFrameArray
{
    NSArray *subviews = [self.containerView.subviews subarrayWithRange:NSMakeRange(0, self.photoArray.count)];
    
    [subviews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIView *view = (UIView *)[self.containerView viewWithTag:idx + 100];
        CGRect originRect = [self.containerView convertRect:view.frame toView:nil];
        
        [self.frameArray addObject:NSStringFromCGRect(originRect)];
        
    }];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self actionSheetPhoto];
    }
}

- (void)actionSheetPhoto
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    YCBaseNavigationViewController *tmpNavigation = appDelegate.tabBarViewController.selectedViewController;
    NSArray *tmpArray = tmpNavigation.viewControllers;
    YCBaseViewController *tmpViewController = [tmpArray lastObject];
    
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    
    switch (author) {
        case AVAuthorizationStatusDenied:
            [tmpViewController showAuthorityAlertViewWithType:AuthorityTypePhoto];
            break;
        case AVAuthorizationStatusNotDetermined:
        {
            if (IS_IOS8) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (status == PHAuthorizationStatusAuthorized) {
                            UIImageWriteToSavedPhotosAlbum(self.saveImageView.image, nil, nil, nil);
                            [tmpViewController addBDKNotifyHUDWithImage:nil text:@"保存成功"];
                        }
                    });
                }];
            }
        }
            break;
        case AVAuthorizationStatusAuthorized://已经认证
        {
            UIImageWriteToSavedPhotosAlbum(self.saveImageView.image, nil, nil, nil);
            [tmpViewController addBDKNotifyHUDWithImage:nil text:@"保存成功"];
            
        }
            break;
        default:
            break;
    }

}

- (NSMutableArray *)frameArray
{
    if (_frameArray == nil) {
        _frameArray = [NSMutableArray new];
    }
    return _frameArray;
}

- (NSMutableDictionary *)loadImageDic
{
    if (_loadImageDic == nil) {
        _loadImageDic = [NSMutableDictionary new];
    }
    return _loadImageDic;
}

@end
