//
//  ClaudeAPIManager_Tiger.m
//  ClaudeChat
//
//  Tiger-compatible version using delegate pattern
//

#import "ClaudeAPIManager.h"
#import "HTTPSClient.h"
#import "AppDelegate.h"
#include "yyjson.h"
#include <string.h>

@implementation ClaudeAPIManager

- (id)init {
    self = [super init];
    if (self) {
        conversationHistory = [[NSMutableArray alloc] init];
        delegate = nil;
    }
    return self;
}

- (void)dealloc {
    [conversationHistory release];
    delegate = nil;
    [super dealloc];
}

- (void)setDelegate:(id)aDelegate {
    delegate = aDelegate;
}

- (void)sendMessage:(NSString *)message withAPIKey:(NSString *)apiKey {
    // Retain for background thread
    [message retain];
    [apiKey retain];
    
    // Create info dictionary
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
                          message, @"message",
                          apiKey, @"apiKey",
                          nil];
    
    [self performSelectorInBackground:@selector(sendMessageInBackground:) 
                            withObject:info];
    
    [info release];
}

- (void)addToHistory:(NSString *)message isUser:(BOOL)isUser {
    NSDictionary *historyMessage = [NSDictionary dictionaryWithObjectsAndKeys:
                                    isUser ? @"user" : @"assistant", @"role",
                                    message, @"content",
                                    nil];
    [conversationHistory addObject:historyMessage];
}

- (void)sendMessageInBackground:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *message = [[info objectForKey:@"message"] retain];
    NSString *apiKey = [[info objectForKey:@"apiKey"] retain];
    
    // Get selected model from AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *model = [appDelegate selectedModel];
    if (!model || [model length] == 0) {
        model = @"claude-3-haiku-20240307";  // Default to Haiku 3
    }
    
    // Add message to history
    NSDictionary *userMessage = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"user", @"role",
                                  message, @"content",
                                  nil];
    [conversationHistory addObject:userMessage];
    
    // Prepare request body
    NSDictionary *requestBody = [NSDictionary dictionaryWithObjectsAndKeys:
                                  model, @"model",
                                  conversationHistory, @"messages",
                                  [NSNumber numberWithInt:1024], @"max_tokens",
                                  nil];
    
    // For Tiger, we need to manually create JSON
    NSString *jsonString = [self dictionaryToJSON:requestBody];
    NSData *bodyData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Use HTTPSClient for the request
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                             apiKey, @"x-api-key",
                             @"2023-06-01", @"anthropic-version",
                             @"application/json", @"content-type",
                             nil];
    
    NSLog(@"Sending request to Claude API");
    NSLog(@"Request headers: %@", headers);
    NSLog(@"Request body: %@", jsonString);
    
    // Create HTTPS client
    HTTPSClient *client = [[[HTTPSClient alloc] initWithHost:@"api.anthropic.com" port:443] autorelease];
    
    // Send request
    NSData *data = [client sendPOSTRequest:@"/v1/messages"
                                   headers:headers
                                      body:bodyData];
    
    if (data) {
        NSLog(@"Received data of length: %lu", (unsigned long)[data length]);
        
        NSString *jsonResponse = [[[NSString alloc] initWithData:data 
                                                         encoding:NSUTF8StringEncoding] autorelease];
        
        if (!jsonResponse) {
            NSLog(@"Failed to convert data to string");
            NSError *parseError = [NSError errorWithDomain:@"ClaudeAPI"
                                                       code:500
                                                   userInfo:[NSDictionary dictionaryWithObject:@"Failed to decode response as UTF-8"
                                                                                        forKey:NSLocalizedDescriptionKey]];
            [self performSelectorOnMainThread:@selector(notifyDelegateWithError:)
                                   withObject:parseError
                                waitUntilDone:NO];
            [message release];
            [apiKey release];
            [pool release];
            return;
        }
        
        NSLog(@"JSON Response length: %lu", (unsigned long)[jsonResponse length]);
        NSString *responseText = [self extractResponseText:jsonResponse];
        
        if (responseText) {
            // Add assistant response to history
            NSDictionary *assistantMessage = [NSDictionary dictionaryWithObjectsAndKeys:
                                               @"assistant", @"role",
                                               responseText, @"content",
                                               nil];
            [conversationHistory addObject:assistantMessage];
            
            // Notify delegate on main thread
            [self performSelectorOnMainThread:@selector(notifyDelegateWithResponse:)
                                   withObject:responseText
                                waitUntilDone:NO];
        } else {
            NSError *parseError = [NSError errorWithDomain:@"ClaudeAPI"
                                                       code:500
                                                   userInfo:[NSDictionary dictionaryWithObject:@"Failed to parse response"
                                                                                        forKey:NSLocalizedDescriptionKey]];
            [self performSelectorOnMainThread:@selector(notifyDelegateWithError:)
                                   withObject:parseError
                                waitUntilDone:NO];
        }
    } else {
        NSError *networkError = [NSError errorWithDomain:@"ClaudeAPI"
                                                     code:500
                                                 userInfo:[NSDictionary dictionaryWithObject:@"Failed to connect to API"
                                                                                      forKey:NSLocalizedDescriptionKey]];
        [self performSelectorOnMainThread:@selector(notifyDelegateWithError:)
                               withObject:networkError
                            waitUntilDone:NO];
    }
    
    [message release];
    [apiKey release];
    [pool release];
}

- (void)notifyDelegateWithResponse:(NSString *)response {
    if (delegate && [delegate respondsToSelector:@selector(apiManager:didReceiveResponse:)]) {
        [delegate apiManager:self didReceiveResponse:response];
    }
}

- (void)notifyDelegateWithError:(NSError *)error {
    if (delegate && [delegate respondsToSelector:@selector(apiManager:didFailWithError:)]) {
        [delegate apiManager:self didFailWithError:error];
    }
}

// Simple JSON serialization for Tiger
- (NSString *)dictionaryToJSON:(NSDictionary *)dict {
    NSMutableString *json = [NSMutableString stringWithString:@"{"];
    NSArray *keys = [dict allKeys];
    int i;
    for (i = 0; i < [keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        id value = [dict objectForKey:key];
        
        if (i > 0) [json appendString:@","];
        [json appendFormat:@"\"%@\":", key];
        
        if ([value isKindOfClass:[NSString class]]) {
            NSString *escaped = [(NSString *)value stringByReplacingOccurrencesOfString:@"\"" 
                                                                              withString:@"\\\""];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
            [json appendFormat:@"\"%@\"", escaped];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [json appendFormat:@"%@", value];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [json appendString:[self arrayToJSON:value]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [json appendString:[self dictionaryToJSON:value]];
        }
    }
    [json appendString:@"}"];
    return json;
}

- (NSString *)arrayToJSON:(NSArray *)array {
    NSMutableString *json = [NSMutableString stringWithString:@"["];
    int i;
    for (i = 0; i < [array count]; i++) {
        id value = [array objectAtIndex:i];
        
        if (i > 0) [json appendString:@","];
        
        if ([value isKindOfClass:[NSString class]]) {
            NSString *escaped = [(NSString *)value stringByReplacingOccurrencesOfString:@"\"" 
                                                                              withString:@"\\\""];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
            [json appendFormat:@"\"%@\"", escaped];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [json appendFormat:@"%@", value];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [json appendString:[self dictionaryToJSON:value]];
        }
    }
    [json appendString:@"]"];
    return json;
}


// JSON response parser using yyjson
- (NSString *)extractResponseText:(NSString *)jsonResponse {
    // Log for debugging (truncate if too long)
    if ([jsonResponse length] > 1000) {
        NSLog(@"API Response (first 500 chars): %@", [jsonResponse substringToIndex:500]);
        NSLog(@"API Response (last 500 chars): %@", [jsonResponse substringFromIndex:[jsonResponse length] - 500]);
    } else {
        NSLog(@"API Response: %@", jsonResponse);
    }
    
    // Convert NSString to C string for yyjson
    const char *json_str = [jsonResponse UTF8String];
    size_t json_len = strlen(json_str);
    
    NSLog(@"Attempting to parse JSON of length: %zu", json_len);
    NSLog(@"First 200 chars of JSON: %.200s", json_str);
    
    // Parse JSON with yyjson
    yyjson_read_err err;
    memset(&err, 0, sizeof(err));
    yyjson_doc *doc = yyjson_read_opts((char *)json_str, json_len, 0, NULL, &err);
    if (!doc) {
        NSLog(@"Failed to parse JSON with yyjson - Error code: %u, message: %s, position: %zu", 
              err.code, err.msg, err.pos);
        NSLog(@"Error occurred near: %.50s", json_str + (err.pos > 50 ? err.pos - 50 : 0));
        return nil;
    }
    
    // Get root object
    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        NSLog(@"No root object in JSON");
        return nil;
    }
    
    // Check for error response
    yyjson_val *error_obj = yyjson_obj_get(root, "error");
    if (error_obj) {
        yyjson_val *error_msg = yyjson_obj_get(error_obj, "message");
        if (error_msg && yyjson_is_str(error_msg)) {
            const char *error_str = yyjson_get_str(error_msg);
            NSLog(@"API Error: %s", error_str);
            NSString *errorString = [NSString stringWithFormat:@"API Error: %s", error_str];
            yyjson_doc_free(doc);
            return errorString;  // Return error message to display to user
        }
    }
    
    // Get content array
    yyjson_val *content = yyjson_obj_get(root, "content");
    if (!content || !yyjson_is_arr(content)) {
        NSLog(@"No content array found in response");
        yyjson_doc_free(doc);
        return nil;
    }
    
    // Get first content item
    yyjson_val *first_content = yyjson_arr_get(content, 0);
    if (!first_content) {
        NSLog(@"Content array is empty");
        yyjson_doc_free(doc);
        return nil;
    }
    
    // Get text field from content item
    yyjson_val *text_val = yyjson_obj_get(first_content, "text");
    if (!text_val || !yyjson_is_str(text_val)) {
        NSLog(@"No text field in content item");
        yyjson_doc_free(doc);
        return nil;
    }
    
    // Get the text string
    const char *text_str = yyjson_get_str(text_val);
    NSString *result = [NSString stringWithUTF8String:text_str];
    
    // Clean up
    yyjson_doc_free(doc);
    
    NSLog(@"Successfully parsed response with yyjson");
    return result;
}

@end