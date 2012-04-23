//
//  Parser.m
//  DJParser
//
//  Created by Jerome Poichet on 1/6/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//
//  License:
//      You can use the code in your own products
//      You can modify the code as you wish
//      You can use modified code in your products
//      You can redistribute the original code but retain that copyright notice
//      I’m not liable for anything you do with the code, no matter what.
//      You can’t use my name or other marks to promote your products based on the code.
//      Attribution in your product is welcome but not required
//

#import "DJParser.h"

//#define LEFT() NSLog(@"[LEFT] '%@'", [[scanner string] substringFromIndex: [scanner scanLocation]]);
#define LEFT()

// Comparison
// http://psionides.eu/2010/12/12/cocoa-json-parsing-libraries-part-2/


@interface DJParser (Private)

- (NSDictionary *) _parseHash;
- (NSArray *) _parseArray;
- (id) _parseStraightValue;
- (id) _parseQuotedValue;

- (id) _parseRawValue: (NSCharacterSet *)endDelimiters;
- (NSString *) _cleanupQuotes: (NSString *)input;

@end

@implementation DJParser

@synthesize json;

+ (DJParser *) parserWithString: (NSString *)s
{
    return [[[DJParser alloc] initWithString: s] autorelease];
}

- (id) initWithString: (NSString *)s
{
    if ((self = [super init])) {
        self.json = s;
    }
    return self;
}

- (void) dealloc
{
    [json release];
    [super dealloc];
}

+ (id) parse: (NSString *)json
{
    DJParser *parser = [DJParser parserWithString: json];
    return [parser parse];
}

- (id) parse
{
    NSString *scrape = nil;
    
    scanner = [NSScanner scannerWithString: json];
    [scanner setCharactersToBeSkipped: nil];
    
    stack = [[NSMutableDictionary alloc] init];
    
    setArray = [NSCharacterSet characterSetWithCharactersInString: @"["];
    setHash = [NSCharacterSet characterSetWithCharactersInString: @"{"];
    setValue = [NSCharacterSet characterSetWithCharactersInString: @"\""];
    
    if ([scanner scanCharactersFromSet: setArray intoString: nil]) {
        return [self _parseArray];
    } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
        return [self _parseHash];
    } else {
        [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
        if ([scanner scanCharactersFromSet: setValue intoString: &scrape]) {
            if ([scrape isEqualToString: @"\"\""]) {
                return @"";
            } else {
                return [self _parseQuotedValue];                
            }
        } else {
            id value = [self _parseStraightValue];
            
            // Non quoted JSON can only be true, false, null or numerical
            if ([value isKindOfClass: [NSString string]]) {
               NSLog(@"Invalid JSON");
               return nil;
            }
            return value;
        }
    }
    return nil;
}

@end

@implementation DJParser (Private)

- (NSDictionary *) _parseHash
{
    NSMutableDictionary *hash = [[NSMutableDictionary alloc] init];
    
	// Test for empty hash
	if ([[scanner string] characterAtIndex: [scanner scanLocation]] == '}') {
		// skip it
        [scanner setScanLocation: [scanner scanLocation] + 1];
		
		return [hash autorelease];
	}
	
    while (![scanner isAtEnd]) {
        NSString *key = nil;
        id value = nil;
        NSString *scrape = nil;

        LEFT();
        
        // Eat leading spaces
        [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
        
        LEFT();
        
        [scanner scanUpToString: @":" intoString: &key];
        
        LEFT();
        
        key = [key stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        key = [self _cleanupQuotes: key];

        //NSLog(@"[KEY] '%@'", key);
        
        if ([key isEqualToString: @"}"]) {
            return hash;
        }
        
        if ([scanner isAtEnd]) {
            NSLog(@"Invalid hash");
            return nil;
        }
        
        // Skip :
        [scanner setScanLocation: [scanner scanLocation] + 1];
        if ([scanner isAtEnd]) {
            NSLog(@"Invalid hash");
            return nil;
        }
        
        // Eat spaces
        [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];

        if ([scanner scanCharactersFromSet: setArray intoString: &scrape]) {
            // Could be multiple [ in a row, scan back if necessary
            int depth = [scrape length] - 1;
            [scanner setScanLocation: [scanner scanLocation] - depth];
            value = [self _parseArray];
        } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
            value = [self _parseHash];
        } else if ([scanner scanCharactersFromSet: setValue intoString: &scrape]) {
            if ([scrape isEqualToString: @"\"\""]) {
                value = @"";
            } else {
                value = [self _parseQuotedValue];                
            }
        } else {
            value = [self _parseStraightValue];
        }
        
        //NSLog(@"[VALUE] '%@'", value);
		
        if (!value) {
            return nil;
        }
        
        [hash setObject: value forKey: key];
        
        // Eat spaces
        [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
        
        // If we have , then we have another value, if we have } then we are at the end of that hash
        if ([scanner scanString: @"," intoString: nil]) {
        } else if ([scanner scanString: @"}" intoString: nil]) {
            break;
        } else {
            // Invalid json
            [hash release];
            NSLog(@"Invalid Hash");
            return nil;
        }
        
    }
    
    return [hash autorelease];
}

- (NSArray *) _parseArray
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
   
	// Test for empty hash
	if ([[scanner string] characterAtIndex: [scanner scanLocation]] == ']') {
		[scanner setScanLocation: [scanner scanLocation] + 1];
		return [array autorelease];
	}
	
    //NSLog(@"Starting array %@...", [[[scanner string] substringFromIndex: [scanner scanLocation]] substringToIndex: 32]);
    
	while (![scanner isAtEnd]) {
        id value = nil;
        NSString *scrape = nil;
        
        LEFT();
        
        [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
        
        LEFT();
        
        if ([scanner scanCharactersFromSet: setArray intoString: nil]) {
            value = [self _parseArray];
        } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
            value = [self _parseHash];
        } else if ([scanner scanCharactersFromSet: setValue intoString: &scrape]) {
            if ([scrape isEqualToString: @"\"\""]) {
                value = @"";
            } else {
                value = [self _parseQuotedValue];                
            }
        } else {
            value = [self _parseStraightValue];
        }
                
        if (!value) {
            // Empty array
            if ([scanner scanString: @"]" intoString: nil]) {
                break;
            } else {
                // Invalid Array
                [array release];
                NSLog(@"Invalid array");
                return nil;
                
            }
        } else {
            [array addObject: value];
            
            // Eat spaces
            [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
            
            // If we have , then we have another value, if we have } then we are at the end of that hash
            if ([scanner scanString: @"," intoString: nil]) {
            } else if ([scanner scanString: @"]" intoString: nil]) {
                // End of array
                break;
            } else {
                // Invalid Array
                [array release];
                NSLog(@"Invalid array");
                return nil;
            }            
        }
    }
    return [array autorelease];
}

- (id) _parseStraightValue
{
    /*
    NSString *value = nil;
    NSCharacterSet *end = [NSCharacterSet characterSetWithCharactersInString: @" \n\t,}]"];
    [scanner scanUpToCharactersFromSet: end intoString: &value];
    while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);    
    return value;
    */
    //NSLog(@"[S]");
    id value = [self _parseRawValue: [NSCharacterSet characterSetWithCharactersInString: @" \n\t,}]"]];
    [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: nil];
    
    if (!value) {
        return nil;
    }
    
    //NSLog(@" -> %@ (%@)", value, [[scanner string] substringFromIndex: [scanner scanLocation]]);
    if ([value isEqualToString: @"true"]) {
        return [NSNumber numberWithBool: YES];
    } else if ([value isEqualToString: @"false"]) {
        return [NSNumber numberWithBool: NO];
    } else if ([value isEqualToString: @"null"]) {
        return [NSNull null];
    }
    
    NSScanner *valueScanner = [NSScanner scannerWithString: value];
    NSDecimal decimalValue;
    if ([valueScanner scanDecimal: &decimalValue]) {
        return [NSDecimalNumber decimalNumberWithDecimal: decimalValue];
    }

    
    return value;
}

- (id) _parseQuotedValue
{
    //NSLog(@"[Q]");
    id value = [self _parseRawValue: [NSCharacterSet characterSetWithCharactersInString: @"\""]];
    if (![scanner isAtEnd]) [scanner setScanLocation: [scanner scanLocation] + 1];
    return value;

}

- (id) _parseRawValue: (NSCharacterSet *)endDelimiters
{
    // unescape the sequence
    NSMutableString *chars = nil;


    //NSLog(@" <- '%@'", [[scanner string] substringFromIndex: [scanner scanLocation]]);
    
    while (![scanner isAtEnd] && ![endDelimiters characterIsMember: [[scanner string] characterAtIndex: [scanner scanLocation]]]) {
        if (!chars) chars = [[[NSMutableString alloc] init] autorelease];

        //NSLog(@" . '%@'", [[scanner string] substringFromIndex: [scanner scanLocation]]);

        unichar currentChar = [[scanner string] characterAtIndex: [scanner scanLocation]];  
        unichar nextChar;

        if (currentChar != '\\') {
            [chars appendFormat:@"%C", currentChar];
        } else {
            nextChar = [[scanner string] characterAtIndex: ([scanner scanLocation]+1)];

            switch (nextChar) {
				case '\"':
					[chars appendString:@"\""];
					break;
				case '\\':
					[chars appendString:@"\\"];
					break;
				case '/':
					[chars appendString:@"/"];
					break;
				case 'b':
					[chars appendString:@"\b"];
					break;
				case 'f':
					[chars appendString:@"\f"];
					break;
				case 'n':
					[chars appendString:@"\n"];
					break;
				case 'r':
					[chars appendString:@"\r"];
					break;
				case 't':
					[chars appendString:@"\t"];
					break;
				case 'u': // unicode sequence - get string of hex chars, convert to int, convert to unichar, append
                {
                    NSScanner *s = [NSScanner scannerWithString: [[scanner string] substringWithRange: NSMakeRange([scanner scanLocation] + 2, 4)]];
                    unsigned unicodeHexValue;
                    [s scanHexInt: &unicodeHexValue];
                    [chars appendFormat: @"%C", unicodeHexValue];
                    [scanner setScanLocation: [scanner scanLocation] + 4];
                }
                    
                    
					break;
				default:
					[chars appendFormat:@"\\%C", nextChar];
					break;
            }
            [scanner setScanLocation: [scanner scanLocation] + 1];
        }
        [scanner setScanLocation: [scanner scanLocation] + 1];    
    }
    //if (![scanner isAtEnd]) [scanner setScanLocation: [scanner scanLocation] + 1];
    
    
    return chars;
}




- (NSString *) _cleanupQuotes: (NSString *)input
{
    if ([[input substringToIndex: 1] isEqualToString: @"\""]) {
        NSRange r = NSMakeRange(1, [input length] - 2);
        return [input substringWithRange: r];
    }
    return input;
}


@end
