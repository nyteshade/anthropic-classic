//
//  NetworkManager_Tiger.h
//  ClaudeChat
//
//  Simplified network layer for Tiger compatibility
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedManager;

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                   returningResponse:(NSURLResponse **)response
                               error:(NSError **)error;

- (NSMutableURLRequest *)createRequestWithURL:(NSURL *)url
                                        method:(NSString *)method
                                       headers:(NSDictionary *)headers
                                          body:(NSData *)body;

@end