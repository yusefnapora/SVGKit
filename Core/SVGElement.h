//
//  SVGElement.h
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class SVGDocument;

@interface SVGElement : NSObject {
  @private
	NSMutableArray *_children;
}

@property (nonatomic, readonly) __weak SVGDocument *document;

@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly, copy) NSString *stringValue;
@property (nonatomic, readonly) NSString *localName;

@property (nonatomic, readonly) NSString *identifier; // 'id' is reserved

+ (BOOL)shouldStoreContent; // to optimize parser, default is NO

- (id)initWithDocument:(SVGDocument *)aDocument name:(NSString *)name;

- (void)loadDefaults; // should be overriden to set element defaults

- (SVGElement *) childWithId:(NSString *)elementId recursive:(BOOL)recursive;

@end


@protocol SVGLayeredElement < NSObject >

- (CALayer *)layer;
- (void)layoutLayer:(CALayer *)layer;

@end
