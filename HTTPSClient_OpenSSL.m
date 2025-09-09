//
//  HTTPSClient.m
//  ClaudeChat
//
//  HTTPS client with fallback support
//

#import "HTTPSClient.h"

// Check if we have OpenSSL available
// Just include OpenSSL directly - the Makefile handles the include paths
#define HAS_OPENSSL 1
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/bio.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>

@implementation HTTPSClient

- (id)initWithHost:(NSString *)host port:(int)portNum {
    self = [super init];
    if (self) {
        hostname = [host retain];
        port = portNum;
        
        // Initialize OpenSSL (not needed for OpenSSL 1.1.0+)
        #if OPENSSL_VERSION_NUMBER < 0x10100000L
        SSL_load_error_strings();
        SSL_library_init();
        OpenSSL_add_all_algorithms();
        #endif
    }
    return self;
}

- (void)dealloc {
    [hostname release];
    [super dealloc];
}

- (NSData *)sendRequestData:(NSData *)requestData {
    SSL_CTX *ctx = NULL;
    SSL *ssl = NULL;
    int sockfd = -1;
    NSMutableData *responseData = nil;
    
    // Create SSL context (use TLS_client_method if available, fall back to SSLv23)
    #if OPENSSL_VERSION_NUMBER >= 0x10100000L
        const SSL_METHOD *method = TLS_client_method();
    #else
        const SSL_METHOD *method = SSLv23_client_method();
    #endif
    ctx = SSL_CTX_new(method);
    if (!ctx) {
        NSLog(@"Failed to create SSL context");
        return nil;
    }
    
    // Set options for compatibility
    SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3);
    
    // Create socket
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        NSLog(@"Failed to create socket");
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Resolve hostname
    struct hostent *host_entry = gethostbyname([hostname UTF8String]);
    if (!host_entry) {
        NSLog(@"Failed to resolve hostname: %@", hostname);
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Setup server address
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    memcpy(&server_addr.sin_addr.s_addr, host_entry->h_addr_list[0], host_entry->h_length);
    
    // Connect to server
    if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        NSLog(@"Failed to connect to server");
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Create SSL connection
    ssl = SSL_new(ctx);
    SSL_set_fd(ssl, sockfd);
    
    // Set SNI hostname (only if available)
    #ifdef SSL_CTRL_SET_TLSEXT_HOSTNAME
    SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, (char *)[hostname UTF8String]);
    #endif
    
    // Perform SSL handshake
    if (SSL_connect(ssl) <= 0) {
        NSLog(@"SSL handshake failed");
        ERR_print_errors_fp(stderr);
        SSL_free(ssl);
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Send request data
    const char *requestBytes = [requestData bytes];
    int totalSent = 0;
    int requestLen = [requestData length];
    
    while (totalSent < requestLen) {
        int sent = SSL_write(ssl, requestBytes + totalSent, requestLen - totalSent);
        if (sent <= 0) {
            NSLog(@"Failed to send request");
            SSL_free(ssl);
            close(sockfd);
            SSL_CTX_free(ctx);
            return nil;
        }
        totalSent += sent;
    }
    
    // Read response
    responseData = [NSMutableData data];
    char buffer[4096];
    int bytes;
    
    while ((bytes = SSL_read(ssl, buffer, sizeof(buffer))) > 0) {
        [responseData appendBytes:buffer length:bytes];
    }
    
    // Clean up
    SSL_free(ssl);
    close(sockfd);
    SSL_CTX_free(ctx);
    
    return responseData;
}

- (NSData *)sendRequest:(NSString *)request {
    SSL_CTX *ctx = NULL;
    SSL *ssl = NULL;
    int sockfd = -1;
    NSMutableData *responseData = nil;
    
    // Create SSL context (use TLS_client_method if available, fall back to SSLv23)
    #if OPENSSL_VERSION_NUMBER >= 0x10100000L
        const SSL_METHOD *method = TLS_client_method();
    #else
        const SSL_METHOD *method = SSLv23_client_method();
    #endif
    ctx = SSL_CTX_new(method);
    if (!ctx) {
        NSLog(@"Failed to create SSL context");
        return nil;
    }
    
    // Set options for compatibility
    SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3);
    
    // Create socket
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        NSLog(@"Failed to create socket");
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Resolve hostname
    struct hostent *host_entry = gethostbyname([hostname UTF8String]);
    if (!host_entry) {
        NSLog(@"Failed to resolve hostname: %@", hostname);
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Setup server address
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    memcpy(&server_addr.sin_addr.s_addr, host_entry->h_addr_list[0], host_entry->h_length);
    
    // Connect to server
    if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        NSLog(@"Failed to connect to server");
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Create SSL connection
    ssl = SSL_new(ctx);
    SSL_set_fd(ssl, sockfd);
    
    // Set SNI hostname (only if available)
    #ifdef SSL_CTRL_SET_TLSEXT_HOSTNAME
    SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, (char *)[hostname UTF8String]);
    #endif
    
    // Perform SSL handshake
    if (SSL_connect(ssl) <= 0) {
        NSLog(@"SSL handshake failed");
        ERR_print_errors_fp(stderr);
        SSL_free(ssl);
        close(sockfd);
        SSL_CTX_free(ctx);
        return nil;
    }
    
    // Send request
    const char *requestStr = [request UTF8String];
    int totalSent = 0;
    int requestLen = strlen(requestStr);
    
    while (totalSent < requestLen) {
        int sent = SSL_write(ssl, requestStr + totalSent, requestLen - totalSent);
        if (sent <= 0) {
            NSLog(@"Failed to send request");
            SSL_free(ssl);
            close(sockfd);
            SSL_CTX_free(ctx);
            return nil;
        }
        totalSent += sent;
    }
    
    // Read response
    responseData = [NSMutableData data];
    char buffer[4096];
    int bytes;
    
    while ((bytes = SSL_read(ssl, buffer, sizeof(buffer))) > 0) {
        [responseData appendBytes:buffer length:bytes];
    }
    
    // Clean up
    SSL_free(ssl);
    close(sockfd);
    SSL_CTX_free(ctx);
    
    return responseData;
}

- (NSData *)sendPOSTRequest:(NSString *)path
                    headers:(NSDictionary *)headers
                       body:(NSData *)bodyData {
    
    // Build HTTP request
    NSMutableString *request = [NSMutableString string];
    [request appendFormat:@"POST %@ HTTP/1.1\r\n", path];
    [request appendFormat:@"Host: %@\r\n", hostname];
    [request appendFormat:@"Content-Length: %lu\r\n", (unsigned long)[bodyData length]];
    
    // Add custom headers
    NSEnumerator *keyEnum = [headers keyEnumerator];
    NSString *key;
    while ((key = [keyEnum nextObject])) {
        NSString *value = [headers objectForKey:key];
        [request appendFormat:@"%@: %@\r\n", key, value];
    }
    
    // Add connection close header
    [request appendString:@"Connection: close\r\n"];
    [request appendString:@"\r\n"];
    
    // Combine headers and body
    NSMutableData *fullRequest = [NSMutableData data];
    [fullRequest appendData:[request dataUsingEncoding:NSUTF8StringEncoding]];
    [fullRequest appendData:bodyData];
    
    // Send request directly as data
    NSData *response = [self sendRequestData:fullRequest];
    
    if (!response) {
        return nil;
    }
    
    // Parse response to extract body
    NSString *responseStr = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
    NSRange headerEnd = [responseStr rangeOfString:@"\r\n\r\n"];
    
    if (headerEnd.location != NSNotFound) {
        NSUInteger bodyStart = headerEnd.location + 4;
        if (bodyStart < [response length]) {
            return [response subdataWithRange:NSMakeRange(bodyStart, [response length] - bodyStart)];
        }
    }
    
    return nil;
}

- (NSData *)sendGETRequest:(NSString *)path
                   headers:(NSDictionary *)headers {
    
    // Build HTTP request
    NSMutableString *request = [NSMutableString string];
    [request appendFormat:@"GET %@ HTTP/1.1\r\n", path];
    [request appendFormat:@"Host: %@\r\n", hostname];
    
    // Add custom headers
    NSEnumerator *keyEnum = [headers keyEnumerator];
    NSString *key;
    while ((key = [keyEnum nextObject])) {
        NSString *value = [headers objectForKey:key];
        [request appendFormat:@"%@: %@\r\n", key, value];
    }
    
    // Add connection close header
    [request appendString:@"Connection: close\r\n"];
    [request appendString:@"\r\n"];
    
    // Send request and get response
    NSData *response = [self sendRequest:request];
    
    if (!response) {
        return nil;
    }
    
    // Parse response to extract body
    NSString *responseStr = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
    NSRange headerEnd = [responseStr rangeOfString:@"\r\n\r\n"];
    
    if (headerEnd.location != NSNotFound) {
        NSUInteger bodyStart = headerEnd.location + 4;
        if (bodyStart < [response length]) {
            return [response subdataWithRange:NSMakeRange(bodyStart, [response length] - bodyStart)];
        }
    }
    
    return nil;
}

@end