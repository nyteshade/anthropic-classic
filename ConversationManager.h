//
//  ConversationManager.h
//  ClaudeChat
//
//  Manages conversation history and persistence
//

#import <Foundation/Foundation.h>
#import "TigerCompat.h"

@interface Conversation : NSObject {
    NSString *_conversationId;
    NSString *_title;
    NSDate *_lastModified;
    NSMutableArray *_messages;
    NSAttributedString *_displayContent;
}

NEHProperty(NSString*, conversationId, setConversationId);
NEHProperty(NSString*, title, setTitle);
NEHProperty(NSDate*, lastModified, setLastModified);
NEHProperty(NSMutableArray*, messages, setMessages);
NEHProperty(NSAttributedString*, displayContent, setDisplayContent);

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