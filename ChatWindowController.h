//
//  ChatWindowController.h
//  ClaudeChat
//

#import <Cocoa/Cocoa.h>
#import "ClaudeAPIManager.h"

@class ClaudeAPIManager;

@interface ChatWindowController : NSWindowController <ClaudeAPIManagerDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    NSTextView *chatTextView;
    NSTextView *messageField;
    NSScrollView *messageScrollView;
    NSButton *sendButton;
    NSProgressIndicator *progressIndicator;
    NSScrollView *scrollView;
    float messageFieldMinHeight;
    float messageFieldMaxHeight;
    
    NSDrawer *conversationDrawer;
    NSTableView *conversationTable;
    
    ClaudeAPIManager *apiManager;
    NSMutableAttributedString *chatHistory;
    NSMutableArray *codeBlockButtons;
    NSMutableArray *codeBlockRanges;
}

- (id)init;
- (void)sendMessage:(id)sender;
- (void)appendMessage:(NSString *)message fromUser:(BOOL)isUser;
- (void)clearConversation;
- (void)updateWindowTitle;
- (void)updateTheme;
- (void)updateFontSize;
- (NSAttributedString *)parseMarkdown:(NSString *)text isUser:(BOOL)isUser;
- (NSDictionary *)parseMarkdownWithCodeBlocks:(NSString *)text isUser:(BOOL)isUser;

@end