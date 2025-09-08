//
//  ClaudeAPIManager_Tiger.m
//  ClaudeChat
//
//  Tiger-compatible version using delegate pattern
//

#import "ClaudeAPIManager.h"
#import "NetworkManager_Tiger.h"
#import "AppDelegate.h"

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
    
    // Create request
    NSURL *url = [NSURL URLWithString:@"https://api.anthropic.com/v1/messages"];
    
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                             apiKey, @"x-api-key",
                             @"2023-06-01", @"anthropic-version",
                             @"application/json", @"content-type",
                             nil];
    
    NSMutableURLRequest *request = [[NetworkManager sharedManager] createRequestWithURL:url
                                                                                  method:@"POST"
                                                                                 headers:headers
                                                                                    body:bodyData];
    
    // Send request
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *data = [[NetworkManager sharedManager] sendSynchronousRequest:request
                                                         returningResponse:&response
                                                                     error:&error];
    
    if (!error && data) {
        NSString *jsonResponse = [[[NSString alloc] initWithData:data 
                                                         encoding:NSUTF8StringEncoding] autorelease];
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
        [self performSelectorOnMainThread:@selector(notifyDelegateWithError:)
                               withObject:error
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

// Simple JSON response parser
- (NSString *)extractResponseText:(NSString *)jsonResponse {
    // Log for debugging
    NSLog(@"API Response: %@", jsonResponse);
    
    // Look for "content":[{"type":"text","text":"..."}]
    // The response format includes a "type" field
    NSRange textStartRange = [jsonResponse rangeOfString:@"\"text\":\""];
    if (textStartRange.location != NSNotFound) {
        NSUInteger startIndex = textStartRange.location + [@"\"text\":\"" length];
        
        // Find the closing quote, handling escaped quotes
        NSUInteger searchIndex = startIndex;
        BOOL foundEnd = NO;
        NSUInteger endIndex = startIndex;
        
        while (searchIndex < [jsonResponse length] && !foundEnd) {
            unichar c = [jsonResponse characterAtIndex:searchIndex];
            if (c == '"') {
                // Check if it's escaped
                if (searchIndex > 0 && [jsonResponse characterAtIndex:searchIndex - 1] != '\\') {
                    foundEnd = YES;
                    endIndex = searchIndex;
                } else if (searchIndex > 1 && 
                          [jsonResponse characterAtIndex:searchIndex - 1] == '\\' &&
                          [jsonResponse characterAtIndex:searchIndex - 2] == '\\') {
                    // Double backslash means the quote is not escaped
                    foundEnd = YES;
                    endIndex = searchIndex;
                }
            }
            searchIndex++;
        }
        
        if (foundEnd) {
            NSString *text = [jsonResponse substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
            
            // Unescape JSON escapes in the correct order
            text = [text stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\001"];  // Temp replace
            text = [text stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
            text = [text stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            text = [text stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
            text = [text stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
            text = [text stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
            text = [text stringByReplacingOccurrencesOfString:@"\001" withString:@"\\"];  // Restore backslash
            
            return text;
        }
    }
    
    // Check for error message
    NSRange errorRange = [jsonResponse rangeOfString:@"\"message\":\""];
    if (errorRange.location != NSNotFound) {
        NSUInteger startIndex = errorRange.location + [@"\"message\":\"" length];
        NSRange endRange = [jsonResponse rangeOfString:@"\"" 
                                                options:0 
                                                  range:NSMakeRange(startIndex, [jsonResponse length] - startIndex)];
        if (endRange.location != NSNotFound) {
            NSString *errorMsg = [jsonResponse substringWithRange:NSMakeRange(startIndex, endRange.location - startIndex)];
            NSLog(@"API Error: %@", errorMsg);
            return nil;
        }
    }
    
    NSLog(@"Failed to parse response");
    return nil;
}

@end