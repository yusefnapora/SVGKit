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

    float lastX = 0;
    float lastY = 0;
    float lastX1 = 0;
    float lastY1 = 0;
    
    while (parserHelper.position < stringLength)
    {
        UniChar cmd = [string characterAtIndex:parserHelper.position];
        [parserHelper advance];
        BOOL wasCurve = NO;
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
                    lastX += x;
                    lastY += y;
                } else {
                    lastX = x;
                    lastY = y;
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
                    lastX += x;
                    lastY += y;
                } else {
                    lastX = x;
                    lastY = y;
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
                    lastX += x;
                } else {
                    [self lineTo:CGPointMake(x, lastY) relative:NO];
                    lastX = x;
                }
                break;
            }
                
            case 'V':
            case 'v':
            {
                float y = [parserHelper nextFloat];
                if (cmd == 'v') {
                    [self lineTo:CGPointMake(0, y) relative:YES];
                    lastY += y;
                } else {
                    [self lineTo:CGPointMake(lastX, y) relative:NO];
                    lastY = y;
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
                    c1.x += lastX;
                    c2.x += lastX;
                    pt.x += lastX;
                    c1.y += lastY;
                    c2.y += lastY;
                    pt.y += lastY;
                }
                [self addCurve:c1 control2:c2 endPoint:pt];
                lastX1 = c2.x;
                lastY1 = c2.y;
                lastX = pt.x;
                lastY = pt.y;
                
                break;
            }
                
            case 'S':
            case 's':
            {
                wasCurve = YES;
                CGPoint c2 = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                CGPoint pt = CGPointMake([parserHelper nextFloat], [parserHelper nextFloat]);
                if (cmd == 's') {
                    c2.x += lastX;
                    pt.x += lastX;
                    c2.y += lastY;
                    pt.y += lastY;
                }
                CGPoint c1 = CGPointMake(2 * lastX - lastX1, 2 * lastY - lastY1);
                [self addCurve:c1 control2:c2 endPoint:pt];
                lastX1 = c2.x;
                lastY1 = c2.y;
                lastX = pt.x;
                lastY = pt.y;
                
                break;
            }
        }
        
        if (!wasCurve) {
            lastX1 = lastX;
            lastY1 = lastY;
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

- (void) closePath
{
    CGPathCloseSubpath(self.CGPath);
}

@end
