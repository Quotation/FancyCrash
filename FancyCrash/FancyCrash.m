//
//  FancyCrash.m
//  FancyCrashTest
//
//  Created by Wang Xiaolei on 3/26/14.
//  Copyright (c) 2014 Wang Xiaolei. All rights reserved.
//

#import "FancyCrash.h"
@import QuartzCore;

#pragma mark - FCImagePiece

/**
 *  Splitted image piece
 */
@interface FCImagePiece : NSObject
@property (assign, nonatomic) CGPoint position;
@property (retain, nonatomic) NSArray *corners;
@property (retain, nonatomic) UIImage *image;
@end

@implementation FCImagePiece
@end

#pragma mark - FancyCrash class

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
    NSTimeInterval crackDuration = [self doubleOptionForKey:@"crackDuration" defaultValue:0.5];
    NSTimeInterval fallDuration = [self doubleOptionForKey:@"fallDuration" defaultValue:0.9];
    NSInteger rows = [self integerOptionForKey:@"rows" defaultValue:6];
    NSInteger columns = [self integerOptionForKey:@"columns" defaultValue:4];
    fallDuration = MAX(fallDuration, 0.2);
    rows = MAX(rows, 2);
    columns = MAX(columns, 2);
    
    NSTimeInterval totalDuration = crackDuration + fallDuration;
    
    // animation container
    UIViewController *animController = [UIViewController new];
    UIView *animView = animController.view;
    animView.backgroundColor = [UIColor blackColor];
    
    // break screenshot into pieces
    UIImage *screenshot = [self takeScreenshot];
    NSArray *pieces = [self polygonSplitImage:screenshot intoRows:rows columns:columns];
    
    // joint image pieces to fake current UI
    NSMutableArray *allPicLayers = [NSMutableArray arrayWithCapacity:pieces.count];
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < columns; c++) {
            FCImagePiece *piece = pieces[r * columns + c];
            CALayer *picLayer = [CALayer layer];
            picLayer.contents = (__bridge id)[piece.image CGImage];
            picLayer.frame = CGRectMake(piece.position.x, piece.position.y, piece.image.size.width, piece.image.size.height);
            [animView.layer addSublayer:picLayer];
            [allPicLayers addObject:picLayer];
            
            // clip to polygon path
            UIBezierPath *clipPath = [UIBezierPath bezierPath];
            [clipPath moveToPoint:[piece.corners[0] CGPointValue]];
            [clipPath addLineToPoint:[piece.corners[1] CGPointValue]];
            [clipPath addLineToPoint:[piece.corners[2] CGPointValue]];
            [clipPath addLineToPoint:[piece.corners[3] CGPointValue]];
            [clipPath closePath];
            [clipPath applyTransform:CGAffineTransformMakeTranslation(-piece.position.x, -piece.position.y)];
            
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.path = [clipPath CGPath];
            picLayer.mask = maskLayer;
        }
    }
    
    // add cracks
    UIBezierPath *cracksPath = [UIBezierPath bezierPath];
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < columns; c++) {
            FCImagePiece *piece = pieces[r * columns + c];
            [cracksPath moveToPoint:[piece.corners[0] CGPointValue]];
            [cracksPath addLineToPoint:[piece.corners[1] CGPointValue]];
            [cracksPath addLineToPoint:[piece.corners[2] CGPointValue]];
            [cracksPath addLineToPoint:[piece.corners[3] CGPointValue]];
            [cracksPath addLineToPoint:[piece.corners[0] CGPointValue]];
        }
    }
    
    CAShapeLayer *cracksLayer = [CAShapeLayer layer];
    cracksLayer.frame = animView.bounds;
    cracksLayer.path = [cracksPath CGPath];
    cracksLayer.strokeColor = [[UIColor blackColor] CGColor];
    cracksLayer.fillColor = nil;
    cracksLayer.lineJoin = kCALineJoinBevel;
    [animView.layer addSublayer:cracksLayer];
    
    [UIApplication sharedApplication].keyWindow.rootViewController = animController;
    
    // cracks animation
    CABasicAnimation *cracksAnim = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
    cracksAnim.duration = 0.1;
    cracksAnim.fillMode = kCAFillModeForwards;
    cracksAnim.removedOnCompletion = NO;
    cracksAnim.fromValue = @0.0;
    cracksAnim.toValue = @2.0;
    [cracksLayer addAnimation:cracksAnim forKey:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(crackDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [cracksLayer removeFromSuperlayer];
    });
    
    // pieces animation
    CGFloat beginTimeMax = 0.1;
    CGFloat xMoveMax = animView.bounds.size.width / columns * 0.1;
    CGFloat yMove = animView.bounds.size.height * (1.0 + 1.0 / rows);
    CGFloat rotateMax = M_PI * 0.1;
    CAMediaTimingFunction *timingEaseIn = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    for (NSInteger i = 0; i < rows * columns; i++) {
        CALayer *picLayer = allPicLayers[i];
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
        anim.beginTime = CACurrentMediaTime() + crackDuration + beginTimeMax * randomDouble01();
        anim.duration = fallDuration;
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(totalDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

- (NSArray *)rectangleSplitImage:(UIImage *)image intoRows:(NSUInteger)rowCount columns:(NSUInteger)colCount {
    if (rowCount == 0 || colCount == 0) {
        return nil;
    }
    
    NSMutableArray *resultPieces = [NSMutableArray arrayWithCapacity:rowCount * colCount];
    
    CGFloat scale = image.scale;
    CGFloat blockWidth = image.size.width / colCount;
    CGFloat blockHeight = image.size.height / rowCount;
    
    for (NSUInteger row = 0; row < rowCount; row++) {
        for (NSUInteger col = 0; col < colCount; col++) {
            CGRect rcBlock = CGRectMake(blockWidth * col, blockHeight * row, blockWidth, blockHeight);
            rcBlock = CGRectIntegral(rcBlock);
            
            FCImagePiece *piece = [FCImagePiece new];
            piece.position = rcBlock.origin;
            piece.corners = @[[NSValue valueWithCGPoint:rcBlock.origin],
                              [NSValue valueWithCGPoint:CGPointMake(rcBlock.origin.x + rcBlock.size.width, rcBlock.origin.y)],
                              [NSValue valueWithCGPoint:CGPointMake(rcBlock.origin.x + rcBlock.size.width, rcBlock.origin.y + rcBlock.size.height)],
                              [NSValue valueWithCGPoint:CGPointMake(rcBlock.origin.x, rcBlock.origin.y + rcBlock.size.height)]];
            
            rcBlock.origin.x *= scale;
            rcBlock.origin.y *= scale;
            rcBlock.size.width *= scale;
            rcBlock.size.height *= scale;
            CGImageRef cgBlock = CGImageCreateWithImageInRect(image.CGImage, rcBlock);
            piece.image = [UIImage imageWithCGImage:cgBlock scale:scale orientation:image.imageOrientation];
            CGImageRelease(cgBlock);
            
            [resultPieces addObject:piece];
        }
    }
    
    return [NSArray arrayWithArray:resultPieces];
}

- (NSArray *)polygonSplitImage:(UIImage *)image intoRows:(NSUInteger)rowCount columns:(NSUInteger)colCount {
    if (rowCount == 0 || colCount == 0) {
        return nil;
    }
    
    NSMutableArray *resultPieces = [NSMutableArray arrayWithCapacity:rowCount * colCount];
    
    CGFloat scale = image.scale;
    CGFloat blockWidth = image.size.width / colCount;
    CGFloat blockHeight = image.size.height / rowCount;
    
    // random move cell corners
    CGPoint *corners = (CGPoint *)malloc(sizeof(CGPoint) * (rowCount + 1) * (colCount + 1));
    CGFloat maxMoveX = blockWidth * 0.3;
    CGFloat maxMoveY = blockHeight * 0.3;
    for (NSUInteger row = 0; row <= rowCount; row++) {
        for (NSUInteger col = 0; col <= colCount; col++) {
            CGPoint *pt = corners + row * (colCount + 1) + col;
            pt->x = blockWidth * col;
            pt->y = blockHeight * row;
            if (col != 0 && col != colCount) {
                pt->x += randomDouble11() * maxMoveX;
            }
            if (row != 0 && row != rowCount) {
                pt->y += randomDouble11() * maxMoveY;
            }
        }
    }
    
    for (NSUInteger row = 0; row < rowCount; row++) {
        for (NSUInteger col = 0; col < colCount; col++) {
            // 4 corners make a polygon
            CGPoint *plt = corners + row * (colCount + 1) + col;
            CGPoint lt = plt[0];
            CGPoint rt = plt[1];
            CGPoint rb = plt[colCount + 2];
            CGPoint lb = plt[colCount + 1];
            
            // bounding rect for sub image
            CGFloat minX = MIN(lt.x, lb.x);
            CGFloat minY = MIN(lt.y, rt.y);
            CGFloat maxX = MAX(rt.x, rb.x);
            CGFloat maxY = MAX(lb.y, rb.y);
            CGRect rcBlock = CGRectMake(minX, minY, maxX - minX, maxY - minY);
            rcBlock = CGRectIntegral(rcBlock);
            
            FCImagePiece *piece = [FCImagePiece new];
            piece.position = rcBlock.origin;
            piece.corners = @[[NSValue valueWithCGPoint:lt],
                              [NSValue valueWithCGPoint:rt],
                              [NSValue valueWithCGPoint:rb],
                              [NSValue valueWithCGPoint:lb]];
            
            rcBlock.origin.x *= scale;
            rcBlock.origin.y *= scale;
            rcBlock.size.width *= scale;
            rcBlock.size.height *= scale;
            CGImageRef cgBlock = CGImageCreateWithImageInRect(image.CGImage, rcBlock);
            piece.image = [UIImage imageWithCGImage:cgBlock scale:scale orientation:image.imageOrientation];
            CGImageRelease(cgBlock);
            
            [resultPieces addObject:piece];
        }
    }
    
    free(corners);
    
    return [NSArray arrayWithArray:resultPieces];
}

@end
