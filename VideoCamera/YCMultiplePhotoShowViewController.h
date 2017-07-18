//
//  YCMultiplePhotoShowViewController.h
//   
//
//  Created by  yc on 16/8/31.
//  Copyright © 2016年  yc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YCMultiplePhotoShowViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *photoArray;
@property (assign, nonatomic) NSInteger index;     //点击过来的图片下标
@property (assign, nonatomic) BOOL isSendDynamic;

@end
