//
//  NetworkManager.m
//  ClaudeChat
//

#import "NetworkManager.h"

@implementation NetworkManager

static NetworkManager *sharedInstance = nil;

+ (NetworkManager *)sharedManager {
    if (sharedInstance == nil) {
        sharedInstance = [[NetworkManager alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // For Tiger compatibility, we'll default to using NSURLConnection
        useModernSSL = NO;
    }
    return self;
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

- (void)performHTTPSRequest:(NSURLRequest *)request
                  completion:(NetworkCompletionHandler)completion {
    // For Tiger compatibility, we'll use NSURLConnection
    // Using performSelectorInBackground for Tiger compatibility (no GCD)
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          request, @"request",
                          completion, @"completion",
                          nil];
    [self performSelectorInBackground:@selector(performRequestInBackground:) 
                            withObject:info];
}

- (void)performRequestInBackground:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSURLRequest *request = [info objectForKey:@"request"];
    NetworkCompletionHandler completion = [info objectForKey:@"completion"];
    
    NSError *error = nil;
    NSURLResponse *response = nil;
    
    // Synchronous request for simplicity (Tiger compatible)
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    // Call completion on main thread
    if (completion) {
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                data, @"data",
                                error, @"error",
                                completion, @"completion",
                                nil];
        [self performSelectorOnMainThread:@selector(callCompletionOnMainThread:)
                               withObject:result
                            waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)callCompletionOnMainThread:(NSDictionary *)result {
    NetworkCompletionHandler completion = [result objectForKey:@"completion"];
    NSData *data = [result objectForKey:@"data"];
    NSError *error = [result objectForKey:@"error"];
    
    if (completion) {
        completion(data, error);
    }
}

// For older OS X versions, we might need to implement custom SSL handling
// This would involve using OpenSSL directly or through a wrapper
- (void)performLegacyHTTPSRequest:(NSURLRequest *)request
                        completion:(NetworkCompletionHandler)completion {
    // This would be implemented using OpenSSL for Tiger compatibility
    // For now, we'll fall back to standard NSURLConnection
    [self performHTTPSRequest:request completion:completion];
}

@end