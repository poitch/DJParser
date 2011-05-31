//
//  DJParser_UnitTests.m
//  DJParser
//
//  Created by Jerome Poichet on 11/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DJParser_UnitTests.h"

#import "DJParser.h"

@implementation DJParser_UnitTests

- (void)testTrue
{
    NSString *resp = [DJParser parse: @"true"];
    STAssertTrue([resp isEqualToString: @"true"], @"Scan return failure.");
}

@end
