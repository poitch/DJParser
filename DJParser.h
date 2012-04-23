//
//  Parser.h
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
//

#if TARGET_OS_IPHONE
    #import <Foundation/Foundation.h>
    #import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

@interface DJParser : NSObject {
    NSString *json;
    
    NSScanner *scanner;
    
    NSCharacterSet *setArray;
    NSCharacterSet *setHash;
    NSCharacterSet *setValue;
    
    NSMutableDictionary *stack;
}

@property (nonatomic, retain) NSString *json;

+ (DJParser *) parserWithString: (NSString *)json;
- (id) initWithString: (NSString *)json;

- (id) parse;

+ (id) parse: (NSString *)json;
@end
