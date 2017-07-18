//
//  YCVideoShowViewController.m
//   
//
//  Created by  yc on 2017/7/4.
//  Copyright © 2017年  yc. All rights reserved.
//

#import "YCVideoShowViewController.h"

@interface YCVideoShowViewController ()<UIActionSheetDelegate>
@property (strong, nonatomic) UIView *navigationView;
@property (strong, nonatomic) UIImageView *navigationBackImage;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *leftBarButton;
@property (strong, nonatomic) UIButton *rightBarButton;


@property (strong, nonatomic) UIActionSheet *actionSheetDelete;
@property (strong, nonatomic) UIAlertController *deleteAlertController;


@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@end

@implementation YCVideoShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addPanGestureOnView:self.view needDelegate:YES];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    NSURL *url =[NSURL fileURLWithPath:self.movieURL];
    
    self.playerItem = [[AVPlayerItem alloc] initWithURL:url];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.view addSubview:self.preview];
    [self addCustomNavigation];
    [self addNotification];
    [self addPlayerLayer];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.player play];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.player pause];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc{
    [self.player pause];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];

    
}

- (void)addCustomNavigation
{
    [self addNavigationView];
    [self addNavigationBackImage];
//    [self addTitleLabel];
    [self addLeftBarButton];
    [self addRightBarButton];
}

- (void)addNavigationView
{
    _navigationView = [[UIView alloc]init];
    [self.view addSubview:_navigationView];
    
    [_navigationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.right.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(KSCREENWIDTH, kNavigationHeight+20));
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
    _titleLabel.text= @"1/1";
    [self.navigationView addSubview:_titleLabel];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.centerX.mas_equalTo(0);
        make.center.centerY.mas_equalTo(30);

    }];
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
        make.centerY.mas_equalTo(10);
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
        make.centerY.mas_equalTo(10);
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
        
        self.deleteAlertController = [UIAlertController alertControllerWithTitle:kVideoShow_deleteTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        NSAttributedString *editSelectedAttri = [[NSAttributedString alloc] initWithString:kVideoShow_deleteTitle attributes:@{NSFontAttributeName:kTitleFontAleartController, NSForegroundColorAttributeName:kTitleColorAleartController,NSBaselineOffsetAttributeName:[NSNumber numberWithInt:kTitlBaselineOffsetAleartController]}];
        
        [self.deleteAlertController setValue:editSelectedAttri forKey:@"_attributedTitle"];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:kVideoShow_deleteCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *otherAction1 = [UIAlertAction actionWithTitle:kVideoShow_deleteEnsure style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteEnsure];
        }];
        [self.deleteAlertController addAction:cancelAction];
        [self.deleteAlertController addAction:otherAction1];
        [self presentViewController:self.deleteAlertController animated:YES completion:^{
            
        }];
    }else {
        
        if (self.actionSheetDelete == nil) {
            self.actionSheetDelete = [[UIActionSheet alloc]initWithTitle:kVideoShow_deleteTitle delegate:self cancelButtonTitle:kVideoShow_deleteCancel destructiveButtonTitle:nil otherButtonTitles:kVideoShow_deleteEnsure, nil];
        }
        [self.actionSheetDelete showFromTabBar:self.tabBarController.tabBar];
    }
}
#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    if (actionSheet == self.actionSheetSavePhoto) {
//        if (buttonIndex == 0) {
//            [self actionSheetPhoto];
//        }
////    }else {
        if (buttonIndex == 0) {
            [self deleteEnsure];
        }
//    }
}

- (void)dismissMultiplePhotoShow
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)deleteEnsure
{
    [self updateSendView];
    [self dismissMultiplePhotoShow];

}
- (void)updateSendView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeVideo)]) {
        [self.delegate removeVideo];
    }}

-(void)addPlayerLayer{

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    playerLayer.frame = self.preview.bounds;
    playerLayer.videoGravity=AVLayerVideoGravityResizeAspect;
    [self.preview.layer addSublayer:playerLayer];
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
//    [self.player play];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        CMTime duration = self.playerItem.duration;
        NSLog(@"%lld",duration.value);
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");
            [self.player play];
        } else{
            NSLog(@"load break");
        }
    }
}

-(UIImage *)firstFrameWithVideoURL:(NSURL *)url{
    NSDictionary *options = [NSDictionary dictionaryWithObject:@0 forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:options];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeZero;
    CGImageRef image = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:NULL error:nil];
    return [UIImage imageWithCGImage:image];
}
#pragma mark -
#pragma mark --

/**
 *  添加播放器通知
 */
-(void)addNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dealWithVideoChatisShowing:)
                                                 name:YC_VideoChatisShowing
                                               object:nil];
}
-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)didBecomeActive{
    [self.player play];
}
- (void)willResignActive{
    [self.player pause];
}
- (void)dealWithVideoChatisShowing:(NSNotification *)notify
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.player pause];
    [self dismissMultiplePhotoShow];
}
/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player play];
    }

}

-(UIView *)preview{
    if (!_preview) {
        _preview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, KSCREENWIDTH, KSCREENHEIGHT)];
        _preview.backgroundColor = [UIColor blackColor];
        _preview.layer.backgroundColor = [UIColor blackColor].CGColor;
    }
    return _preview;
}
@end
