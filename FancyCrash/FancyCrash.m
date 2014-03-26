//
//  FancyCrash.m
//  FancyCrashTest
//
//  Created by Wang Xiaolei on 3/26/14.
//  Copyright (c) 2014 Wang Xiaolei. All rights reserved.
//

#import "FancyCrash.h"
@import QuartzCore;

@interface FancyCrash ()
@property (retain, nonatomic) NSDictionary *effectOptions;
@end

@implementation FancyCrash

+ (void)crash
{
    FancyCrashEffect effect = (arc4random() % kFancyCrashEffectLast) + 1;
    [FancyCrash crashWithEffect:effect effectOptions:nil];
}

+ (void)crashWithEffect:(FancyCrashEffect)effect effectOptions:(NSDictionary *)options
{
    FancyCrash *crash = [FancyCrash new];
    crash.effectOptions = options;
    
    switch (effect) {
        case kFancyCrashEffectBreakGlass1:
            [crash breakGlass1];
            break;
            
        default:
            [crash exitApp];
            break;
    }
}

#pragma mark - Effects

// random double in [0, 1]
static double randomDouble01()
{
    return ((int)arc4random() % 101) / 100.0;
}

// random double in [-1, 1]
static double randomDouble11()
{
    return ((int)arc4random() % 201 - 100) / 100.0;
}

- (void)breakGlass1
{
    NSTimeInterval duration = [self doubleOptionForKey:@"duration" defaultValue:0.9];
    NSInteger rows = [self integerOptionForKey:@"rows" defaultValue:6];
    NSInteger columns = [self integerOptionForKey:@"columns" defaultValue:4];
    rows = MAX(rows, 2);
    columns = MAX(columns, 2);
    
    // animation container
    UIViewController *animController = [UIViewController new];
    UIView *animView = animController.view;
    animView.backgroundColor = [UIColor blackColor];
    
    // break screenshot into pieces
    UIImage *screenshot = [self takeScreenshot];
    NSArray *pieces = [self splitImage:screenshot intoRows:rows columns:columns];
    CGFloat y = 0;
    for (NSInteger r = 0; r < rows; r++) {
        CGFloat x = 0;
        CGFloat rowHeight = 0;
        for (NSInteger c = 0; c < columns; c++) {
            UIImage *pic = pieces[r * columns + c];
            CALayer *picLayer = [CALayer layer];
            picLayer.contents = (__bridge id)([pic CGImage]);
            picLayer.frame = CGRectMake(x, y, pic.size.width, pic.size.height);
            [animView.layer addSublayer:picLayer];
            
            x += pic.size.width;
            if (c == 0) {
                rowHeight = pic.size.height;
            }
        }
        y += rowHeight;
    }
    
    [UIApplication sharedApplication].keyWindow.rootViewController = animController;
    
    // animation
    CGFloat beginTimeMax = 0.1;
    CGFloat xMoveMax = animView.bounds.size.width / columns * 0.1;
    CGFloat yMove = animView.bounds.size.height * (1.0 + 1.0 / rows);
    CGFloat rotateMax = M_PI * 0.1;
    CAMediaTimingFunction *timingEaseIn = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    NSArray *allPicLayers = animView.layer.sublayers;
    for (NSInteger i = 0; i < rows * columns; i++) {
        CALayer *picLayer = allPicLayers[i];
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
        anim.beginTime = CACurrentMediaTime() + beginTimeMax * randomDouble01();
        anim.duration = duration;
        anim.fillMode = kCAFillModeForwards;
        anim.cumulative = YES;
        anim.removedOnCompletion = NO;
        anim.timingFunction = timingEaseIn;
        CATransform3D trans = picLayer.transform;
        trans = CATransform3DTranslate(trans, randomDouble11() * xMoveMax, yMove, 0);
        trans = CATransform3DRotate(trans, randomDouble11() * rotateMax, 0, 0, 1);
        anim.toValue = [NSValue valueWithCATransform3D:trans];
        [picLayer addAnimation:anim forKey:nil];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitApp];
    });
}

#pragma mark - Helpers

- (double)doubleOptionForKey:(NSString *)key defaultValue:(double)defaultValue
{
    NSNumber *num = self.effectOptions[key];
    return num ? [num doubleValue] : defaultValue;
}

- (NSInteger)integerOptionForKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
    NSNumber *num = self.effectOptions[key];
    return num ? [num integerValue] : defaultValue;
}

- (void)exitApp
{
    exit(1);
}

- (UIImage *)takeScreenshot
{
    UIView *rootView = [UIApplication sharedApplication].keyWindow;
    UIGraphicsBeginImageContextWithOptions(rootView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [rootView drawViewHierarchyInRect:rootView.bounds afterScreenUpdates:YES];
    
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenshot;
}

- (NSArray *)splitImage:(UIImage *)image intoRows:(NSUInteger)rowCount columns:(NSUInteger)colCount {
    if (rowCount == 0 || colCount == 0) {
        return nil;
    }
    
    NSMutableArray *resultImages = [NSMutableArray arrayWithCapacity:rowCount * colCount];
    
    CGFloat blockWidth = image.size.width / colCount * image.scale;
    CGFloat blockHeight = image.size.height / rowCount * image.scale;
    CGImageRef cgSelf = image.CGImage;
    
    for (NSUInteger row = 0; row < rowCount; row++) {
        for (NSUInteger col = 0; col < colCount; col++) {
            CGRect rcBlock = CGRectMake(blockWidth * col, blockHeight * row, blockWidth, blockHeight);
            CGImageRef cgBlock = CGImageCreateWithImageInRect(cgSelf, rcBlock);
            UIImage *imgBlock = [UIImage imageWithCGImage:cgBlock scale:image.scale orientation:image.imageOrientation];
            CGImageRelease(cgBlock);
            
            [resultImages addObject:imgBlock];
        }
    }
    
    return [NSArray arrayWithArray:resultImages];
}

@end
