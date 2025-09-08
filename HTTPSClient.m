//
//  HTTPSClient.m
//  ClaudeChat
//
//  Simplified HTTPS client
//

#import "HTTPSClient.h"

@implementation HTTPSClient

- (id)initWithHost:(NSString *)host port:(int)portNum {
    self = [super init];
    if (self) {
        hostname = [host retain];
        port = portNum;
    }
    return self;
}

- (void)dealloc {
    [hostname release];
    [super dealloc];
}

- (NSData *)sendPOSTRequest:(NSString *)path
                    headers:(NSDictionary *)headers
                       body:(NSData *)bodyData {
    
    // Build URL
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%d%@", hostname, port, path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    
    // Add headers
    NSEnumerator *keyEnum = [headers keyEnumerator];
    NSString *key;
    while ((key = [keyEnum nextObject])) {
        NSString *value = [headers objectForKey:key];
        [request setValue:value forHTTPHeaderField:key];
    }
    
    // Send synchronous request
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
    
    if (error) {
        NSLog(@"HTTPSClient error: %@", [error localizedDescription]);
        NSLog(@"Error domain: %@, code: %ld", [error domain], (long)[error code]);
        return nil;
    }
    
    if (response) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"HTTP Status Code: %ld", (long)[httpResponse statusCode]);
        NSLog(@"Response headers: %@", [httpResponse allHeaderFields]);
    }
    
    if (responseData) {
        NSLog(@"Response data length: %lu bytes", (unsigned long)[responseData length]);
        // Log first 500 chars of response for debugging
        if ([responseData length] > 0) {
            NSString *responseStr = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
            if (responseStr && [responseStr length] > 0) {
                NSLog(@"Response preview: %@", [responseStr length] > 500 ? [responseStr substringToIndex:500] : responseStr);
            }
        }
    } else {
        NSLog(@"No response data received");
    }
    
    return responseData;
}

- (NSData *)sendGETRequest:(NSString *)path
                   headers:(NSDictionary *)headers {
    
    // Build URL
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%d%@", hostname, port, path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // Add headers
    NSEnumerator *keyEnum = [headers keyEnumerator];
    NSString *key;
    while ((key = [keyEnum nextObject])) {
        NSString *value = [headers objectForKey:key];
        [request setValue:value forHTTPHeaderField:key];
    }
    
    // Send synchronous request
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
    
    if (error) {
        NSLog(@"HTTPSClient error: %@", [error localizedDescription]);
        return nil;
    }
    
    return responseData;
}

@end