//
//  YCVideoShowViewController.h
//   
//
//  Created by  yc on 2017/7/4.
//  Copyright © 2017年  yc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YCVideoShowViewControllerDelegate <NSObject>

-(void)removeVideo;

@end

@interface YCVideoShowViewController :UIViewController

@property (nonatomic, weak) id<YCVideoShowViewControllerDelegate>delegate;
@property (nonatomic, copy) NSString *movieURL;
@end
