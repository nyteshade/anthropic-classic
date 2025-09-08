//
//  HTTPSClient.h
//  ClaudeChat
//
//  Simple HTTPS client using OpenSSL for Tiger compatibility
//

#ifndef HTTPS_CLIENT_H
#define HTTPS_CLIENT_H

#import <Foundation/Foundation.h>

@interface HTTPSClient : NSObject {
    NSString *hostname;
    int port;
}

// Initialize with hostname and port
- (id)initWithHost:(NSString *)host port:(int)portNum;

// Send HTTPS POST request
- (NSData *)sendPOSTRequest:(NSString *)path
                    headers:(NSDictionary *)headers
                       body:(NSData *)bodyData;

// Send HTTPS GET request
- (NSData *)sendGETRequest:(NSString *)path
                   headers:(NSDictionary *)headers;

@end

#endif