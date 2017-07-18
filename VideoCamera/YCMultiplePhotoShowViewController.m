//
//  YCMultiplePhotoShowViewController.m
//   
//
//  Created by  yc on 16/8/31.
//  Copyright © 2016年  yc. All rights reserved.
//

#import "YCMultiplePhotoShowViewController.h"
#import <Photos/Photos.h>
//#define kPrevious       @"previous"
//#define kCurrent        @"current"
//#define kNext           @"next"

#define kImageViewM     10 //照片中间的间隔
#define kPhotoScrollW   (KSCREENWIDTH + kImageViewM * 2)

#define kLoadSucceed    @"kLoadSucceed"
#define kLoadFailed     @"kLoadFailed"

typedef enum : NSUInteger {
    ScrollDirectionLeft,
    ScrollDirectionRight,
} ScrollDirection;

@interface YCMultiplePhotoShowViewController () <UIScrollViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UIScrollView *photoScroll;
@property (strong, nonatomic) UIPageControl *pageControl;

//@property (strong, nonatomic) NSMutableArray *bigPhotoArray;

//@property (strong, nonatomic) NSMutableDictionary *scrollDic;
@property (assign, nonatomic) NSInteger currentIndex;
@property (strong, nonatomic) NSMutableDictionary *loadImageDic; //记录图片是否加载成功

@property (strong, nonatomic) UIActionSheet *actionSheetSavePhoto;
@property (strong, nonatomic) UIAlertController *savePhotoAlertController;

@property (strong, nonatomic) UIImageView *saveImageView;  //保存图片

@property (assign, nonatomic) BOOL canScale;

@property (strong, nonatomic) UIView *navigationView;
@property (strong, nonatomic) UIImageView *navigationBackImage;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *leftBarButton;
@property (strong, nonatomic) UIButton *rightBarButton;
@property (assign, nonatomic) ScrollDirection scrollDirection;

@property (strong, nonatomic) UIActionSheet *actionSheetDelete;
@property (strong, nonatomic) UIAlertController *deleteAlertController;

@end

@implementation YCMultiplePhotoShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    [self configureBigPhotoArray];
    [self addSubviews];
    if (self.isSendDynamic)
    {
        [self addCustomNavigation];
    }
//    [self configureImageView];
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMultiplePhotoShow)];
//    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self closeCustomView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)addSubviews
{
    UIView *backView = [[UIView alloc]init];
    [self.view addSubview:backView];
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.isSendDynamic)
    {
        self.photoScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(-kImageViewM, 20, kPhotoScrollW, CGRectGetHeight(self.view.frame) - 20)];
    }
    else
    {
        self.photoScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(-kImageViewM, 0, kPhotoScrollW, CGRectGetHeight(self.view.frame))];
    }
    self.photoScroll.pagingEnabled = YES;
    self.photoScroll.showsHorizontalScrollIndicator = NO;
    self.photoScroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.photoScroll];
    
    for (int i = 0; i < self.photoArray.count; i++) {
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kPhotoScrollW * i + kImageViewM, 0, KSCREENWIDTH, CGRectGetHeight(self.photoScroll.frame))];
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 4.0;
        scrollView.delegate = self;
        [self addTapRecognizerOnScrollView:scrollView];
        [self.photoScroll addSubview:scrollView];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, KSCREENWIDTH, CGRectGetHeight(scrollView.frame))];
        
        
        //测试质量度时暂时打开试用
        imageView.multipleTouchEnabled = YES;
        [self addLongGestureOnImageView:imageView];
        
        
        
        [scrollView addSubview:imageView];

        NSString *photo = [NSString stringWithFormat:@"%@",self.photoArray[i]];
        [self.loadImageDic setObject:kLoadFailed forKey:photo];
    }
    
    self.currentIndex = self.index;
    self.photoScroll.contentSize = CGSizeMake((CGRectGetWidth(self.photoScroll.frame)) * self.photoArray.count, CGRectGetHeight(self.photoScroll.frame) - 64 - 49);
    [self.photoScroll setContentOffset:CGPointMake(self.index * CGRectGetWidth(self.photoScroll.frame), 0) animated:NO];
    
    self.photoScroll.delegate = self; //防止刚进来就走跳到下一个的方法
    
    [self updateCurrentImage];

    if (self.photoArray.count > 1) {
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 50, KSCREENWIDTH, 30)];
        self.pageControl.numberOfPages = self.photoArray.count;
        self.pageControl.currentPage = self.index;
        self.pageControl.userInteractionEnabled = NO;
        self.pageControl.currentPageIndicatorTintColor = kPageControlCurrentColor;
        self.pageControl.pageIndicatorTintColor = kPageControlDefaultColor;
        [self.view addSubview:self.pageControl];
    }
    [self addPanGestureOnView:self.photoScroll needDelegate:YES];
}

- (void)addCustomNavigation
{
    [self addNavigationView];
    [self addNavigationBackImage];
    [self addTitleLabel];
    [self addLeftBarButton];
    [self addRightBarButton];
}

- (void)addNavigationView
{
    _navigationView = [[UIView alloc]init];
    [self.view addSubview:_navigationView];
    
    [_navigationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(20);
        make.left.right.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(KSCREENWIDTH, kNavigationHeight));
    }];
}

- (void)addNavigationBackImage
{
    _navigationBackImage = [[UIImageView alloc] init];
    _navigationBackImage.backgroundColor = [UIColor blackColor];
    _navigationBackImage.alpha = 0.5f;
    [self.navigationView addSubview:_navigationBackImage];
    
    [_navigationBackImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(0);
        make.height.equalTo(self.navigationView);
    }];
}

- (void)addTitleLabel
{
    _titleLabel = [[UILabel alloc]init];
    _titleLabel.textColor = kWhiteColor;
    _titleLabel.font = kTextFont_navigationTitle;
    [self.navigationView addSubview:_titleLabel];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.navigationView);
    }];
    [self updateTitleLabel];
}

- (void)addLeftBarButton
{
    _leftBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_leftBarButton setBackgroundImage:[UIImage imageNamed:@"back_btn_normal"] forState:UIControlStateNormal];
    [_leftBarButton setBackgroundImage:[UIImage imageNamed:@"back_btn_selected"] forState:UIControlStateHighlighted];
    [_leftBarButton addTarget:self action:@selector(leftButtonIsPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationView addSubview:_leftBarButton];
    
    [_leftBarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(kBackButtonLeft);
        make.size.mas_equalTo(CGSizeMake(kBackButtonWidth, kBackButtonHeight));
        make.centerY.equalTo(self.navigationView);
    }];
}

- (void)addRightBarButton
{
    _rightBarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_rightBarButton addTarget:self
                        action:@selector(rightButtonIsPressed)
              forControlEvents:UIControlEventTouchUpInside];
    [_rightBarButton setBackgroundImage:[UIImage imageNamed:@"Shape6"] forState:UIControlStateNormal];
    [_rightBarButton setBackgroundImage:[UIImage imageNamed:@"Shape6"] forState:UIControlStateHighlighted];
    [self.navigationView addSubview:_rightBarButton];
    
    [_rightBarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.size.mas_equalTo(CGSizeMake(35, 35));
        make.centerY.equalTo(self.navigationView);
    }];
}

- (void)leftButtonIsPressed
{
    [self dismissMultiplePhotoShow];
}

- (void)rightButtonIsPressed
{
    if (IS_IOS8) {
        
        __weak typeof(self)weakSelf = self;
        
        self.deleteAlertController = [UIAlertController alertControllerWithTitle:kMultiPhotoShow_deleteTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        NSAttributedString *editSelectedAttri = [[NSAttributedString alloc] initWithString:kMultiPhotoShow_deleteTitle attributes:@{NSFontAttributeName:kTitleFontAleartController, NSForegroundColorAttributeName:kTitleColorAleartController,NSBaselineOffsetAttributeName:[NSNumber numberWithInt:kTitlBaselineOffsetAleartController]}];
        
        [self.deleteAlertController setValue:editSelectedAttri forKey:@"_attributedTitle"];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:kMultiPhotoShow_deleteCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *otherAction1 = [UIAlertAction actionWithTitle:kMultiPhotoShow_deleteEnsure style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteEnsure];
        }];
        [self.deleteAlertController addAction:cancelAction];
        [self.deleteAlertController addAction:otherAction1];
        [self presentViewController:self.deleteAlertController animated:YES completion:^{
            
        }];
    }else {
     
        if (self.actionSheetDelete == nil) {
            self.actionSheetDelete = [[UIActionSheet alloc]initWithTitle:kMultiPhotoShow_deleteTitle delegate:self cancelButtonTitle:kMultiPhotoShow_deleteCancel destructiveButtonTitle:nil otherButtonTitles:kMultiPhotoShow_deleteEnsure, nil];
        }
        [self.actionSheetDelete showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)deleteEnsure
{
    [self deleteCurrentImage];
    if (self.photoArray.count <= 0)
    {
        [self updateSendView];
        [self dismissMultiplePhotoShow];
        return;
    }
    
    if (self.currentIndex == 0 || self.scrollDirection == ScrollDirectionRight)
    {
        [self gotoNextImage];
    }
    else
    {
        [self gotoLastImage];
    }
    
    [self updateOffsetAfterDeleteImage];
    [self updateCurrentImage];
    [self updateTitleLabel];
    [self updateSendView];
}

- (void)updateSendView
{
    if (self.isSendDynamic)
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:YC_SendDynamic_Update object:self.photoArray];
    }
}

//删除当前图片
- (void)deleteCurrentImage
{
    [self.photoArray removeObjectAtIndex:self.currentIndex];
    NSArray *subScrolls = self.photoScroll.subviews;
    UIScrollView *currentScroll = subScrolls[self.currentIndex];
    [currentScroll removeFromSuperview];
    
    for (int i = 0; i < self.photoScroll.subviews.count; i++) {
        UIScrollView *scrollView = [self.photoScroll.subviews objectAtIndex:i];
        [scrollView setFrame:CGRectMake(kPhotoScrollW * i + kImageViewM, scrollView.frame.origin.y, KSCREENWIDTH, CGRectGetHeight(scrollView.frame))];
    }
}

//定位到删除照片的前一张
- (void)gotoLastImage
{
    if (self.currentIndex > 0)
    {
        self.currentIndex = self.currentIndex - 1;
    }
}

//定位到删除照片的后一张
- (void)gotoNextImage
{
    if (self.currentIndex >= self.photoArray.count)
    {
        self.currentIndex = self.photoArray.count - 1;
    }
}

- (void)updateOffsetAfterDeleteImage
{
    self.index = self.currentIndex;
    self.pageControl.numberOfPages = self.photoArray.count;
    self.pageControl.currentPage = self.index;
    self.photoScroll.contentSize = CGSizeMake((CGRectGetWidth(self.photoScroll.frame)) * self.photoArray.count, CGRectGetHeight(self.photoScroll.frame) - 64 - 49);
    [self.photoScroll setContentOffset:CGPointMake(self.index * CGRectGetWidth(self.photoScroll.frame), 0) animated:NO];
}


- (void)updateTitleLabel
{
    if (self.isSendDynamic)
    {
        self.titleLabel.text = [NSString stringWithFormat:@"%li/%lu",(self.currentIndex + 1),(unsigned long)self.photoArray.count];
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
            [self updateTitleLabel];
            
        }else if (page < self.currentIndex && page >= 0) {
            
            self.currentIndex = page;
            self.pageControl.currentPage = self.currentIndex;

            [self scrollToPreviousPage];
            [self updateTitleLabel];
        }
    }
}

#pragma mark - 赋值
- (void)updateCurrentImage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIScrollView *currentScroll = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentScroll photo:self.photoArray[index] placeholder:nil];
    }
    
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex < self.photoArray.count) {
        UIScrollView *nextScroll = self.photoScroll.subviews[nextIndex];
        [self setImageWithScrollView:nextScroll photo:self.photoArray[nextIndex] placeholder:nil];
    }
    
    NSInteger previousIndex = self.currentIndex - 1;
    if (previousIndex < self.photoArray.count) {
        UIScrollView *previousScroll = self.photoScroll.subviews[previousIndex];
        [self setImageWithScrollView:previousScroll photo:self.photoArray[previousIndex] placeholder:nil];
    }
}

- (void)scrollToNextPage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIScrollView *currentScroll = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentScroll photo:self.photoArray[index] placeholder:nil];
    }
    
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex < self.photoArray.count) {
        UIScrollView *nextScroll = self.photoScroll.subviews[nextIndex];
        [self setImageWithScrollView:nextScroll photo:self.photoArray[nextIndex] placeholder:nil];
    }
    self.scrollDirection = ScrollDirectionRight;
}

- (void)scrollToPreviousPage
{
    NSInteger index = self.currentIndex;
    if (index < self.photoArray.count) {
        UIScrollView *currentScroll = self.photoScroll.subviews[index];
        [self setImageWithScrollView:currentScroll photo:self.photoArray[index] placeholder:nil];
    }
    
    NSInteger previousIndex = self.currentIndex - 1;
    if (previousIndex < self.photoArray.count) {
        UIScrollView *previousScroll = self.photoScroll.subviews[previousIndex];
        [self setImageWithScrollView:previousScroll photo:self.photoArray[previousIndex] placeholder:nil];
    }
    self.scrollDirection = ScrollDirectionLeft;
}

- (void)setImageWithScrollView:(UIScrollView *)scrollView photo:(NSString *)photo placeholder:(NSString *)placeholder
{
    UIImageView *imageView = (UIImageView *)scrollView.subviews.firstObject;
    
    if (photo == nil) {
        imageView.image = nil;
        return;
    }
    
    NSString *loadResult = [self.loadImageDic objectForKeyYC:photo];
    if ([loadResult isEqualToString:kLoadSucceed]) {
        self.canScale = YES;
        return;
    }
    
    self.canScale = NO;
    
    photo = [YCPicProcessHelper resizePath:photo
                                     withW:nil
                                      andH:nil
                                cropCenter:NO
                                   andWebp:YES];
    [imageView sd_setImageWithURL:[NSURL URLWithString:photo] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        if (image == nil) { //图片失败了
            
            self.canScale = NO;
            imageView.contentMode = UIViewContentModeCenter;
            
            scrollView.maximumZoomScale = 1.0;
            imageView.image = [UIImage imageNamed:@"chat_pic_loadfailed"];
            
        }else {
            
            self.canScale = YES;
            imageView.contentMode = UIViewContentModeScaleToFill;
            
            scrollView.maximumZoomScale = 4.0;
            [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
            
            CGFloat tmpHeight = KSCREENWIDTH*image.size.height / image.size.width;
            imageView.frame = CGRectMake(0, 0, KSCREENWIDTH, tmpHeight);

            if (tmpHeight <= CGRectGetHeight(self.photoScroll.frame)) {
                imageView.center = CGPointMake(imageView.center.x, scrollView.frame.size.height / 2);
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
  
//    [self dismissViewControllerAnimated:NO completion:^{
//        
//    }];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return (UIImageView *)scrollView.subviews.firstObject;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIImageView *imageView = (UIImageView *)scrollView.subviews.firstObject;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                         scrollView.contentSize.height * 0.5 + offsetY);
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"%s", __FUNCTION__);
    
    @try {
        
        if ([YCUserInfoShared shared].isAnimating) {
            return NO;
        }
        
        if (otherGestureRecognizer.state != UIGestureRecognizerStateBegan) {
            return YES;
        }
        
        if ([gestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)gestureRecognizer.view;
          
            
            if (scrollView.contentOffset.x <= 0) {
                
                if (self.currentIndex == 0)
                {
                    UIScrollView *currentScroll = self.photoScroll.subviews[self.currentIndex];
                    if (currentScroll.contentOffset.x <= 0)
                    {
                        return YES;
                    }
                }

            }
        }
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    return NO;
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
        
//        [self dismissMultiplePhotoShow];
        
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
        [self presentViewController:self.savePhotoAlertController animated:YES completion:^{
            
        }];
    }else {
        if (self.actionSheetSavePhoto == nil) {
            self.actionSheetSavePhoto = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存", nil];
        }
        [self.actionSheetSavePhoto showFromTabBar:self.tabBarController.tabBar];
    }
    
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.actionSheetSavePhoto) {
        if (buttonIndex == 0) {
            [self actionSheetPhoto];
        }
    }else {
        if (buttonIndex == 0) {
            [self deleteEnsure];
        }
    }
}

- (void)actionSheetPhoto
{
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == AVAuthorizationStatusDenied){
        [self showAuthorityAlertViewWithType:AuthorityTypePhoto];
    }else if(author == AVAuthorizationStatusAuthorized){
        UIImageWriteToSavedPhotosAlbum(self.saveImageView.image, nil, nil, nil);
        [self addBDKNotifyHUDWithImage:nil text:@"保存成功"];
    }else if (author == AVAuthorizationStatusNotDetermined){
        if (IS_IOS8) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (status == PHAuthorizationStatusAuthorized) {
                        UIImageWriteToSavedPhotosAlbum(self.saveImageView.image, nil, nil, nil);
                        [self addBDKNotifyHUDWithImage:nil text:@"保存成功"];                    }
                });
            }];
        }
    }
}

- (NSMutableDictionary *)loadImageDic
{
    if (_loadImageDic == nil) {
        _loadImageDic = [NSMutableDictionary new];
    }
    return _loadImageDic;
}

- (void)dealloc
{
    [self closeCustomView];
}

- (void)closeCustomView
{
    if (IS_IOS8) {
        [self.savePhotoAlertController dismissViewControllerAnimated:YES completion:^{}];
        self.savePhotoAlertController = nil;
    }else {
        [self.actionSheetSavePhoto dismissWithClickedButtonIndex:0 animated:NO];
        self.actionSheetSavePhoto.delegate = nil;
        self.actionSheetSavePhoto = nil;
    }
    
    if (IS_IOS8) {
        [self.deleteAlertController dismissViewControllerAnimated:YES completion:^{}];
        self.deleteAlertController = nil;
    }else {
        [self.actionSheetDelete dismissWithClickedButtonIndex:0 animated:NO];
        self.actionSheetDelete.delegate = nil;
        self.actionSheetDelete = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
