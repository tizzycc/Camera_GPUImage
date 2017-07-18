//
//  GPUImageBeautyFilter.h
//  GPUImageDemo
//
//  Created by wzzn on 2017/4/26.
//  Copyright © 2017年 wzzn. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageBeautyFilter : GPUImageFilter

@property (nonatomic, assign) CGFloat beautyLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, assign) CGFloat toneLevel;
@end
