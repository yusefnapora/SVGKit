//
//  SVGShapeElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGShapeElement.h"

#import "CGPathAdditions.h"
#import "SVGDefsElement.h"
#import "SVGDocument.h"
#import "SVGElement+Private.h"
#import "SVGGradientElement.h"


@implementation SVGShapeElement

#define IDENTIFIER_LEN 256

@synthesize opacity = _opacity;

@synthesize fillType = _fillType;
@synthesize fillColor = _fillColor;

@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;
@synthesize miterLimit = _miterLimit;

@synthesize path = _path;

@synthesize gradientId = _gradientId;

- (void)finalize {
	CGPathRelease(_path);
	[super finalize];
}

- (void)dealloc {
	CGPathRelease(_path);
	[super dealloc];
}

- (void)loadDefaults {
	_opacity = 1.0f;
	
	_fillColor = SVGColorMake(0, 0, 0, 255);
	_fillType = SVGFillTypeSolid;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"opacity"])) {
		_opacity = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"fill"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_fillType = SVGFillTypeNone;
		}
		else if (!strncmp(cvalue, "url", 3)) {
			//NSLog(@"Gradients are no longer supported");
			_fillType = SVGFillTypeGradient;
            
            // save the url of the gradient for later. we look it up when our layer is requested, after the whole document is loaded
            NSMutableString *urlString = [[value stringByReplacingOccurrencesOfString:@"url(#" withString:@""] mutableCopy];
            [urlString replaceCharactersInRange:NSMakeRange([urlString length] - 1, 1) withString:@""];
            self.gradientId = urlString;
            [urlString release];
		}
		else {
			_fillColor = SVGColorFromString([value UTF8String]);
			_fillType = SVGFillTypeSolid;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-width"])) {
		_strokeWidth = [value floatValue];
	}
    if ((value = [attributes objectForKey:@"stroke-miterlimit"])) {
        _miterLimit = [value floatValue];
    }
	
	if ((value = [attributes objectForKey:@"stroke"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_strokeWidth = 0.0f;
		}
		else {
			_strokeColor = SVGColorFromString(cvalue);
			
			if (!_strokeWidth)
				_strokeWidth = 1.0f;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-opacity"])) {
		_strokeColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
	
	if ((value = [attributes objectForKey:@"fill-opacity"])) {
		_fillColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
}

- (void)loadPath:(CGPathRef)aPath {
	if (_path) {
		CGPathRelease(_path);
		_path = NULL;
	}
	
	if (aPath) {
		_path = CGPathCreateCopy(aPath);
	}
}


- (CALayer *)layer {
	CAShapeLayer *shape = [CAShapeLayer layer];
	shape.name = self.identifier;
	shape.opacity = _opacity;
	
#if OUTLINE_SHAPES
	
#if TARGET_OS_IPHONE
	shape.borderColor = [UIColor redColor].CGColor;
#endif
	
	shape.borderWidth = 1.0f;
#endif
	
	CGRect rect = CGRectIntegral(CGPathGetPathBoundingBox(_path));
	
	CGPathRef path = CGPathCreateByOffsettingPath(_path, rect.origin.x, rect.origin.y);
	
	shape.path = path;
	CGPathRelease(path);
	
	shape.frame = rect;
    
    if ([shape respondsToSelector:@selector(setShouldRasterize:)]) {
		[shape performSelector:@selector(setShouldRasterize:)
					withObject:[NSNumber numberWithBool:YES]];
	}
	
	if (_strokeWidth) {
		shape.lineWidth = _strokeWidth;
		shape.strokeColor = CGColorCreateWithSVGColor(_strokeColor);
	}
	
    if (_miterLimit) {
        shape.miterLimit = _miterLimit;
    }

	if (_fillType == SVGFillTypeNone) {
		shape.fillColor = nil;
	}
	else if (_fillType == SVGFillTypeSolid) {
		shape.fillColor = CGColorCreateWithSVGColor(_fillColor);
	} else if (_fillType == SVGFillTypeGradient) {
        SVGElement *element = [self.document childWithId:self.gradientId recursive:YES];
        if (!element || ![element isKindOfClass:[SVGGradientElement class]])
        {
            NSLog(@"No gradient found with id %@", self.gradientId);
            _fillType = SVGFillTypeNone;
            shape.fillColor = nil;
            return shape;
        }
        SVGGradientElement *gradient = (SVGGradientElement *)element;
        CALayer * gradientLayer = [gradient layerWithShapeLayer:shape];
        [shape addSublayer:gradientLayer];
    }
	
	return shape;
}

- (void)layoutLayer:(CALayer *)layer { }

@end
