//
//  SVGPathParserHelper.m
//  SVGPad
//
//  Created by Yusef Napora on 10/16/11.
//  Copyright (c) 2011 SefCo. All rights reserved.
//

#import "SVGPathParserHelper.h"

@interface SVGPathParserHelper ()

@property (nonatomic, assign) UniChar currentChar;
@property (nonatomic, assign) size_t stringLength;

- (UniChar) read;
- (CGFloat) buildFloat:(int)mantissa exponent:(int)exponent;

@end


static double PowersOfTen[128];

@implementation SVGPathParserHelper

@synthesize svgString;
@synthesize position;
@synthesize currentChar;
@synthesize stringLength;

+ (void) initialize
{
    for (int i = 0; i < 128; i++) {
        PowersOfTen[i] = pow(10, i);
    }
}

- (id) initWithString:(NSString *)string position:(NSUInteger)pos
{
    self = [super init];
    if (self)
    {
        self.svgString = string;
        self.position = pos;
        self.stringLength = [string length];
        self.currentChar = [svgString characterAtIndex:position];
    }
    return self;
}

- (UniChar) read
{
    if (position < stringLength)
    {
        position++;
    }
        
    if (position == stringLength)
    {
        return '\0';
    }
    return [svgString characterAtIndex:position];
}


- (void) skipWhitespace
{
    while (position < stringLength) {
        UniChar c = [svgString characterAtIndex:position];
        switch (c) {
            case ' ':
            case ',':
            case '\n':
            case '\t':
                [self advance];
                break;
            default:
                return;
        }
    }
}

- (void) skipNumberSeparator
{
    while (position < stringLength) {
        char c = [svgString characterAtIndex:position];
        switch (c) {
            case ' ':
            case ',':
            case '\n':
            case '\t':
                [self advance];
                break;
            default:
                return;
        }
    }
}

- (void) advance
{
    currentChar = [self read];
}

- (CGFloat) nextFloat
{
    [self skipWhitespace];
    CGFloat f = [self parseFloat];
    [self skipNumberSeparator];
    return f;
}

/**
 * Parses the content of the buffer and converts it to a float.
 */
- (CGFloat) parseFloat
{
    int     mant     = 0;
    int     mantDig  = 0;
    BOOL mantPos  = YES;
    BOOL mantRead = NO;
    
    int     exp      = 0;
    int     expDig   = 0;
    int     expAdj   = 0;
    BOOL    expPos   = YES;
    
    switch (currentChar) {
        case '-':
            mantPos = NO;
            // fallthrough
        case '+':
            [self advance];
    }
    
    switch (currentChar) {
        default:
            return NAN;
            
        case '.':
            break;
            
        case '0':
            mantRead = YES;
            for (;;) {
                [self advance];
                switch (currentChar) {
                    default:
                        return 0.0f;
                    case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                        goto endloop1;
                    case '.': case 'e': case 'E':
                        goto m1;

                    case '0':
                        continue;
                }
            }
        
        endloop1:
        
        
        case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
            mantRead = YES;
             for (;;) {
                if (mantDig < 9) {
                    mantDig++;
                    mant = mant * 10 + (currentChar - '0');
                } else {
                    expAdj++;
                }
                [self advance];
                switch (currentChar) {
                    default:
                        goto m1;
                    case '0': case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                        continue;
                }
             }
    }
    
    m1:
    
    if (currentChar == '.') {
        [self advance];
        
        switch (currentChar) {
            default:
            case 'e': case 'E':
                if (!mantRead) {
                    //reportUnexpectedCharacterError( current );
                    return 0.0f;
                }
                break;
                
            case '0':
                if (mantDig == 0) {
                    for (;;) {
                        [self advance];
                        expAdj--;
                        switch (currentChar) {
                            case '1': case '2': case '3': case '4':
                            case '5': case '6': case '7': case '8': case '9':
                                goto endloop2;
                            default:
                                if (!mantRead) {
                                    return 0.0f;
                                }
                                goto m2;
                            case '0':
                                continue;
                        }
                    }
                }
            endloop2:
            case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
                for (;;) {
                    if (mantDig < 9) {
                        mantDig++;
                        mant = mant * 10 + (currentChar - '0');
                        expAdj--;
                    }
                    [self advance];
                    switch (currentChar) {
                        default:
                            goto endloop3;
                        case '0': case '1': case '2': case '3': case '4':
                        case '5': case '6': case '7': case '8': case '9':
                            continue;
                    }
                }
            endloop3:
                ;
        }
    }
    m2:
    
    switch (currentChar) {
        case 'e': case 'E':
            [self advance];
            switch (currentChar) {
                default:
                    //reportUnexpectedCharacterError( current );
                    return 0.0f;
                case '-':
                    expPos = NO;
                case '+':
                    [self advance];
                    switch (currentChar) {
                        default:
                            //reportUnexpectedCharacterError( current );
                            return 0.0f;
                        case '0': case '1': case '2': case '3': case '4':
                        case '5': case '6': case '7': case '8': case '9':
                            ;
                    }
                case '0': case '1': case '2': case '3': case '4':
                case '5': case '6': case '7': case '8': case '9':
                    ;
            }
            
        switch (currentChar) {
            case '0':
                for (;;) {
                    [self advance];
                    switch (currentChar) {
                        case '1': case '2': case '3': case '4':
                        case '5': case '6': case '7': case '8': case '9':
                            goto endloop4;
                        default:
                            goto en;
                        case '0':
                            continue;
                    }
                }
                endloop4:
                
            case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
            for (;;) {
                if (expDig < 3) {
                    expDig++;
                    exp = exp * 10 + (currentChar - '0');
                }
                [self advance];
                switch (currentChar) {
                    default:
                        goto endloop5;
                    case '0': case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                        continue;
                }
            }
            endloop5:
                ;
        }
            
        en:
        default:
            ;
    }
    
    if (!expPos) {
        exp = -exp;
    }
    exp += expAdj;
    if (!mantPos) {
        mant = -mant;
    }
    
    return [self buildFloat:mant  exponent:exp];
}

/**
 * Computes a float from mantissa and exponent.
 */
- (CGFloat) buildFloat:(int)mantissa exponent:(int)exponent
{
    if (exponent < -125 || mantissa == 0) {
        return 0.0f;
    }
    
    if (exponent >=  128) {
        return (mantissa > 0) ? INFINITY : -INFINITY;
    }
    
    if (exponent == 0) {
        return mantissa;
    }
    
    if (mantissa >= (1 << 26)) {
        mantissa++;  // round up trailing bits if they will be dropped.
    }
    
    return (float) ((exponent > 0) ? mantissa * PowersOfTen[exponent] : mantissa / PowersOfTen[-exponent]);
}

@end
