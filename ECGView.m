//
//  ECGView.m
//  Sigma
//
//  Created by Sonic X on 4/20/13.
//  Copyright (c) 2013 Sonic X. All rights reserved.
//

#import "ECGView.h"
#import "ECGDataList.h"
#import "ECGUtilties.h"

@interface ECGView ()

@property (strong, nonatomic) NSArray *ecgData;
@property (strong, nonatomic) NSArray *limitEcgData;
@property (strong, nonatomic) NSMutableArray *points;


@end


@implementation ECGView

#define KOAF 1.5f
#define KOAF_2 1.5f

- (BOOL)checkDispersion:(CGFloat)pnt {
    static CGFloat x0 = 0;
    static CGFloat x1 = 0;
    static CGFloat x2 = 0;
    static CGFloat x3 = 0;
    static CGFloat x4 = 0;
    static CGFloat x5 = 0;
    
    if (dispersion == 0)
        return NO;
    
    
    BOOL result = pnt - x0 > dispersion ? YES : NO;
    if (!result)
        result = pnt - x1 > dispersion ? YES : NO;
    if (!result)
        result = pnt - x2 > dispersion ? YES : NO;
    if (!result)
        result = pnt - x3 > dispersion ? YES : NO;
    if (!result)
        result = pnt - x4 > dispersion ? YES : NO;
    if (!result)
        result = pnt - x5 > dispersion ? YES : NO;

    x5 = x4;
    x4 = x3;
    x3 = x2;
    x2 = x1;
    x1 = x0;
    x0 = pnt;
    
    return result;
}

- (BOOL)checkDispersion2:(CGFloat)pnt {
    BOOL result = pnt > dispersion ? YES : NO;    
    return result;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (newSuperview == nil)
        return;
    
    static NSInteger x = 0;
    
    ECGDataList *list = [[ECGDataList alloc] init];
    self.ecgData = [list getECGData];
    
    _points = [NSMutableArray array];
    redPik = [NSMutableArray array];
    yellowPik = [NSMutableArray array];
    
//    NSInteger pool = _ecgData.count % 1000 == 0 ? _ecgData.count : (_ecgData.count / 1000) + 1;
    for (NSInteger j = 3; j < 4; j++) {
        
        self.limitEcgData = [list getLimitECGData:j];
        
        CGFloat mean = [ECGUtilties meanOfDataFrom:_limitEcgData];
        dispersion = [ECGUtilties dispersionOfDataFrom:_limitEcgData andMean:mean] * KOAF;
        
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:_limitEcgData.count];
        
        for (NSNumber *info in _limitEcgData) {
            NSInteger y = [info integerValue];
            NSPoint point = CGPointMake(x++, y);
            NSValue *value = [NSValue valueWithPoint:point];
            [array addObject:value];
        }
        [self.points addObjectsFromArray:array];
        
        limitRedPik = [self calculateRedPik];
        NSArray *pikLong = [self calculateLongBetweenPik:limitRedPik];
        CGFloat meanOfPik = [ECGUtilties meanOfDataFrom:pikLong];
        dispersion2 = [ECGUtilties dispersionOfDataFrom:pikLong andMean:meanOfPik] * KOAF_2;
        
        limitYellowPik = [NSMutableArray array];
        NSMutableArray *arr = [NSMutableArray array];
        NSInteger j = limitRedPik.count - 2;
        NSInteger s = 0;
        
        for (NSInteger i = 1; i < j; i++) {
            NSValue *value0 = [limitRedPik objectAtIndex:i-1-s];
            NSPoint point0 = [value0 pointValue];
            NSValue *value1 = [limitRedPik objectAtIndex:i-s];
            NSPoint point1 = [value1 pointValue];
            NSValue *value2 = [limitRedPik objectAtIndex:i+1-s];
            NSPoint point2 = [value2 pointValue];
            NSValue *value3 = [limitRedPik objectAtIndex:i+2-s];
            NSPoint point3 = [value3 pointValue];
            
            NSNumber *number0 = [pikLong objectAtIndex:i-1];
            NSInteger length0 = [number0 integerValue];
            NSNumber *number1 = [pikLong objectAtIndex:i];
            NSInteger length1 = [number1 integerValue];
            NSNumber *number2 = [pikLong objectAtIndex:i+1];
            NSInteger length2 = [number2 integerValue];
            
            if (length1 > meanOfPik + dispersion2 && length2 < meanOfPik - dispersion2) {
                point2 = CGPointMake(point3.x - (NSInteger)(point3.x - point1.x)/2, point2.y);
                [limitRedPik removeObjectAtIndex:i+1];
//                [limitRedPik addObject:[NSValue valueWithPoint:point2]];
//                [limitYellowPik addObject:[NSValue valueWithPoint:point2]];
            }
            else if (length1 > meanOfPik + dispersion2 && length0 < meanOfPik - dispersion2) {
                point0 = CGPointMake(point2.x - (NSInteger)(point2.x - point0.x)/2, point0.y);
//                [limitRedPik removeObjectAtIndex:i];
                [limitRedPik removeObjectAtIndex:i - s];
                j -= 1;
                s += 1;
//                [limitRedPik addObject:[NSValue valueWithPoint:point0]];
                [limitYellowPik addObject:[NSValue valueWithPoint:point0]];
            }
            else if (length1 > meanOfPik + dispersion2) {
                [arr addObject:[NSNumber numberWithInteger:i]];
            }
        }
        
        for (NSNumber *number in arr) {
            NSInteger pnt = [number integerValue];
            NSValue *value1 = [limitRedPik objectAtIndex:pnt];
            NSValue *value2 = [limitRedPik objectAtIndex:pnt + 1];
            
            NSPoint point1 = [value1 pointValue];
            NSPoint point2 = [value2 pointValue];
            
            NSPoint point = CGPointMake(point2.x - (NSInteger)(point2.x - point1.x)/2, point2.y - (point2.y - point1.y)/2);
//            [limitRedPik addObject:[NSValue valueWithPoint:point]];
            [limitYellowPik addObject:[NSValue valueWithPoint:point]];
        }
        [redPik addObjectsFromArray:limitRedPik];
        [yellowPik addObjectsFromArray:limitYellowPik];
//        NSLog(@"asb %ld", pool);
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    [self drawRedGraph];
    [self drawYellowGraph];
    [self drawBlueGraph];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
    
    long i = 1;
    for (NSValue *value in redPik) {
        NSPoint point = [value pointValue];
        NSAttributedString *currentText =
        [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", i++] attributes: attributes];
        [currentText drawAtPoint:NSMakePoint(point.x + 5, point.y / 10 - 5)];
    }
}

- (NSArray *)calculateLongBetweenPik:(NSArray *)pikArr {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:pikArr.count];
    
    NSInteger length = 0;
    NSPoint oldPoint = CGPointZero;
    for (NSValue *value in pikArr) {
        NSPoint newPoint = [value pointValue];
        if (length++ == 0) {
            oldPoint = newPoint;
            continue;
        }
        
        length = newPoint.x - oldPoint.x;
        oldPoint = newPoint;
        [arr addObject:[NSNumber numberWithInteger:length]];
    }
    
    return (NSArray *)arr;
}

- (NSMutableArray *)calculateRedPik {
    NSInteger counter = 1;
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSValue *value in self.points) {
        NSPoint point = CGPointZero;
        if ([self checkDispersion:[value pointValue].y] && counter == 0) {
            point = CGPointMake([value pointValue].x, [value pointValue].y);
            [array addObject:[NSValue valueWithPoint:point]];
            counter = 1;
        }
        else if (counter != 0) {
            counter++;
        }
        
        if (counter > 15)
            counter = 0;
        
    }
    return array;
}

- (void)drawYellowGraph {
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    
    for (NSValue *value in self.points) {
        NSPoint point = CGPointMake([value pointValue].x, [value pointValue].y);
        for (NSValue *val in yellowPik) {
            NSPoint point2 = [val pointValue];
            if (point.x == point2.x) {
                point = CGPointMake([val pointValue].x, [val pointValue].y / 5);
                break;
            }
            else {
                point = CGPointMake([value pointValue].x, [value pointValue].y / 15);
            }
        }
        [path lineToPoint:point];
        
    }
    [[NSColor greenColor] set];
    [path stroke];
}

- (void)drawBlueGraph {
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    
    for (NSValue *value in self.points) {
        NSPoint point = CGPointMake([value pointValue].x, [value pointValue].y / 15);
        [path lineToPoint:point];
        
    }
    [[NSColor blueColor] set];
    [path stroke];
}

- (void)drawRedGraph {
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    for (NSValue *value in self.points) {
        NSPoint point = CGPointMake([value pointValue].x, [value pointValue].y);
        for (NSValue *val in redPik) {
            NSPoint point2 = [val pointValue];
            if (point.x == point2.x) {
                point = CGPointMake([val pointValue].x, [val pointValue].y / 5);
                break;
            }
            else {
                point = CGPointMake([value pointValue].x, [value pointValue].y / 15);
            }
        }
        [path lineToPoint:point];
        
    }
    [[NSColor redColor] set];
    [path stroke];
}


@end
