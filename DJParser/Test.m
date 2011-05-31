#import <Foundation/Foundation.h>

#import "DJParser.h"

void test(NSString * json)
{
    NSLog(@"[TESTING] '%@'", json);
    id res = [DJParser parse: json];
    NSLog(@"Returned '%@' <%@>", res, [res className]);
    
}

int main (int argc, const char * argv[]) 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    id res = [DJParser parse: @"2470086426"];
    NSLog(@"Returned '%@' <%@>", res, [res className]);
    NSLog(@"%@", [res description]);
    
#if 0
    
    test(@"true");
    test(@"false");
    test(@"null");
    test(@"3.14");
    test(@"3.14e4");
    test(@"\"Hello world.\"");

    test(@"\"\\r\\n\\f\\b\\\\\"");
    test(@"\"Hello\r\rworld.\"");
    test(@"\"x\\u0078xx\"");
    test(@"{\"bar\":\"foo\"}");
    test(@"{\"bar\":{\"bar\":\"foo\"}}");
    
    test(@"[\"bar\",\"foo\"]");
    test(@"[\"bar\",[\"bar\",\"foo\"]]");
    test(@"    \"Hello world.\"      ");
    test(@"[ true, false ]");
    test(@"{ \"x\" : [ 1 , 2 ] }");
    test(@"[]");
    test(@"[ ]");
    test(@"{}");
    test(@"{ }");
    test(@"{\"Foo\":{}}");
    test(@"\"\"");
    test(@"   \"\"   ");
    
    NSString *theSource;
    
    theSource = @"{\"status\": \"ok\", \"operation\": \"new_task\", \"task\": {\"status\": 0, \"updated_at\": {}, \"project_id\": 7179, \"dueDate\": null, \"creator_id\": 1, \"type_id\": 0, \"priority\": 1, \"id\": 37087, \"summary\": \"iPhone test\", \"description\": null, \"creationDate\": {}, \"owner_id\": 1, \"noteCount\": 0, \"commentCount\": 0}}";
    test(theSource);
    
    theSource = @"{\"status\": \"ok\", \"operation\": \"new_task\", \"task\": {\"status\": 0, \"project_id\": 7179, \"dueDate\": null, \"creator_id\": 1, \"type_id\": 0, \"priority\": 1, \"id\": 37087, \"summary\": \"iPhone test\", \"description\": null, \"owner_id\": 1, \"noteCount\": 0, \"commentCount\": 0}}";
    test(theSource);
    
    theSource = @"{\"r\":[{\"name\":\"KEXP\",\"desc\":\"90.3 - Where The Music Matters\",\"icon\":\"\\/img\\/channels\\/radio_stream.png\",\"audiostream\":\"http:\\/\\/kexp-mp3-1.cac.washington.edu:8000\\/\",\"type\":\"radio\",\"stream\":\"fb8155000526e0abb5f8d1e02c54cb83094cffae\",\"relay\":\"r2b\"}]}";
    test(theSource);
    
    // Failure modes
    theSource = @"{\"a\": [ { ] }";
    test(theSource);
    
    theSource = @"\"";
    test(theSource);

    theSource = @">";
    test(theSource);
#endif
    
    [pool drain];
    return 0;
}
