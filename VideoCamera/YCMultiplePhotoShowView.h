//
//  YCMultiplePhotoShowView.h
//   
//
//  Created by  yc on 16/10/14.
//  Copyright © 2016年  yc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YCMultiplePhotoShowView : UIView <UIScrollViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UIScrollView *photoScroll;
@property (strong, nonatomic) UIPageControl *pageControl;

@property (assign, nonatomic) NSInteger currentIndex;
@property (strong, nonatomic) NSMutableDictionary *loadImageDic; //记录图片是否加载成功
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (strong, nonatomic) UIActionSheet *actionSheetSavePhoto;
@property (strong, nonatomic) UIAlertController *savePhotoAlertController;

@property (strong, nonatomic) UIImageView *saveImageView;  //保存图片

@property (assign, nonatomic) BOOL canScale;

@property (strong, nonatomic) NSArray *photoArray;
@property (strong, nonatomic) NSArray *placeholderArray;
@property (assign, nonatomic) NSInteger index;     //点击过来的图片下标
@property (strong, nonatomic) NSMutableArray *frameArray; //containerView的所有image的frame

@property (strong, nonatomic) UIView *containerView;
@property (assign, nonatomic) BOOL isShowing;

- (void)updateMultiplePhotoShowView;
- (void)dismissMultiplePhotoShow;

@end
