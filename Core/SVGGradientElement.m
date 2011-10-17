//
//  SVGGradientElement.m
//  SVGPad
//
//  Created by Yusef Napora on 10/15/11.
//  Copyright (c) 2011 SefCo. All rights reserved.
//

#import "SVGGradientElement.h"
#import "SVGElement+Private.h"

@implementation SVGGradientElement

@synthesize point1;
@synthesize point2;
@synthesize gradientUnits;
@synthesize gradientTransform;

- (void)parseAttributes:(NSDictionary *)attributes 
{
    [super parseAttributes:attributes];

    id value = nil;
    
    if ((value = [attributes valueForKey:@"gradientUnits"]))
    {
        if ([value isEqualToString:@"userSpaceOnUse"])
            self.gradientUnits = SVGGradientUnitsUserSpace;
        else if ([value isEqualToString:@"objectBoundingBox"])
            self.gradientUnits = SVGGradientUnitsBoundingBox;
    }

    value = nil;
    if ((value = [attributes valueForKey:@"x1"])) {
        point1.x = [value floatValue];
    }
    
    value = nil;
    if ((value = [attributes valueForKey:@"y1"])) {
        point1.y = [value floatValue];
    }
    
    value = nil;
    if ((value = [attributes valueForKey:@"x2"])) {
        point2.x = [value floatValue];
    }
    
    value = nil;
    if ((value = [attributes valueForKey:@"y2"])) {
        point2.y = [value floatValue];
    }
    
    value = nil;
    self.gradientTransform = CGAffineTransformIdentity;
    if ((value = [attributes valueForKey:@"gradientTransform"]))
    {
        self.gradientTransform = SVGTransformFromString(value);
    }
    
    //NSLog(@"New Gradient: id: %@, start: %@ end: %@", self.identifier, NSStringFromCGPoint(point1), NSStringFromCGPoint(point2));
    //NSLog(@"Attributes: %@", attributes);
}
    
- (CALayer *) layerWithShapeLayer:(CAShapeLayer *)shape
{
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.name = self.identifier;
    
    NSMutableArray *offsets = [NSMutableArray array];
    NSMutableArray *colors = [NSMutableArray array];

    // first we sort our stops by offset to make sure that they are ascending in value
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"offset" ascending:YES];
    NSArray *kids = [self.children sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
    
    // Now we add the offset and color to the arrays
    for (SVGElement *element in kids)
    {
        if (![element isKindOfClass:[SVGGradientStopElement class]])
            continue;
        SVGGradientStopElement *stop = (SVGGradientStopElement *)element;
        [offsets addObject:[NSNumber numberWithFloat:stop.offset]];
        
        CGColorRef color = CGColorCreateWithSVGColor(stop.color);
        [colors addObject:(id)color];
        //NSLog(@"Gradient stop: offset = %02.2f color = (%d,%d,%d,%d)", stop.offset, stop.color.r, stop.color.g, stop.color.b, stop.color.a);
    }
    
    // set the color and location properties on our gradient layer
    layer.colors = colors;
    layer.locations = offsets;
        
    // Set the gradient layer's start and end points.  If our gradientUnits property is 
    // SVGGradientUnitsUserSpace, we need to convert to a normalized unit coordinate space
    // where points are defined from 0.0 to 1.0.
    CGPoint p1 = CGPointApplyAffineTransform(self.point1, self.gradientTransform);
    CGPoint p2 = CGPointApplyAffineTransform(self.point2, self.gradientTransform);;
    
    //NSLog(@"--- %@ ---", self.identifier);

    CGRect shapeRect;
    if (self.gradientUnits == SVGGradientUnitsUserSpace)
    {
        shapeRect = shape.frame;
        p1.x -= shapeRect.origin.x;
        p1.y -= shapeRect.origin.y;
        p2.x -= shapeRect.origin.x;
        p2.y -= shapeRect.origin.y;
    } else if (self.gradientUnits == SVGGradientUnitsBoundingBox)
    {
        shapeRect = shape.bounds;
    }
        
    /*
    NSLog(@"document bounds: %@", NSStringFromCGRect(coordinateSpace));
    NSLog(@"shape frame: %@", NSStringFromCGRect(shape.frame));
    NSLog(@"original points: 1: %@ 2: %@", NSStringFromCGPoint(point1), NSStringFromCGPoint(point2));
    NSLog(@"transformed points: 1: %@ 2: %@", NSStringFromCGPoint(p1), NSStringFromCGPoint(p2));
     */
    
    // Normalize the start and end points relative to the shape rect
    CGFloat xMax = shapeRect.size.width;
    CGFloat yMax = shapeRect.size.height;
    
    p1.x = p1.x / xMax;
    p1.y = p1.y / yMax;
    p2.x = p2.x / xMax;
    p2.y = p2.y / yMax;
    

    //NSLog(@"normalized points: %@ / %@",  NSStringFromCGPoint(p1), NSStringFromCGPoint(p2));
    

    layer.startPoint = p1;
    layer.endPoint = p2;
    
    // Make a copy of the shape layer and apply it as a mask to the gradient layer
    // CALayer doesn't have a -[copy] method, so we have to copy the properties we need
    // into a new layer
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = shape.path;
    mask.name = [NSString stringWithFormat:@"%@(%@)", shape.name, self.identifier];

    
    layer.frame = shape.bounds;
    mask.frame = shape.bounds;
    [layer setMask:mask];
    
    return layer;
}


@end


@interface SVGGradientStopElement ()
@property (nonatomic, readwrite) SVGColor color;
@end

@implementation SVGGradientStopElement

@synthesize offset;
@synthesize color;

- (void) parseAttributes:(NSDictionary *)attributes
{
    [super parseAttributes:attributes];
    
    id value = nil;
    
    if ((value = [attributes valueForKey:@"offset"]))
    {
        self.offset = [value floatValue];
    }
    
    if ((value = [attributes valueForKey:@"stop-color"]))
    {
        self.color = SVGColorFromString([value UTF8String]);
    }
}


@end