//
//  ClaudeAPIManager.m
//  ClaudeChat
//

#import "ClaudeAPIManager.h"
#import "NetworkManager.h"

@implementation ClaudeAPIManager

- (id)init {
    self = [super init];
    if (self) {
        conversationHistory = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [conversationHistory release];
    [super dealloc];
}

- (void)sendMessage:(NSString *)message 
          withAPIKey:(NSString *)apiKey
          completion:(APICompletionHandler)completion {
    
    // Add message to history
    NSDictionary *userMessage = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"user", @"role",
                                  message, @"content",
                                  nil];
    [conversationHistory addObject:userMessage];
    
    // Prepare request body
    NSDictionary *requestBody = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"claude-3-haiku-20240307", @"model",
                                  conversationHistory, @"messages",
                                  [NSNumber numberWithInt:1024], @"max_tokens",
                                  nil];
    
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:requestBody
                                                        options:0
                                                          error:&jsonError];
    
    if (jsonError) {
        if (completion) {
            completion(nil, jsonError);
        }
        return;
    }
    
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
    [[NetworkManager sharedManager] performHTTPSRequest:request
                                              completion:^(NSData *data, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        // Parse response
        NSError *parseError = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&parseError];
        
        if (parseError) {
            if (completion) {
                completion(nil, parseError);
            }
            return;
        }
        
        // Extract message content
        NSArray *content = [response objectForKey:@"content"];
        if (content && [content count] > 0) {
            NSDictionary *firstContent = [content objectAtIndex:0];
            NSString *text = [firstContent objectForKey:@"text"];
            
            // Add assistant response to history
            NSDictionary *assistantMessage = [NSDictionary dictionaryWithObjectsAndKeys:
                                               @"assistant", @"role",
                                               text, @"content",
                                               nil];
            [conversationHistory addObject:assistantMessage];
            
            if (completion) {
                completion(text, nil);
            }
        } else {
            // Check for error message
            NSDictionary *errorDict = [response objectForKey:@"error"];
            if (errorDict) {
                NSString *errorMessage = [errorDict objectForKey:@"message"];
                NSError *apiError = [NSError errorWithDomain:@"ClaudeAPI"
                                                         code:400
                                                     userInfo:[NSDictionary dictionaryWithObject:errorMessage ? errorMessage : @"Unknown API error"
                                                                                          forKey:NSLocalizedDescriptionKey]];
                if (completion) {
                    completion(nil, apiError);
                }
            } else {
                if (completion) {
                    completion(@"No response content", nil);
                }
            }
        }
    }];
}

@end