//
//  SVGElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGElement.h"

@interface SVGElement ()

@property (nonatomic, copy) NSString *stringValue;

@end


@implementation SVGElement

@synthesize document = _document;

@synthesize children = _children;
@synthesize stringValue = _stringValue;
@synthesize localName = _localName;

@synthesize identifier = _identifier;

+ (BOOL)shouldStoreContent {
	return NO;
}

- (id)initWithDocument:(SVGDocument *)aDocument name:(NSString *)name {
	self = [super init];
	if (self) {
		_document = aDocument;
		_children = [[NSMutableArray alloc] init];
		_localName = [name retain];
		
		[self loadDefaults];
	}
	return self;
}

- (void)dealloc {
	[_children release];
	[_stringValue release];
	[_localName release];
	[_identifier release];
	
	[super dealloc];
}



- (void)loadDefaults {
	// to be overriden by subclasses
}

- (void)addChild:(SVGElement *)element {
	[_children addObject:element];
}

- (SVGElement *)childWithId:(NSString *)elementId recursive:(BOOL)recursive
{
    for (SVGElement *element in self.children)
    {
        if ([element.identifier isEqualToString:elementId])
        {
            return element;
        }
        
        if (recursive) {
            SVGElement *e = [element childWithId:elementId recursive:YES];
            if (e)
                return e;
        }
    }
    return nil;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	// to be overriden by subclasses
	// make sure super implementation is called
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"id"])) {
		_identifier = [value copy];
	}
}

- (void)parseContent:(NSString *)content {
	self.stringValue = content;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p | localName=%@ | identifier=%@ | stringValue=%@ | children=%d>", 
			[self class], self, _localName, _identifier, _stringValue, [_children count]];
}

@end
