//
//  YCShootButton.m
//
//  Created by  yc on 2017/6/26.
//  Copyright © 2017年  yc. All rights reserved.
//

#import "YCShootButton.h"
static CGFloat scope_m = 1.3;//放大系数
static CGFloat scope_s = 0.6;//缩小系数

@interface YCShootButton ()
{
    NSTimeInterval _totalTime;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
}
@property (nonatomic,strong) CAShapeLayer *outerLayer;
@property (nonatomic,strong) CAShapeLayer *interLayer;
@property (nonatomic,strong) CAShapeLayer *progressLayer;
@property (nonatomic,strong) CAShapeLayer *progressBgLayer;

@property (nonatomic,strong) UIBezierPath *outerPath;
@property (nonatomic,strong) UIBezierPath *interPath;
@property (nonatomic,strong) UIBezierPath *progressPath;
@property (nonatomic,strong) UIBezierPath *progressBgPath;
@property (nonatomic,strong) CADisplayLink *displayLink;
@end
@implementation YCShootButton

-(instancetype)initWithFrame:(CGRect)frame longPress:(BOOL)longPress{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubLayers];
        [self addGestureRecognizersWith:longPress];
        self.maxTime = 10;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self addSubLayers];
        [self addGestureRecognizersWith:YES];
        self.maxTime = 10;
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubLayers];
        [self addGestureRecognizersWith:YES];
        self.maxTime = 10;
    }
    return self;
}
-(void)addSubLayers{
    //TODO:这里UIBezierPath没必要用属性，我也不记得当初是怎么想的了。。progressBgLayer和progressLayer可以用一个，两种颜色，懒得弄了
    self.progressBgLayer.path = self.progressBgPath.CGPath;
    [self.layer addSublayer:self.progressBgLayer];
    
    self.progressLayer.path = self.progressPath.CGPath;
    [self.layer addSublayer:self.progressLayer];
    
    self.outerLayer.path = self.outerPath.CGPath;
    [self.layer addSublayer:self.outerLayer];
    
    self.interLayer.path = self.interPath.CGPath;
    [self.layer addSublayer:self.interLayer];

}
-(void)addGestureRecognizersWith:(BOOL)longPress{
    if (longPress) {
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGesture:)];
        _longPressGestureRecognizer.minimumPressDuration = 0.2;
        _longPressGestureRecognizer.allowableMovement = 10;
        
        [self addGestureRecognizer:_longPressGestureRecognizer];
    }
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(captureImage:)];
    [self addGestureRecognizer:tapG];
}
-(void)captureImage:(UITapGestureRecognizer *)tap{
    self.userInteractionEnabled = NO;
    [self.delegate tapGestureRecognizer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //防止重复点击
        self.userInteractionEnabled = YES;

    });
}
-(void)longPressGesture:(UILongPressGestureRecognizer *)sender{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan://开始
        {
            NSLog(@"%d",1);

            [self startRecodeAnimation];
            [self.delegate LongPressGestureRecognizerStateBegan];
            _totalTime = 0;
            self.displayLink.paused = NO;
        }
            break;
        case UIGestureRecognizerStateEnded://结束
        {
            NSLog(@"%d",2);

            [self.delegate LongPressGestureRecognizerStateEnded];
            self.displayLink.paused = YES;
            [self endRecodeAnimation];
            _longPressGestureRecognizer.enabled = YES;
            
        }
            break;
        case UIGestureRecognizerStateCancelled:
        {
            NSLog(@"%d",3);
            [self.delegate LongPressGestureRecognizerStateEnded];
            self.displayLink.paused = YES;
            [self endRecodeAnimation];
            _longPressGestureRecognizer.enabled = YES;

            
        }
            break;
        case UIGestureRecognizerStateFailed:
        {
            NSLog(@"%d",4);
            [self.delegate LongPressGestureRecognizerStateEnded];
            self.displayLink.paused = YES;
            [self endRecodeAnimation];
            _longPressGestureRecognizer.enabled = YES;

        }
            break;
        case UIGestureRecognizerStatePossible:
        {
            NSLog(@"%d",0);
        }
            break;
        default:
            break;
    }

}

-(void)startRecodeAnimation{
    
    self.outerLayer.transform =CATransform3DScale(self.outerLayer.transform, scope_m, scope_m, 1);
    self.interLayer.transform =CATransform3DScale(self.interLayer.transform, scope_s, scope_s, 1);
    self.progressBgLayer.transform =CATransform3DScale(self.progressBgLayer.transform, scope_m, scope_m, 1);
    self.progressBgLayer.lineWidth = 3;
    self.progressLayer.transform =CATransform3DScale(self.progressLayer.transform, scope_m, scope_m, 1);
    self.progressLayer.lineWidth = 3;
}

-(void)endRecodeAnimation{
    self.outerLayer.transform =CATransform3DScale(self.outerLayer.transform, 1/scope_m, 1/scope_m, 1);
    self.interLayer.transform =CATransform3DScale(self.interLayer.transform, 1/scope_s, 1/scope_s, 1);
    self.progressBgLayer.transform =CATransform3DScale(self.progressBgLayer.transform, 1/scope_m, 1/scope_m, 1);
    self.progressBgLayer.lineWidth = 0;
    self.progressLayer.transform =CATransform3DScale(self.progressLayer.transform, 1/scope_m, 1/scope_m, 1);
    self.progressLayer.lineWidth = 0;
    
}

-(void)displayLinkSelector:(CADisplayLink *)displayLink{
    _totalTime +=displayLink.duration;
    float progress = _totalTime/self.maxTime;
    
    UIBezierPath *path= [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetWidth(self.bounds)/2) radius:CGRectGetWidth(self.bounds)/2 startAngle:(-M_PI_2) endAngle:2*M_PI *progress -M_PI_2 clockwise:YES];
    self.progressLayer.path = path.CGPath;
    if (_totalTime>= self.maxTime) {
        self.displayLink.paused = YES;
        _longPressGestureRecognizer.enabled = NO;
    }
}


-(CAShapeLayer *)outerLayer{
    if (!_outerLayer) {
        _outerLayer = [CAShapeLayer layer];
        _outerLayer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3].CGColor;
        _outerLayer.frame = self.bounds;
        
    }
    return _outerLayer;
}
-(CAShapeLayer *)interLayer{
    if (!_interLayer) {
        _interLayer  = [CAShapeLayer layer];
        _interLayer.frame = CGRectMake(10, 10, CGRectGetWidth(self.bounds)-20, CGRectGetHeight(self.bounds)-20);
        _interLayer.fillColor = [UIColor whiteColor].CGColor;
        
    }
    return _interLayer;
    
}
-(CAShapeLayer *)progressBgLayer{
    if (!_progressBgLayer) {
        _progressBgLayer = [CAShapeLayer layer];
        _progressBgLayer.frame =self.bounds;
        _progressBgLayer.strokeColor = [UIColor whiteColor].CGColor;
        _progressBgLayer.fillColor = [UIColor clearColor].CGColor;
        _progressBgLayer.lineWidth = 0;
        _progressBgLayer.lineCap = kCALineCapRound;
    }
    return _progressBgLayer;
}
-(CAShapeLayer *)progressLayer{
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        _progressLayer.strokeColor = [UIColor greenColor].CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = 0;
        _progressLayer.lineCap = kCALineCapRound;
    }
    return _progressLayer;
}
-(UIBezierPath *)outerPath{
    if (!_outerPath) {
        _outerPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:CGRectGetWidth(self.bounds)/2];
    }
    return _outerPath;
}
-(UIBezierPath *)interPath{
    if (!_interPath) {
        _interPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(self.bounds)-20, CGRectGetHeight(self.bounds)-20) cornerRadius:CGRectGetWidth(self.bounds)/2-10];
        
    }
    return _interPath;
}
-(UIBezierPath *)progressPath{
    if (!_progressPath) {
        _progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetWidth(self.bounds)/2) radius:CGRectGetWidth(self.bounds)/2 startAngle:(0) endAngle:0 clockwise:YES];
    }
    return _progressPath;
}
-(UIBezierPath *)progressBgPath{
    if (!_progressBgPath) {
        _progressBgPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetWidth(self.bounds)/2) radius:CGRectGetWidth(self.bounds)/2 startAngle:(0) endAngle:2*M_PI clockwise:YES];
    }
    return _progressBgPath;
}
-(CADisplayLink *)displayLink{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkSelector:)];
        _displayLink.paused = YES;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    }
    return _displayLink;
}
@end
