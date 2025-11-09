////////////////////////////////////////////////////////////////////////////////
// ConversationManager.h
// ClaudeChat
//
// Manages chat conversations and persistence across application sessions.
// Handles conversation creation, deletion, loading, and saving with support
// for efficient caching and background operations.
//
// Compatibility: Mac OS X 10.4 Tiger and later
// Copyright (c) 2024 Nyteshade. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "TigerCompat.h"


/**
 * Maximum number of conversations to keep in memory simultaneously.
 * Older conversations are archived but not loaded until accessed.
 */
#define MAX_CONVERSATIONS_IN_MEMORY 100


////////////////////////////////////////////////////////////////////////////////
/**
 * @class Conversation
 * @brief Represents a single chat conversation
 *
 * A Conversation contains a sequence of messages between the user and Claude,
 * along with metadata such as title, unique ID, and last modified date.
 *
 * Messages are stored as dictionaries with keys:
 * - "role": @"user" or @"assistant"
 * - "content": NSString with message text
 */
@interface Conversation : NSObject
{
  NSString *_conversationId;
  NSString *_title;
  NSDate *_lastModified;
  NSMutableArray *_messages;
  NSAttributedString *_displayContent;
}


/**
 * Unique identifier for this conversation.
 * Format: "conv_<timestamp>_<random>"
 */
NEHProperty(NSString*, conversationId, setConversationId);


/**
 * Human-readable title for the conversation.
 * Defaults to "Chat N" but can be customized.
 */
NEHProperty(NSString*, title, setTitle);


/**
 * Date when this conversation was last modified.
 * Updated automatically when messages are added.
 */
NEHProperty(NSDate*, lastModified, setLastModified);


/**
 * Array of message dictionaries.
 * Each message contains "role" and "content" keys.
 */
NEHProperty(NSMutableArray*, messages, setMessages);


/**
 * Cached attributed string for display.
 * May be nil if not yet rendered.
 */
NEHProperty(NSAttributedString*, displayContent, setDisplayContent);


/**
 * Initializes a new conversation with the given title.
 *
 * @param aTitle The title for the conversation
 * @return An initialized Conversation instance
 */
- (id)initWithTitle:(NSString *)aTitle;


/**
 * Adds a message to the conversation.
 *
 * Automatically updates the lastModified date.
 *
 * @param message Dictionary with "role" and "content" keys
 */
- (void)addMessage:(NSDictionary *)message;


/**
 * Returns a summary string for the conversation.
 *
 * Uses the first user message (up to 50 characters) if available,
 * otherwise returns the conversation title.
 *
 * @return A summary string suitable for display in a list
 */
- (NSString *)summary;

@end


////////////////////////////////////////////////////////////////////////////////
/**
 * @class ConversationManager
 * @brief Singleton manager for all chat conversations
 *
 * ConversationManager provides centralized management of conversations,
 * including:
 * - Creating and deleting conversations
 * - Loading from and saving to disk
 * - Maintaining current conversation selection
 * - Efficient caching and background persistence
 *
 * This is a singleton class - use [ConversationManager sharedManager].
 *
 * Scalability features:
 * - Limits in-memory conversations to MAX_CONVERSATIONS_IN_MEMORY
 * - Caches sorted conversation lists
 * - Supports background save operations
 * - Invalidates caches intelligently
 */
@interface ConversationManager : NSObject
{
  NSMutableArray *conversations;
  Conversation *currentConversation;
  NSString *storageDirectory;

  // Cached sorted conversations array
  NSArray *cachedSortedConversations;
  BOOL sortCacheValid;
}


/**
 * Returns the shared ConversationManager singleton instance.
 *
 * @return The singleton ConversationManager instance
 */
+ (ConversationManager *)sharedManager;


/**
 * Returns all conversations, sorted by last modified date (newest first).
 *
 * This method uses a cache to avoid repeated sorting. The cache is
 * invalidated automatically when conversations are added or removed.
 *
 * @return Array of Conversation objects, sorted by last modified date
 */
- (NSArray *)allConversations;


/**
 * Returns the currently active conversation.
 *
 * @return The current Conversation instance
 */
- (Conversation *)currentConversation;


/**
 * Creates a new conversation with a default title.
 *
 * The new conversation is automatically selected as current and added
 * to the conversation list. The sort cache is invalidated.
 *
 * @return The newly created Conversation instance
 */
- (Conversation *)createNewConversation;


/**
 * Selects a conversation as the current active conversation.
 *
 * Automatically saves the previously current conversation before switching.
 *
 * @param conversation The conversation to select
 */
- (void)selectConversation:(Conversation *)conversation;


/**
 * Saves the current conversation to disk.
 *
 * Conversations are saved as property list files in the application
 * support directory. This operation is synchronous but can be wrapped
 * in a background operation if needed.
 */
- (void)saveCurrentConversation;


/**
 * Saves the current conversation to disk on a background thread.
 *
 * This is the preferred method for saving during normal operation to
 * avoid blocking the main thread.
 */
- (void)saveCurrentConversationInBackground;


/**
 * Loads all conversations from disk.
 *
 * Conversations are loaded from property list files in the application
 * support directory. Limits loading to MAX_CONVERSATIONS_IN_MEMORY most
 * recent conversations for scalability.
 */
- (void)loadConversations;


/**
 * Deletes a conversation from the manager and disk.
 *
 * If the deleted conversation is the current conversation, automatically
 * selects another conversation or creates a new one if none remain.
 * Invalidates the sort cache.
 *
 * @param conversation The conversation to delete
 */
- (void)deleteConversation:(Conversation *)conversation;

@end
