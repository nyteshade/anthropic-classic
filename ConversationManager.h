//
//  ConversationManager.h
//  ClaudeChat
//
//  Manages conversation history and persistence
//

#import <Foundation/Foundation.h>

@interface Conversation : NSObject {
    NSString *conversationId;
    NSString *title;
    NSDate *lastModified;
    NSMutableArray *messages;
    NSAttributedString *displayContent;
}

@property (retain) NSString *conversationId;
@property (retain) NSString *title;
@property (retain) NSDate *lastModified;
@property (retain) NSMutableArray *messages;
@property (retain) NSAttributedString *displayContent;

- (id)initWithTitle:(NSString *)aTitle;
- (void)addMessage:(NSDictionary *)message;
- (NSString *)summary;

@end

@interface ConversationManager : NSObject {
    NSMutableArray *conversations;
    Conversation *currentConversation;
    NSString *storageDirectory;
}

+ (ConversationManager *)sharedManager;
- (NSArray *)allConversations;
- (Conversation *)currentConversation;
- (Conversation *)createNewConversation;
- (void)selectConversation:(Conversation *)conversation;
- (void)saveCurrentConversation;
- (void)loadConversations;
- (void)deleteConversation:(Conversation *)conversation;

@end