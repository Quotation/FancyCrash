//
//  FancyCrash.h
//  FancyCrashTest
//
//  Created by Wang Xiaolei on 3/26/14.
//  Copyright (c) 2014 Wang Xiaolei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FancyCrashEffect)
{
    kFancyCrashEffectNone = 0,      // Silent crash
    
    /**
     *  Options:
     *    @"crackDuration"  : @0.5,     // crack animation duration
     *    @"fallDuration"   : @0.9,     // fall animation duration
     *    @"rows"           : @6,       // row count
     *    @"columns"        : @4,       // column count
     */
    kFancyCrashEffectBreakGlass1,
    
    kFancyCrashEffectLast = kFancyCrashEffectBreakGlass1
};

@interface FancyCrash : NSObject

/**
 *  Crash App with random effect.
 */
+ (void)crash;

/**
 *  Crash App with specific effect and custom options.
 */
+ (void)crashWithEffect:(FancyCrashEffect)effect effectOptions:(NSDictionary *)options;

@end
