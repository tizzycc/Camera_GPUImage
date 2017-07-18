//
//  YCImagePickerController.h
//
//  Created by  yc on 2017/6/26.
//  Copyright © 2017年  yc. All rights reserved.
//

#import <UIKit/UIKit.h>
#define KSCREENWIDTH               [UIScreen mainScreen].bounds.size.width
#define KSCREENHEIGHT              [UIScreen mainScreen].bounds.size.height
#define IS_IOS8                    (kCFCoreFoundationVersionNumber > 847.27)
typedef NS_ENUM(NSInteger, YCCameraType) {
    YCCameraTypeAll,            //
    YCCameraTypeStillCamera,    //只能拍照
    YCCameraTypeVideoCamera,    //只能录制视频
};

@protocol YCImagePickerControllerDelegate <NSObject>

/**
 录视频回调

 @param url 本地视频地址
 */
-(void)finishWithVideoURL:(NSURL *)url;

/**
 拍照片回调

 @param image 图像
 */
-(void)finishWithImage:(UIImage *)image;
@end

@interface YCImagePickerController : UIViewController
@property (nonatomic, strong) id<YCImagePickerControllerDelegate>delegate;



-(instancetype)initWithType:(YCCameraType)cameraType;



@end
