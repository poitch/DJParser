//
//  Parser.h
//  TestGeo
//
//  Created by Jerome Poichet on 1/6/10.
//  Copyright 2010 Jerome Poichet. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import <UIKit/UIKit.h>


@interface DJParser : NSObject {
    NSString *json;
    
    NSScanner *scanner;
    
    NSCharacterSet *setArray;
    NSCharacterSet *setHash;
    NSCharacterSet *setValue;
    NSCharacterSet *setSpaces;
    
    NSMutableDictionary *stack;
}

@property (nonatomic, retain) NSString *json;

+ (DJParser *) parserWithString: (NSString *)json;
- (id) initWithString: (NSString *)json;

- (id) parse;

@end
