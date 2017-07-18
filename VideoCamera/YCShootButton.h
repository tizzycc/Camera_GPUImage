//
//  YCShootButton.h
//
//  Created by  yc on 2017/6/26.
//  Copyright © 2017年  yc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YCShootButtonDelegate <NSObject>
@optional
-(BOOL)tapGestureRecognizer;
-(void)LongPressGestureRecognizerStateBegan;
-(void)LongPressGestureRecognizerStateEnded;
@end
@interface YCShootButton : UIView
@property (nonatomic, weak)id<YCShootButtonDelegate>delegate;
@property (nonatomic,  assign)NSTimeInterval maxTime;

/**
 初始化，是否添加单击手势待处理。

 @param frame frame
 @param longPress 是否添加长按手势
 @return YCShootButton
 */
-(instancetype)initWithFrame:(CGRect)frame longPress:(BOOL)longPress;
@end
