//
//  Parser.m
//  TestGeo
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

@interface DJParser (Private)

- (NSDictionary *) _parseHash;
- (NSArray *) _parseArray;
- (NSString *) _parseStraightValue;
- (NSString *) _parseValue;
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
    if (self = [super init]) {
        self.json = s;
    }
    return self;
}

- (void) dealloc
{
    [json release];
    [super dealloc];
}

- (id) parse
{
    scanner = [NSScanner scannerWithString: json];
    
    stack = [[NSMutableDictionary alloc] init];
    
    setArray = [NSCharacterSet characterSetWithCharactersInString: @"["];
    setHash = [NSCharacterSet characterSetWithCharactersInString: @"{"];
    setValue = [NSCharacterSet characterSetWithCharactersInString: @"\""];
    setSpaces = [NSCharacterSet characterSetWithCharactersInString: @" \n\r\t"];
    
    if ([scanner scanCharactersFromSet: setArray intoString: nil]) {
        return [self _parseArray];
    } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
        return [self _parseHash];
    } else {
        NSLog(@"Invalid JSON");
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
        
        while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
        [scanner scanUpToString: @":" intoString: &key];
        key = [key stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        key = [self _cleanupQuotes: key];

        // Skip :
        [scanner setScanLocation: [scanner scanLocation] + 1];
        // Eat spaces
        while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
        
        if ([scanner scanCharactersFromSet: setArray intoString: nil]) {
            value = [self _parseArray];
        } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
            value = [self _parseHash];
        } else if ([scanner scanCharactersFromSet: setValue intoString: &scrape]) {
            if ([scrape isEqualToString: @"\"\""]) {
                value = @"";
            } else {
                value = [self _parseValue];                
            }
        } else {
            value = [self _parseStraightValue];
        }
		
        [hash setObject: value forKey: key];
        
        // Eat spaces
        while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
        
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
	
	while (![scanner isAtEnd]) {
        id value = nil;
        NSString *scrape = nil;
        
        while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
        
        if ([scanner scanCharactersFromSet: setArray intoString: nil]) {
            value = [self _parseArray];
        } else if ([scanner scanCharactersFromSet: setHash intoString: nil]) {
            value = [self _parseHash];
        } else if ([scanner scanCharactersFromSet: setValue intoString: &scrape]) {
            if ([scrape isEqualToString: @"\"\""]) {
                value = @"";
            } else {
                value = [self _parseValue];                
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
            while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
            
            // If we have , then we have another value, if we have } then we are at the end of that hash
            if ([scanner scanString: @"," intoString: nil]) {
            } else if ([scanner scanString: @"]" intoString: nil]) {
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

- (NSString *) _parseStraightValue
{
    NSString *value = nil;
    NSCharacterSet *end = [NSCharacterSet characterSetWithCharactersInString: @" \n\t,}]"];
    [scanner scanUpToCharactersFromSet: end intoString: &value];
    while ([scanner scanCharactersFromSet: setSpaces intoString: nil]);
    return value;
}

- (NSString *) _parseValue
{
    // unescape the sequence
    NSMutableString *chars = [[[NSMutableString alloc] init] autorelease];

    while (![scanner isAtEnd] && [[scanner string] characterAtIndex: [scanner scanLocation]] != '\"') {
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
    [scanner setScanLocation: [scanner scanLocation] + 1];
    
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
