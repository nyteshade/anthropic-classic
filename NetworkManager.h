//
//  NetworkManager.h
//  ClaudeChat
//
//  Network abstraction layer for OS X Tiger compatibility
//

#import <Foundation/Foundation.h>

// For Tiger compatibility, we'll use a selector-based callback instead of blocks
@protocol NetworkManagerDelegate
- (void)networkRequestCompleted:(NSData *)data error:(NSError *)error context:(id)context;
@end

// Define block type for newer OS versions
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
typedef void (^NetworkCompletionHandler)(NSData *data, NSError *error);
#else
typedef id NetworkCompletionHandler;
#endif

@interface NetworkManager : NSObject {
    BOOL useModernSSL;
}

+ (NetworkManager *)sharedManager;

- (void)performHTTPSRequest:(NSURLRequest *)request
                  completion:(NetworkCompletionHandler)completion;

- (NSMutableURLRequest *)createRequestWithURL:(NSURL *)url
                                        method:(NSString *)method
                                       headers:(NSDictionary *)headers
                                          body:(NSData *)body;

@end