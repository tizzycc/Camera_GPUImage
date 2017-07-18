//
//  ViewController.m
//  YCVideoCamera
//
//  Created by  yc on 2017/7/18.
//  Copyright © 2017年 CYC. All rights reserved.
//

#import "ViewController.h"
#import "YCImagePickerController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()

@end

@implementation ViewController
- (IBAction)showVideoCamera {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized)//为做选择
    {
        [self checkAudioGranted];
    }
    else if (authStatus == AVAuthorizationStatusDenied)//不允许
    {

    
    }else if (authStatus ==  AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkAudioGranted];
                });
            }
        }];
    }

    
    
//    YCImagePickerController *imagePicker = [[YCImagePickerController alloc]initWithType:YCCameraTypeAll];
//    [self.navigationController presentViewController:imagePicker animated:YES completion:^{
//    }];
}
-(void)checkAudioGranted{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            YCImagePickerController *imagePicker = [[YCImagePickerController alloc]initWithType:YCCameraTypeAll];
                            [self.navigationController presentViewController:imagePicker animated:YES completion:^{
                            }];                        });
                    }
                }];
            }
        }
            break;
        case AVAuthorizationStatusAuthorized:
            //玩家授权
        {
            YCImagePickerController *imagePicker = [[YCImagePickerController alloc]initWithType:YCCameraTypeAll];
            [self.navigationController presentViewController:imagePicker animated:YES completion:^{
            }];        }
            break;
        default:
        {

        }
            break;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
