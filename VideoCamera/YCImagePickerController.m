//
//  YCImagePickerController.m
//   
//
//  Created by  yc on 2017/6/26.
//  Copyright © 2017年  yc. All rights reserved.
//

#import "YCImagePickerController.h"
#import "GPUImage.h"
#import "GPUImageBeautyFilter.h"
#import "GPUImageEmptyFilter.h"
#import "YCShootButton.h"
#import <CoreMotion/CoreMotion.h>
#import "UIImage+ImageEffects.h"
#import <VideoToolbox/VideoToolbox.h>
#include <sys/types.h>
#include <sys/sysctl.h>

typedef NS_ENUM(NSInteger, YCCameraSatus) {
    YCCameraStatusUnknown,        //
    YCCameraSatusRanning,         //拍摄中
    YCCameraSatusOutputImage,     //拍摄完成，输出图片
    YCCameraSatusOutputVideo,     //拍摄完成，输出视频
};


//TODO:视频开头裁减掉时间，首帧黑屏问题，应该是视频帧没开始写入的时候音频已经开始写了。就会黑屏，有人建议我音视频分开录，然后再合成，无奈项目急。先这么解决了。
CGFloat cropOutTime = 0.2;


@interface YCImagePickerController ()<CAAnimationDelegate,UIGestureRecognizerDelegate,GPUImageVideoCameraDelegate,YCShootButtonDelegate>
{
    NSURL *_movieURL;
    AVPlayerItem *_playerItem;
    
}
@property (nonatomic, strong) GPUImageFilter *filter;
@property (nonatomic, strong) GPUImageStillCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterImageView;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) UIImage *image;
/** 拍摄按钮 */
@property (strong, nonatomic) YCShootButton *shootButton;
/** 翻转摄像头按钮 */
@property (strong, nonatomic) UIButton *transcribeButton;
/** 完成按钮 */
@property (strong, nonatomic) UIButton *finishButton;
/** 重新拍摄按钮 */
@property (strong, nonatomic) UIButton *rephotofraphButton;
/** 返回按钮 */
@property (strong, nonatomic) UIButton *dismissButton;
/** 视频预览view */
@property (nonatomic, strong) UIView *preview;
/** 视频预览layer */
@property (nonatomic, strong) AVPlayer *player;
/** 拍照预览view */
@property (nonatomic, strong) UIImageView *preImageView;
/** 聚焦层 */
@property (nonatomic, strong) CALayer *focusLayer;

@property (nonatomic, strong) CMMotionManager * motionManager;
/** 是否是录制视频 */
@property (nonatomic, assign) YCCameraSatus cameraStatus;
/** 是否是iPhone5以前，iPad4以前设备 */
@property (nonatomic, assign) BOOL isOldDevice;
@property (nonatomic, assign) YCCameraType cameraType;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
/** 开始的缩放比例 */
@property (nonatomic , assign) CGFloat beginGestureScale;
/** 最后的缩放比例 */
@property (nonatomic , assign) CGFloat effectiveScale;

@end

@implementation YCImagePickerController

-(instancetype)initWithType:(YCCameraType)cameraType{
    self = [super init];
    if (self) {
        self.cameraType = cameraType;
        self.isOldDevice = [self equipmentlow];

        if (self.cameraType != YCCameraTypeStillCamera) {
            
            NSDate *date = [NSDate date];
            NSString *videoPath = [NSString stringWithFormat:@"output%llu",(long long)([date timeIntervalSince1970] * 1000)];
            
            
            NSString * path =             [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/dynamicVideo/"];
            BOOL isDir =NO;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
            if ( !(isDir ==YES && existed == YES) ){//如果没有文件夹则创建
                [fileManager createDirectoryAtPath:path withIntermediateDirectories:isDir attributes:nil error:nil];
            }
            NSString * pathToMovie = [path stringByAppendingFormat:@"%@.mp4",videoPath];
            _movieURL = [NSURL fileURLWithPath:pathToMovie];
        }
    }

    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initVideoCamera];
    if (self.cameraType != YCCameraTypeStillCamera) {
        self.movieWriter = [self creatMovieWriter];
        [self.filter addTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
    }
    [self addSubViews];
    [self addNotification];
    if (self.motionManager.accelerometerAvailable) {
        [self.motionManager startAccelerometerUpdates];
//翻转摄像头按钮随手机翻转自动翻转。在低端机上有点影响性能，
//        NSOperationQueue *queue = [NSOperationQueue mainQueue];
//        __weak typeof(self) weakSelf = self;
//        [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
//            if (error) {
//                [weakSelf.motionManager stopAccelerometerUpdates];
//            }else{
//                CMAcceleration ration = accelerometerData.acceleration;
//                
//                UIDeviceOrientation deviceOrientation = [self deviceOrientationWith:ration];
//                if (deviceOrientation != UIDeviceOrientationUnknown && deviceOrientation != weakSelf.deviceOrientation) {
//                    weakSelf.deviceOrientation = deviceOrientation;
//                    CGAffineTransform transform = CGAffineTransformMakeRotation(-[weakSelf rotateAngleDisplayWith:weakSelf.deviceOrientation]);
//                    [UIView animateWithDuration:0.2 animations:^{
//                        weakSelf.transcribeButton.transform =transform;
//                    }];
//
//                }
//            }
//        }];
    }else{
        NSLog(@"该设备不支持获取加速度数据！");
    }
    [self addGestureRecognizers];
    [self.filterImageView.layer addSublayer:self.focusLayer];
//    NSLog(@"YCImagePickerController4");
//TODO:这里本来想解决调起相机，没录制的时候点击home键上方显示红条问题。但是这样处理音频就没了。又看了看GPUImageVideoCamera里面的代码。发现addAudioInputsAndOutputs里面AVCaptureDeviceInput不添加就没红条。但是开始录制的时候添加屏幕会闪下，还没有好多方法，谁有方法欢迎指导
//    [[AVAudioSession sharedInstance]setActive:NO error:nil];


}

-(void)dealloc{
    [self.motionManager stopAccelerometerUpdates];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

//    NSLog(@"YCImagePickerController5");

}
-(void)addGestureRecognizers{
    //聚焦
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusWithTap:)];
    [self.filterImageView addGestureRecognizer:tap];
    //调整焦距
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(focusDisdance:)];
    [self.filterImageView addGestureRecognizer:pinch];
    pinch.delegate = self;
}

-(void)addPlayer{
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
    }
     _playerItem = [[AVPlayerItem alloc] initWithURL:_movieURL];
    
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    playerLayer.frame = self.preview.bounds;
    playerLayer.videoGravity=AVLayerVideoGravityResizeAspect;
    [self.preview.layer addSublayer:playerLayer];
}
-(void)addSubViews{
    [self.view addSubview:self.preview];
    [self.view addSubview:self.preImageView];
    [self.view addSubview:self.finishButton];
    [self.view addSubview:self.rephotofraphButton];
    [self.view addSubview:self.shootButton];
    [self.view addSubview:self.transcribeButton];
    [self.view addSubview:self.dismissButton];
}
-(void)initVideoCamera{
    _filterImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//在3.5寸屏上本来要截取两边黑边后来参考微信，修改了AVCaptureSessionPreset，截取上下
//    float height = ((1080 / KSCREENWIDTH) * KSCREENHEIGHT);
    //CGRect frame = CGRectMake(0, (1920 - height)/2/1920, 1,height/1920);
    if (self.isOldDevice) {
        float width =((640 / KSCREENHEIGHT) * KSCREENWIDTH);
        CGRect frame = CGRectMake((480-width)/2/480, 0, width/480, 1);
        GPUImageCropFilter * cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:frame];
        [self.videoCamera addTarget:cropFilter];
        [cropFilter addTarget:self.filter];

    }else{
        [self.videoCamera addTarget:self.filter];
    }
    [self.view addSubview:self.filterImageView];
    [self.view insertSubview:self.filterImageView atIndex:0];
    [self.filter addTarget:self.filterImageView];
    [self.videoCamera startCameraCapture];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    

}
-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

//本来打算切换前后台的时候暂停camera，或者停掉AVPlayer，后来参考微信，推掉后台或挂起直接dismiss
- (void)didBecomeActive{
//    if (self.cameraStatus == YCCameraSatusOutputVideo) {
//        [self.player play];
//    }else if (self.cameraStatus == YCCameraSatusRanning){
//        [self.videoCamera startCameraCapture];
//    }
//    
}
- (void)willResignActive{
    [[AVAudioSession sharedInstance]setActive:NO error:nil];

    [[NSFileManager defaultManager] removeItemAtURL:_movieURL error:nil];
    [self.videoCamera stopCameraCapture];
    [self dismissViewController];
//    if (self.cameraStatus == YCCameraSatusOutputVideo) {
//        [self.player pause];
//    }else if (self.cameraStatus == YCCameraSatusRanning){
//        [self.videoCamera stopCameraCapture];
//    }
}

#pragma mark -
#pragma mark -- kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");
            //最好在这里开启播放，但不知道会不会有其他问题，懒得看了
//            [self.player play];
        } else{
            [self rephotographButtonClick:nil];
            NSLog(@"load break");
        }
    }
}

#pragma mark -
#pragma mark -- YCShootButtonDelegate
-(BOOL)tapGestureRecognizer{
    self.dismissButton.hidden = YES;
    self.transcribeButton.hidden = YES;
    //获取加速器数据判断方向用
    CMAcceleration ration = self.motionManager.accelerometerData.acceleration;
    UIDeviceOrientation deviceOrientation = [self deviceOrientationWith:ration];
    UIImageOrientation imageOrientation = [self imageOrientationWithDeviceOrientation:deviceOrientation];
    self.cameraStatus = YCCameraSatusOutputImage;
    __weak typeof(self) weakSelf = self;
    
    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:self.filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        if(error){
            NSLog(@"抛出异常");
            
            return;
        }
        [weakSelf.videoCamera stopCameraCapture];
        [weakSelf finishRecodAnimation];
        weakSelf.image = [processedImage rotate:imageOrientation];
        weakSelf.preImageView.hidden = NO;
        weakSelf.preImageView.image = weakSelf.image;
    }];
    return  YES;
}
-(void)LongPressGestureRecognizerStateBegan{
    self.dismissButton.hidden = YES;
    if (!_movieWriter) {
        for (id<GPUImageInput> obj in self.filter.targets) {
            if ([obj isKindOfClass:[GPUImageMovieWriter class]]) {
                [self.filter removeTarget:obj];//1
            }
        }
        self.movieWriter = [self creatMovieWriter];
        [self.filter addTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = self.movieWriter;

    }
    CMAcceleration ration = self.motionManager.accelerometerData.acceleration;
    UIDeviceOrientation deviceOrientation = [self deviceOrientationWith:ration];
    CGFloat angle = 0;
    angle = [self rotateAngleDisplayWith:deviceOrientation];
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    [self.movieWriter startRecordingInOrientation:transform];
}
-(void)LongPressGestureRecognizerStateEnded{
    [self.movieWriter finishRecording];
    [self finishRecodAnimation];
    CMTime time = self.movieWriter.duration;
    if (time.value/time.timescale<0.5) {
        NSLog(@"时间不够，截取一张,或者给个提示都行");
        __weak typeof(self) weakSelf = self;
        UIImageOrientation imageOrientation = [self imageOrientationWithDeviceOrientation:self.deviceOrientation];

        [self.videoCamera capturePhotoAsImageProcessedUpToFilter:self.filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
            if(error){
                NSLog(@"抛出异常");
                [weakSelf startRecodAnimation];
                self.dismissButton.hidden = NO;
                return;
            }
            [weakSelf.videoCamera stopCameraCapture];

            weakSelf.image = [processedImage rotate:imageOrientation];
            weakSelf.preImageView.hidden = NO;
            weakSelf.preImageView.image = weakSelf.image;
            weakSelf.image = processedImage ;
            weakSelf.cameraStatus = YCCameraSatusOutputImage;
        }];
    }else{
        [self.videoCamera stopCameraCapture];

        self.cameraStatus = YCCameraSatusOutputVideo;
        self.preview.hidden = NO;
        [self addPlayer];
        [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        self.transcribeButton.hidden = YES;
    }
}
#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 在这里做人脸的检测
//    CVImageBufferRef image = CMSampleBufferGetImageBuffer(sampleBuffer);
//    
//    CGSize displaySize = CVImageBufferGetDisplaySize(image);
//    CGSize encodeSize = CVImageBufferGetEncodedSize(image);
//    NSLog(@"displaySize %f %f    decodeSize %f %f",displaySize.width,displaySize.height,encodeSize.width,encodeSize.height);
//
}

#pragma mark -
#pragma mark -- button

- (void)rephotographButtonClick:(UIButton *)sender {
    self.beginGestureScale = 1.0f;
    self.effectiveScale = 1.0f;
    NSError *error;
    if([self.videoCamera.inputCamera lockForConfiguration:&error]){
        [self.videoCamera.inputCamera setVideoZoomFactor:self.effectiveScale];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog(@"ERROR = %@", error);
    }
    
    self.preview.hidden = YES;
    [self.player pause];
    self.preImageView.hidden = YES;
    self.transcribeButton.hidden = NO;
    self.cameraStatus = YCCameraSatusRanning;
    
    //按钮动画
    [self startRecodAnimation];
    [[NSFileManager defaultManager] removeItemAtURL:_movieURL error:nil];//2
    if (_movieWriter){
        for (id<GPUImageInput> obj in self.filter.targets) {
            if ([obj isKindOfClass:[GPUImageMovieWriter class]]) {
                [self.filter removeTarget:obj];//1
            }
        }
        self.movieWriter = [self creatMovieWriter];
        [self.filter addTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
    }
    [self.videoCamera startCameraCapture];
    [[AVAudioSession sharedInstance]setActive:NO error:nil];

    self.dismissButton.hidden = NO;

}
- (void)finishButtonClick:(UIButton *)sender {
    sender.userInteractionEnabled = NO;

    if (self.cameraStatus == YCCameraSatusOutputImage) {
        //存入本地相册
        if (self.delegate && [self.delegate respondsToSelector:@selector(finishWithImage:)]) {
            [self.delegate finishWithImage:self.image];
        }
        [self dismissViewController];
        
    }else{
        
//        self.preview.hidden = YES;
        [self.player pause];
        [self compressAndExportVideosAtFileURL:_movieURL];
    }
}

- (void)transcribeClick:(UIButton *)sender {
    [self.videoCamera stopCameraCapture];
    self.beginGestureScale = 1.0f;
    self.effectiveScale = 1.0f;
    [self.videoCamera rotateCamera];
    [self.videoCamera startCameraCapture];
    [[AVAudioSession sharedInstance]setActive:NO error:nil];

    
}
-(void)dismissButtonClick{
    [self dismissViewController];
}
-(void)dismissViewController{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
#pragma mark -
#pragma mark -- 按钮动画
-(void)startRecodAnimation{
    self.shootButton.hidden = NO;
    self.rephotofraphButton.hidden = YES;
    self.finishButton.hidden = YES;
    CGPoint center = self.shootButton.center;
    self.rephotofraphButton.center = center;
    self.finishButton.center = center;
}
-(void)finishRecodAnimation{
    self.shootButton.hidden = YES;
    self.rephotofraphButton.hidden = NO;
    self.finishButton.hidden = NO;
    CGPoint center = self.shootButton.center;
    [UIView animateWithDuration:0.1 animations:^{
        self.rephotofraphButton.center = CGPointMake((KSCREENWIDTH *0.25), center.y);
        self.finishButton.center = CGPointMake((KSCREENWIDTH *0.75), center.y);
    }completion:^(BOOL finished) {
        
    }];
}

#pragma mark -
#pragma mark -- private method
//TODO:这个坑，AVAssetWriter重复录制要重新初始化，项目里还有其他地方用到GPUImage，所以能不动里面代码就不动
-(GPUImageMovieWriter *)creatMovieWriter{
    int width = KSCREENWIDTH, height = KSCREENHEIGHT;
    //TODO:这里有个坑，iPhone6尺寸为375，667，size为奇数的时候会有绿边
    if (width %2 ==1) {
        width +=1;
    }
    if (height%2 == 1) {
        height +=1;
    }
    GPUImageMovieWriter * movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(width, height)];
    //实时压缩
    movieWriter.encodingLiveVideo = YES;
    movieWriter.shouldPassthroughAudio = YES;
    return movieWriter;
    
}

/**
 根据CMAcceleration 判断设备方向

 @param ration CMAcceleration
 @return 设备方向
 */
-(UIDeviceOrientation)deviceOrientationWith:(CMAcceleration)ration{
    if (fabs(ration.y) - fabs(ration.x) >= 0.4) {
        if (ration.y > 0) {
            return UIDeviceOrientationPortraitUpsideDown;
        }
        return UIDeviceOrientationPortrait;
    }else if (fabs(ration.y) - fabs(ration.x) <= -0.4){
        if (ration.x >0) {
            return UIDeviceOrientationLandscapeRight;
        }
        return UIDeviceOrientationLandscapeLeft;
    }
    return UIDeviceOrientationUnknown;
}

/**
 根据设备方向返回翻转角度

 @param deviceOrientation 设备方向
 @return 翻转角度
 */
-(CGFloat)rotateAngleDisplayWith:(UIDeviceOrientation)deviceOrientation{
    CGFloat angle = 0;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            angle= 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle= 0;
            break;
    }
    return angle;
}

/**
 根据设备方向返回图片方向

 @param deviceOrientation 设备方向
 @return 。。。
 */
-(UIImageOrientation)imageOrientationWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            imageOrientation= UIImageOrientationUp;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            imageOrientation = UIImageOrientationDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            imageOrientation = UIImageOrientationRight;
            break;
        default:
            imageOrientation= UIImageOrientationUp;
            break;
    }
    return imageOrientation;
}

/**
 根据CGAffineTransform 判断方向

 @param affineTransform 视频Transform
 @return 录制时设备方向
 */
-(UIDeviceOrientation )DeviceOrientationWithAffineTransform:(CGAffineTransform)affineTransform{
    int transformA = affineTransform.a ,transformB = affineTransform.b;
    if (transformA ==0) {
        if (transformB == -1) {
            return UIDeviceOrientationLandscapeLeft;
        }else{
            return UIDeviceOrientationLandscapeRight;
        }
    }
    if (transformB ==0) {
        if (transformA == -1) {
            return UIDeviceOrientationPortraitUpsideDown;
        }else{
            return UIDeviceOrientationPortrait;
        }
    }
    return UIDeviceOrientationPortrait;

}

/**
 裁剪压缩视频

 @param fileURL 视频地址
 */
- (void)compressAndExportVideosAtFileURL:(NSURL *)fileURL
{
    NSError *error = nil;
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    CMTime totalDuration = kCMTimeZero;
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    AVAssetTrack *assetTrack;
    if (!asset) {
        return;
    }
    NSArray *assetArray = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetArray.count > 0){
        assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *trackArray = [asset tracksWithMediaType:AVMediaTypeAudio];
    //开头剪掉0.2秒
    CMTime startTime = CMTimeMake(asset.duration.timescale *cropOutTime, asset.duration.timescale);
    CMTime endTime = CMTimeMake(asset.duration.value-asset.duration.timescale *cropOutTime, asset.duration.timescale);
    if (trackArray.count > 0){
        
        [audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                            ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                             atTime:totalDuration
                              error:&error];
        
    }
    NSLog(@"裁剪压缩视频:%@",error.userInfo);
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                        ofTrack:assetTrack
                         atTime:totalDuration
                          error:&error];
    NSLog(@"裁剪压缩视频:%@",error.userInfo);

    //fix orientationissue
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    totalDuration = CMTimeAdd(totalDuration, asset.duration);
    //这里直接用assetTrack.preferredTransform有问题，需要设置tx,ty,虽然解决了但是感觉我这么处理有问题，如果有人了解，欢迎指点一下。
    CGAffineTransform layerTransform;
    UIDeviceOrientation deviceOrientation = [self DeviceOrientationWithAffineTransform:assetTrack.preferredTransform];
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            layerTransform = CGAffineTransformTranslate(assetTrack.preferredTransform, 0, 0);
            break;
        case UIDeviceOrientationLandscapeRight:
            layerTransform = CGAffineTransformTranslate(assetTrack.preferredTransform, 0, -KSCREENHEIGHT);
            break;
        case UIDeviceOrientationLandscapeLeft:
            layerTransform = CGAffineTransformTranslate(assetTrack.preferredTransform, -KSCREENWIDTH, 0);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            layerTransform = CGAffineTransformTranslate(assetTrack.preferredTransform, -KSCREENWIDTH, -KSCREENHEIGHT);
            break;
        default:
            layerTransform = CGAffineTransformTranslate(assetTrack.preferredTransform, 0, 0);
            break;
    }
    
    [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:totalDuration];
    //data
    [layerInstructionArray addObject:layerInstruciton];
    
    //get save path
    
    NSDate *date = [NSDate date];
    NSString *videoPath = [NSString stringWithFormat:@"output%llu",(long long)([date timeIntervalSince1970] * 1000)];
    
    NSString * path =             [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/Videos/"];
    BOOL isDir =NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if ( !(isDir ==YES && existed == YES) ){//如果没有文件夹则创建
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:isDir attributes:nil error:nil];
    }
    NSString * pathToMovie = [path stringByAppendingFormat:@"%@.mp4",videoPath];
    
    NSURL *mergeFileURL = [NSURL fileURLWithPath:pathToMovie];
    //export
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    CGSize renderSize = CGSizeMake(0, 0);
    int width = KSCREENWIDTH, height = KSCREENHEIGHT;
    if (width %2 ==1) {
        width +=1;
    }
    if (height%2 == 1) {
        height +=1;
    }
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight) {
        renderSize = CGSizeMake(height,width);
    }else{
        renderSize = CGSizeMake(width, height);
    }

    mainCompositionInst.renderSize = renderSize;
//TODO:个人感觉还是大10s视频4M左右。修改AVAssetExportPresetHighestQuality能压缩更多。但画质不行了。项目其他地方还用到了GPUimage，所以里面的参数也不好乱改。。
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(finishWithVideoURL:)]) {
                [self.delegate finishWithVideoURL:mergeFileURL];
                [[NSFileManager defaultManager] removeItemAtURL:_movieURL error:nil];//2
            }
            NSLog(@"裁剪压缩视前:%@  后:%@",_movieURL,mergeFileURL);

            [self dismissViewController];

        });
    }];
    
}

/**
 判断设备是否太旧

 @return 4s一下。iPad几记不清 了
 */
-(BOOL)equipmentlow{
    NSString *mobileType = [self getMobileType];
    if ([mobileType rangeOfString:@"iPhone"].location != NSNotFound) {
        int n = [[mobileType substringWithRange:NSMakeRange(6, 1)] intValue];
        if (n < 5) {
            return YES;
        }
    }else if ([mobileType rangeOfString:@"iPad"].location != NSNotFound){
        int n = [[mobileType substringWithRange:NSMakeRange(4, 1)] intValue];
        if (n < 4) {
            return YES;
        }
    }
    return NO;
}
-(NSString *)getMobileType
{
    size_t size;
    // get the length of machine name
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    // get machine name
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithFormat:@"%s", machine];
    free(machine);
    
    return platform;
}
#pragma mark -
#pragma mark -- 对焦
- (void)focusWithTap:(UITapGestureRecognizer *)tap {
    if (!self.focusLayer.hidden) {
        return;
    }
    CGPoint touchPoint = [tap locationInView:tap.view];
    [self layerAnimationWithPoint:touchPoint];
    
    if(self.videoCamera.cameraPosition == AVCaptureDevicePositionBack){
        touchPoint = CGPointMake( touchPoint.y /tap.view.bounds.size.height ,1-touchPoint.x/tap.view.bounds.size.width);
    }else{
        touchPoint = CGPointMake(touchPoint.y /tap.view.bounds.size.height ,touchPoint.x/tap.view.bounds.size.width);
    }
    
    if([self.videoCamera.inputCamera isExposurePointOfInterestSupported] && [self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
    {
        NSError *error;
        if ([self.videoCamera.inputCamera lockForConfiguration:&error]) {
//调整曝光感觉有点不平滑。参考微信干脆去掉算了。
//            [self.videoCamera.inputCamera setExposurePointOfInterest:touchPoint];
//            [self.videoCamera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            if ([self.videoCamera.inputCamera isFocusPointOfInterestSupported] && [self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [self.videoCamera.inputCamera setFocusPointOfInterest:touchPoint];
                [self.videoCamera.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            [self.videoCamera.inputCamera unlockForConfiguration];
        } else {
            NSLog(@"ERROR = %@", error);
        }
    }
}

//对焦动画
- (void)layerAnimationWithPoint:(CGPoint)point {
    ///聚焦点聚焦动画设置
    self.focusLayer.hidden = NO;
    CALayer *layer = self.focusLayer;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [layer setPosition:point];
    layer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
    [CATransaction commit];
    
    CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
    animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
//TODO:CABasicAnimation的delegate事strong属性，惊不惊喜。。延迟一会hidden也行
//    animation.delegate = self;
    animation.duration = 0.2f;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [layer addAnimation: animation forKey:@"animation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.focusLayer.hidden = YES;

    });
}
//动画的delegate方法
//- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
//    // 0.5秒钟延时
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.focusLayer.hidden = YES;
//        
//    });
//}
#pragma mark -
#pragma mark -- 调整焦距
-(void)focusDisdance:(UIPinchGestureRecognizer*)pinch {
    self.effectiveScale = self.beginGestureScale * pinch.scale;
    if (self.effectiveScale < 1.0f) {
        self.effectiveScale = 1.0f;
    }
    //设置最大放大倍数为5倍
    CGFloat maxScaleAndCropFactor = 5.0f;
    if (self.effectiveScale > maxScaleAndCropFactor)
        self.effectiveScale = maxScaleAndCropFactor;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    NSError *error;
    if([self.videoCamera.inputCamera lockForConfiguration:&error]){
        [self.videoCamera.inputCamera setVideoZoomFactor:self.effectiveScale];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog(@"ERROR = %@", error);
    }
    
    [CATransaction commit];
}

//手势代理方法
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}




#pragma mark -
#pragma mark -- set && get

-(GPUImageFilter *)filter{
    if (!_filter) {
        if ([self equipmentlow] || !IS_IOS8) {
            _filter = [[GPUImageFilter alloc]init];

        }else{
            _filter = [[GPUImageBeautyFilter alloc]init];
            //这个滤镜是从一个开源直播框架里搞来的。效果也不理想。但勉强能用，本来打算用GPUImageplus里面的美颜滤镜，也转成oc的了。但发现效果也不理想，滤镜以后还要好好研究研究。
            ((GPUImageBeautyFilter *)_filter).toneLevel =0.15;
            ((GPUImageBeautyFilter *)_filter).brightLevel =0.43;
            ((GPUImageBeautyFilter *)_filter).beautyLevel =0.19;
        }

    }
    return _filter;
}
-(GPUImageStillCamera *)videoCamera{
    if (!_videoCamera) {
        NSString *captureSessionPreset = AVCaptureSessionPresetHigh;
        if (self.isOldDevice) {
            captureSessionPreset = AVCaptureSessionPreset640x480;
        }
        _videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:captureSessionPreset cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.horizontallyMirrorRearFacingCamera  = NO;
        _videoCamera.delegate = self;
    }
    return _videoCamera;
}
-(GPUImageView *)filterImageView{
    if (!_filterImageView) {
        _filterImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _filterImageView;
}
-(YCShootButton *)shootButton{
    if (!_shootButton) {
        _shootButton = [[YCShootButton alloc]initWithFrame:CGRectMake((KSCREENWIDTH - 80)/2, (KSCREENHEIGHT -120), 80, 80) longPress:(self.cameraType != YCCameraTypeStillCamera)];
        _shootButton.delegate = self;
    }
    return _shootButton;
}
-(UIButton *)transcribeButton{
    if (!_transcribeButton) {
        _transcribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _transcribeButton.frame = CGRectMake((KSCREENWIDTH - 80),20 , 80, 80);
        [_transcribeButton setImage:[UIImage imageNamed:@"switchcamera"] forState:UIControlStateNormal];
        [_transcribeButton setImage:[UIImage imageNamed:@"switchcamera"] forState:UIControlStateHighlighted];
        [_transcribeButton addTarget:self action:@selector(transcribeClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _transcribeButton;
}
-(UIButton *)finishButton{
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishButton.frame = CGRectMake((KSCREENWIDTH - 80)/2, (KSCREENHEIGHT -120), 80, 80);
        [_finishButton setImage:[UIImage imageNamed:@"finish_button_normal"] forState:UIControlStateNormal];
        [_finishButton setImage:[UIImage imageNamed:@"finish_button_select"] forState:UIControlStateHighlighted];
        [_finishButton addTarget:self action:@selector(finishButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _finishButton.hidden = YES;
    }
    return _finishButton;
}

-(UIButton *)rephotofraphButton{
    if (!_rephotofraphButton) {
        _rephotofraphButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rephotofraphButton.frame = CGRectMake((KSCREENWIDTH - 80)/2, (KSCREENHEIGHT -120), 80, 80);
        [_rephotofraphButton setImage:[UIImage imageNamed:@"rephotograph_button_normal"] forState:UIControlStateNormal];
        [_rephotofraphButton setImage:[UIImage imageNamed:@"rephotograph_button_select"] forState:UIControlStateHighlighted];

        [_rephotofraphButton addTarget:self action:@selector(rephotographButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _rephotofraphButton.hidden = YES;
    }
    return _rephotofraphButton;
}
-(UIButton *)dismissButton{
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _dismissButton.frame = CGRectMake(((KSCREENWIDTH - 80)/2 - 80)/2, (KSCREENHEIGHT -120), 80, 80);
        [_dismissButton setImage:[UIImage imageNamed:@"dismis_button_normal"] forState:UIControlStateNormal];
        [_dismissButton setImage:[UIImage imageNamed:@"dismis_button_normal"] forState:UIControlStateHighlighted];
        
        [_dismissButton addTarget:self action:@selector(dismissButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}
//之前想把视频预览层和图片预览用一个view，后来想想还要处理就没弄，其实也不负责任
-(UIView *)preview{
    if (!_preview) {
        _preview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, KSCREENWIDTH, KSCREENHEIGHT)];
        _preview.hidden = YES;
        _preview.backgroundColor = [UIColor blackColor];
        _preview.layer.backgroundColor = [UIColor blackColor].CGColor;
    }
    return _preview;
}
-(UIImageView *)preImageView{
    if (!_preImageView) {
        _preImageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _preImageView.hidden = YES;
        _preImageView.contentMode = UIViewContentModeScaleAspectFit;
        _preImageView.backgroundColor = [UIColor blackColor];
    }
    return _preImageView;
}
-(CMMotionManager *)motionManager{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc]init];
//        _motionManager.accelerometerUpdateInterval = 0.1;
    }
    return _motionManager;
}
-(CALayer *)focusLayer{
    if (!_focusLayer) {
        _focusLayer = [CALayer layer];
        _focusLayer.frame = CGRectMake(10, 10, 80, 80);
        _focusLayer.backgroundColor = [UIColor clearColor].CGColor;
        _focusLayer.contents = (id)[UIImage imageNamed:@"focus"].CGImage;
        _focusLayer.hidden = YES;
    }
    return _focusLayer;
}

@end
