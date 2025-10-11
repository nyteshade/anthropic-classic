//
//  ChatWindowController.h
//  ClaudeChat
//

#import <Cocoa/Cocoa.h>
#import "ClaudeAPIManager.h"

@class ClaudeAPIManager;

@interface ChatWindowController : NSWindowController <ClaudeAPIManagerDelegate> {
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

- (void)parseInlineMarkdown:(NSString *)text 
											 into:(NSMutableAttributedString *)result 
									 propFont:(NSFont *)propFont
									 monoFont:(NSFont *)monoFont
									textColor:(NSColor *)textColor 
									codeColor:(NSColor *)codeColor;

- (NSAttributedString *)parseMarkdown:(NSString *)text 
															 isUser:(BOOL)isUser;

- (NSAttributedString *)parseMarkdownInternal:(NSString *)text 
																			 isUser:(BOOL)isUser 
																	 codeBlocks:(NSMutableArray *)codeBlocksArray;

- (NSDictionary *)parseMarkdownWithCodeBlocks:(NSString *)text isUser:(BOOL)isUser;

- (void)addCodeBlockButton:(NSString *)code atRange:(NSRange)range;
- (void)adjustMessageFieldHeight;
- (void)appendMessage:(NSString *)message fromUser:(BOOL)isUser;
- (void)clearConversation;
- (void)createConversationDrawer;
- (void)createWindow;
- (void)loadCurrentConversation;
- (void)refreshChatColors;
- (void)removeAllCodeBlockButtons;
- (void)resetControls;
- (void)sendMessage:(id)sender;
- (void)updateCodeBlockButtonPositions;
- (void)updateFontSize;
- (void)updateTheme;
- (void)updateWindowTitle;

@end