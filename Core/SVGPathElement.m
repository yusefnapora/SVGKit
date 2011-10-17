//
//  SVGPathElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGPathElement.h"

#import "SVGElement+Private.h"
#import "SVGShapeElement+Private.h"
#import "SVGUtils.h"
#import "SVGPathParserHelper.h"
#import <math.h>

@interface SVGPathElement ()


@property (nonatomic, assign) CGMutablePathRef CGPath;
- (void)parseData:(NSString *)data;

- (void) moveTo:(CGPoint)point relative:(BOOL)relative;
- (void) lineTo:(CGPoint)point relative:(BOOL)relative;
- (void) addCurve:(CGPoint)control1 control2:(CGPoint)control2 endPoint:(CGPoint)endPoint;
- (void) addQuadCurveToPoint:(CGPoint) endPoint controlPoint:(CGPoint)controlPoint;
- (void) addArcToPoint:(CGPoint)endPoint theta:(CGFloat)theta radiusX:(CGFloat)radiusX radiusY:(CGFloat)radiusY largeArc:(BOOL)largeArc sweepArc:(BOOL)sweepArc; 
- (void) closePath;

@end


@implementation SVGPathElement

@synthesize CGPath;



#define MAX_ACCUM 16

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"d"])) {
		[self parseData:value];
	}
}

- (void)parseData:(NSString *)string {

    NSUInteger stringLength = [string length];
    SVGPathParserHelper *parserHelper = [[SVGPathParserHelper alloc] initWithString:string position:0];
    
    [parserHelper skipWhitespace];
    self.CGPath = CGPathCreateMutable();

    CGPoint lastPoint = CGPointZero;
    CGPoint lastCurveControlPoint = CGPointZero;
    CGPoint lastQuadCurveControlPoint = CGPointZero;
    
        
    while (parserHelper.position < stringLength)
    {
        UniChar cmd = [string characterAtIndex:parserHelper.position];
        [parserHelper advance];
        BOOL wasCurve = NO;
        BOOL wasQuadCurve = NO;
        switch (cmd)
        {
            case 'M':
            case 'm':
            {
                float x = [parserHelper nextFloat];
                float y = [parserHelper nextFloat];
                BOOL relative = NO;
                if (cmd == 'm') {
                    relative = YES;
                    lastPoint.x += x;
                    lastPoint.y += y;
                } else {
                    lastPoint.x = x;
                    lastPoint.y = y;
                }
                [self moveTo:CGPointMake(x, y) relative:relative];
                break;
            }
            
            case 'Z':
            case 'z':
            {
                [self closePath];
                break;
            }
                
            case 'L':
            case 'l':
            {
                float x = [parserHelper nextFloat];
                float y = [parserHelper nextFloat];
                BOOL relative = NO;
                if (cmd == 'l') {
                    relative = YES;
                    lastPoint.x += x;
                    lastPoint.y += y;
                } else {
                    lastPoint.x = x;
                    lastPoint.y = y;
                }
                [self lineTo:CGPointMake(x, y) relative:relative];
                break;
            }
                
            case 'H':
            case 'h':
            {
                float x = [parserHelper nextFloat];
                if (cmd == 'h') {
                    [self lineTo:CGPointMake(x, 0) relative:YES];
                    lastPoint.x += x;
                } else {
                    [self lineTo:CGPointMake(x, lastPoint.y) relative:NO];
                    lastPoint.x = x;
                }
                break;
            }
                
            case 'V':
            case 'v':
            {
                float y = [parserHelper nextFloat];
                if (cmd == 'v') {
                    [self lineTo:CGPointMake(0, y) relative:YES];
                    lastPoint.y += y;
                } else {
                    [self lineTo:CGPointMake(lastPoint.x, y) relative:NO];
                    lastPoint.y = y;
                }
                break;
            }
                
            case 'C':
            case 'c':
            {
                wasCurve = YES;
                CGPoint c1 = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint c2 = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint pt = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                
                if (cmd == 'c') {
                    c1.x += lastPoint.x;
                    c2.x += lastPoint.x;
                    pt.x += lastPoint.x;
                    c1.y += lastPoint.y;
                    c2.y += lastPoint.y;
                    pt.y += lastPoint.y;
                }
                [self addCurve:c1 control2:c2 endPoint:pt];
                lastCurveControlPoint = c2;
                lastPoint = pt;
                
                break;
            }
                
            case 'S':
            case 's':
            {
                wasCurve = YES;
                CGPoint c2 = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint pt = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                if (cmd == 's') {
                    c2.x += lastPoint.x;
                    pt.x += lastPoint.x;
                    c2.y += lastPoint.y;
                    pt.y += lastPoint.y;
                }
                CGPoint c1 = CGPointMake(2 * lastPoint.x - lastCurveControlPoint.x, 2 * lastPoint.y - lastCurveControlPoint.y);
                [self addCurve:c1 control2:c2 endPoint:pt];
                lastCurveControlPoint = c2;
                lastPoint = pt;
                
                break;
            }
            case 'Q':
            case 'q':
            {
                wasQuadCurve = YES;
                CGPoint controlPoint = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint endPoint = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                if (cmd == 'q')
                {
                    controlPoint.x += lastPoint.x;
                    controlPoint.y += lastPoint.y;
                    endPoint.x += lastPoint.x;
                    endPoint.y += lastPoint.y;
                }
                
                [self addQuadCurveToPoint:endPoint controlPoint:controlPoint];
                lastQuadCurveControlPoint = controlPoint;
                lastPoint = endPoint;
                break;
            }
            case 'T':
            case 't':
            {
                wasQuadCurve = YES;
                CGPoint endPoint = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint controlPoint;
                
                controlPoint.x = 2 * lastPoint.x - lastQuadCurveControlPoint.x;
                controlPoint.y = 2 * lastPoint.y - lastQuadCurveControlPoint.y;
                if (cmd == 't') {
                    endPoint.x += lastPoint.x;
                    endPoint.y += lastPoint.y;
                    controlPoint.x += lastPoint.x;
                    controlPoint.y += lastPoint.y;
                }
                [self addQuadCurveToPoint:endPoint controlPoint:controlPoint];
                lastQuadCurveControlPoint = controlPoint;
                lastPoint = endPoint;
                
                break;
            }
            case 'A':
            case 'a':
            {
                CGFloat rx = [parserHelper nextFloat];
                CGFloat ry = [parserHelper nextFloat];
                CGFloat theta = [parserHelper nextFloat];
                BOOL largeArc = (BOOL)[parserHelper nextFloat];
                BOOL sweepArc = (BOOL)[parserHelper nextFloat];
                CGFloat x = [parserHelper nextFloat];
                CGFloat y = [parserHelper nextFloat];
                CGPoint pt = CGPointMake(x, y);
                [self addArcToPoint:pt theta:theta radiusX:rx radiusY:ry largeArc:largeArc sweepArc:sweepArc];
                lastPoint.x = x;
                lastPoint.y = y;
                break;
            }
        }
        
        if (!wasCurve) {
            lastCurveControlPoint = lastPoint;
        }
        if (!wasQuadCurve) {
            lastQuadCurveControlPoint = lastPoint;
        }
        [parserHelper skipWhitespace];
    }
    
    [parserHelper release];
    [self loadPath:self.CGPath];
    CGPathRelease(self.CGPath);
    self.CGPath = NULL;
}

- (void) moveTo:(CGPoint)point relative:(BOOL)relative
{
    if (relative)
    {
        if (!CGPathIsEmpty(self.CGPath))
        {
            CGPoint current = CGPathGetCurrentPoint(self.CGPath);
            point.x += current.x;
            point.y += current.y;
        }
    }
    
    CGPathMoveToPoint(self.CGPath, NULL, point.x, point.y);
}

- (void) lineTo:(CGPoint)point relative:(BOOL)relative
{
    if (relative)
    {
        if (!CGPathIsEmpty(self.CGPath))
        {
            CGPoint current = CGPathGetCurrentPoint(self.CGPath);
            point.x += current.x;
            point.y += current.y;
        }
    }
    
    CGPathAddLineToPoint(self.CGPath, NULL, point.x, point.y);
}

- (void) addCurve:(CGPoint)control1 control2:(CGPoint)control2 endPoint:(CGPoint)endPoint
{
    CGPathAddCurveToPoint(self.CGPath, NULL, control1.x, control1.y, control2.x, control2.y, endPoint.x, endPoint.y);
}

- (void) addQuadCurveToPoint:(CGPoint) endPoint controlPoint:(CGPoint)controlPoint
{
    
}

- (void) addArcToPoint:(CGPoint)endPoint theta:(CGFloat)theta radiusX:(CGFloat)radiusX radiusY:(CGFloat)radiusY largeArc:(BOOL)largeArc sweepArc:(BOOL)sweepArc; 
{
    // Not yet implemented
}

- (void) closePath
{
    CGPathCloseSubpath(self.CGPath);
}

@end
