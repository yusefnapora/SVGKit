//
//  SVGPathParserHelper.h
//  SVGPad
//
//  Created by Yusef Napora on 10/16/11.
//  Copyright (c) 2011 SefCo. All rights reserved.
//

#import <Foundation/Foundation.h>

// Parse numbers from SVG text.  Based on svg-android ParserHelper (Apache 2 Licence), which is based on the Batik Number Parser (Apache 2 License)
@interface SVGPathParserHelper : NSObject

@property (nonatomic, retain) NSString *svgString;
@property (nonatomic, assign) NSUInteger position;

- (id) initWithString:(NSString *)string position:(NSUInteger)position;
- (void) skipWhitespace;
- (void) skipNumberSeparator;
- (void) advance;
- (CGFloat) parseFloat;
- (CGFloat) nextFloat;


@end
