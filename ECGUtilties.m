//
//  ECGUtilties.m
//  Sigma
//
//  Created by Sonic X on 4/20/13.
//  Copyright (c) 2013 Sonic X. All rights reserved.
//

#import "AppKit/AppKit.h"
#import "ECGUtilties.h"

@implementation ECGUtilties

#define THRESHOLD 0.0f

+ (CGFloat)meanOfDataFrom:(NSArray *)array {
    
    CGFloat val = 0.0f;
    if ([array count] == 0)
        return 0.0f;
    
    for (NSNumber *number in array) {
        if (![number isKindOfClass:[NSNumber class]])
            continue;
        NSInteger data = [number integerValue];
        val += data;
    }
    val /= [array count];
    
    return val;
}

+ (CGFloat)dispersionOfDataFrom:(NSArray *)array andMean:(CGFloat)mean {
    
    CGFloat val = 0.0f;
    if ([array count] == 0)
        return 0.0f;
    
    for (NSNumber *number in array) {
        if (![number isKindOfClass:[NSNumber class]])
            continue;
        NSInteger data = [number integerValue];
        val = val + powf(data - mean, 2.0f);
    }
    val = val / [array count];
    val = sqrtf(val);
    
    return val;
}

+ (CGFloat)detectionThresholdAnomaliesFoeMean:(CGFloat)mean atDispersion:(CGFloat)dispersion {
    
    CGFloat val = 0.0f;
    
    val = mean + dispersion * THRESHOLD;
    
    return val;
}

@end
