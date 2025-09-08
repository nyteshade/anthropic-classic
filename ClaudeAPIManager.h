//
//  ClaudeAPIManager.h
//  ClaudeChat
//

#import <Foundation/Foundation.h>

@class ClaudeAPIManager;

@protocol ClaudeAPIManagerDelegate
- (void)apiManager:(ClaudeAPIManager *)manager didReceiveResponse:(NSString *)response;
- (void)apiManager:(ClaudeAPIManager *)manager didFailWithError:(NSError *)error;
@end

@interface ClaudeAPIManager : NSObject {
    NSMutableArray *conversationHistory;
    id delegate;
}

- (id)init;
- (void)setDelegate:(id)aDelegate;
- (void)sendMessage:(NSString *)message withAPIKey:(NSString *)apiKey;
- (void)addToHistory:(NSString *)message isUser:(BOOL)isUser;

@end