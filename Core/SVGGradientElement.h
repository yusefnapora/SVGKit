//
//  SVGGradientElement.h
//  SVGPad
//
//  Created by Yusef Napora on 10/15/11.
//  Copyright (c) 2011 SefCo. All rights reserved.
//

#import "SVGElement.h"
#import "SVGUtils.h"

typedef enum {
    SVGGradientUnitsUserSpace,
    SVGGradientUnitsBoundingBox
} SVGGradientUnitType;

@interface SVGGradientElement : SVGElement 

@property (nonatomic, assign) CGPoint point1;
@property (nonatomic, assign) CGPoint point2;
@property (nonatomic, assign) SVGGradientUnitType gradientUnits;

- (CALayer *) layerWithShapeLayer:(CAShapeLayer *)shape;

@end



@interface SVGGradientStopElement : SVGElement

@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, readonly) SVGColor color;

@end