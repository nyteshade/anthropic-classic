//
//  NetworkManager_Tiger.m
//  ClaudeChat
//
//  Simplified network layer for Tiger compatibility
//

#import "NetworkManager_Tiger.h"

@implementation NetworkManager

static NetworkManager *sharedInstance = nil;

+ (NetworkManager *)sharedManager {
    if (sharedInstance == nil) {
        sharedInstance = [[NetworkManager alloc] init];
    }
    return sharedInstance;
}

- (NSMutableURLRequest *)createRequestWithURL:(NSURL *)url
                                        method:(NSString *)method
                                       headers:(NSDictionary *)headers
                                          body:(NSData *)body {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setTimeoutInterval:30.0];
    
    // Set headers
    if (headers) {
        NSEnumerator *keyEnum = [headers keyEnumerator];
        NSString *key;
        while ((key = [keyEnum nextObject])) {
            [request setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    // Set body
    if (body) {
        [request setHTTPBody:body];
    }
    
    return request;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                   returningResponse:(NSURLResponse **)response
                               error:(NSError **)error {
    return [NSURLConnection sendSynchronousRequest:request
                                  returningResponse:response
                                              error:error];
}

@end