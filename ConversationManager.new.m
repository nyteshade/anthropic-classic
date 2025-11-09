////////////////////////////////////////////////////////////////////////////////
// ConversationManager.m
// ClaudeChat
//
// Implementation of conversation management with optimized caching and
// background persistence for scalability.
//
// Compatibility: Mac OS X 10.4 Tiger and later
// Copyright (c) 2024 Nyteshade. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import "ConversationManager.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Conversation Implementation
// MARK: -
////////////////////////////////////////////////////////////////////////////////

@implementation Conversation

NEMProperty(NSString*, conversationId, setConversationId);
NEMProperty(NSString*, title, setTitle);
NEMProperty(NSDate*, lastModified, setLastModified);
NEMProperty(NSMutableArray*, messages, setMessages);
NEMProperty(NSAttributedString*, displayContent, setDisplayContent);


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (id)initWithTitle:(NSString *)aTitle
{
  self = [super init];

  if (self)
  {
    // Generate unique ID using timestamp and random number
    _conversationId = [[NSString stringWithFormat:@"conv_%d_%d",
                       (int)[[NSDate date] timeIntervalSince1970],
                       arc4random()] retain];

    _title = [aTitle retain];
    _lastModified = [[NSDate date] retain];
    _messages = [[NSMutableArray alloc] init];
    _displayContent = nil;
  }

  return self;
}


- (void)dealloc
{
  [_conversationId release];
  [_title release];
  [_lastModified release];
  [_messages release];
  [_displayContent release];

  [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Message Management
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (void)addMessage:(NSDictionary *)message
{
  [_messages addObject:message];

  // Update modification time
  [_lastModified release];
  _lastModified = [[NSDate date] retain];

  // Invalidate cached display content
  [_displayContent release];
  _displayContent = nil;
}


- (NSString *)summary
{
  NSDictionary *firstUserMessage = nil;
  int i;

  // Find first user message for summary
  if ([_messages count] > 0)
  {
    for (i = 0; i < [_messages count]; i++)
    {
      NSDictionary *msg = [_messages objectAtIndex:i];

      if ([[msg objectForKey:@"role"] isEqualToString:@"user"])
      {
        firstUserMessage = msg;
        break;
      }
    }

    if (firstUserMessage)
    {
      NSString *content = [firstUserMessage objectForKey:@"content"];

      // Truncate long messages
      if ([content length] > 50)
      {
        return [[content substringToIndex:50] stringByAppendingString:@"..."];
      }

      return content;
    }
  }

  // Fallback to title if no messages
  return _title;
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - ConversationManager Implementation
// MARK: -
////////////////////////////////////////////////////////////////////////////////

@implementation ConversationManager

static ConversationManager *sharedInstance = nil;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton
// MARK: -
////////////////////////////////////////////////////////////////////////////////

+ (ConversationManager *)sharedManager
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[ConversationManager alloc] init];
  }

  return sharedInstance;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (id)init
{
  NSArray *paths;
  NSString *appSupport;
  NSFileManager *fm;
  BOOL isDir;

  self = [super init];

  if (self)
  {
    // Initialize conversation storage
    conversations = [[NSMutableArray alloc] init];

    // Initialize cache
    cachedSortedConversations = nil;
    sortCacheValid = NO;

    // Set up storage directory
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                 NSUserDomainMask, YES);
    appSupport = [paths objectAtIndex:0];
    storageDirectory = [[appSupport stringByAppendingPathComponent:@"ClaudeChat"] retain];

    // Create directory if needed
    fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:storageDirectory isDirectory:&isDir])
    {
      [fm createDirectoryAtPath:storageDirectory
                     attributes:[NSDictionary dictionary]];
    }

    // Load existing conversations from disk
    [self loadConversations];

    // Ensure we always have at least one conversation
    if ([conversations count] == 0)
    {
      [self createNewConversation];
    }
    else
    {
      currentConversation = [[conversations objectAtIndex:0] retain];
    }
  }

  return self;
}


- (void)dealloc
{
  [conversations release];
  [currentConversation release];
  [storageDirectory release];
  [cachedSortedConversations release];

  [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Conversation Access
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (NSArray *)allConversations
{
  NSSortDescriptor *sortDesc;

  // Return cached result if valid
  if (sortCacheValid && cachedSortedConversations)
  {
    return cachedSortedConversations;
  }

  // Sort conversations by last modified date (newest first)
  sortDesc = [[[NSSortDescriptor alloc]
              initWithKey:@"lastModified"
              ascending:NO] autorelease];

  [cachedSortedConversations release];
  cachedSortedConversations = [[conversations sortedArrayUsingDescriptors:
                               [NSArray arrayWithObject:sortDesc]] retain];

  sortCacheValid = YES;

  return cachedSortedConversations;
}


- (Conversation *)currentConversation
{
  return currentConversation;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Conversation Management
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (Conversation *)createNewConversation
{
  NSString *title;
  Conversation *newConv;

  // Generate default title
  title = [NSString stringWithFormat:@"Chat %lu",
          (unsigned long)([conversations count] + 1)];

  newConv = [[[Conversation alloc] initWithTitle:title] autorelease];
  [conversations addObject:newConv];

  // Invalidate sort cache
  [self invalidateSortCache];

  // Select as current conversation
  [self selectConversation:newConv];

  return newConv;
}


- (void)selectConversation:(Conversation *)conversation
{
  if (currentConversation != conversation)
  {
    // Save current before switching
    [self saveCurrentConversationInBackground];

    // Switch to new conversation
    [currentConversation release];
    currentConversation = [conversation retain];
  }
}


- (void)deleteConversation:(Conversation *)conversation
{
  NSString *filename;
  NSString *path;

  // Build file path
  filename = [[conversation conversationId] stringByAppendingPathExtension:@"plist"];
  path = [storageDirectory stringByAppendingPathComponent:filename];

  // Delete from disk
  [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];

  // Handle current conversation
  if (currentConversation == conversation)
  {
    [currentConversation release];
    currentConversation = nil;
  }

  // Remove from array
  [conversations removeObject:conversation];

  // Invalidate cache
  [self invalidateSortCache];

  // Ensure we have a current conversation
  if (currentConversation == nil)
  {
    if ([conversations count] > 0)
    {
      currentConversation = [[conversations objectAtIndex:0] retain];
    }
    else
    {
      // Create new conversation when all are deleted
      [self createNewConversation];
    }
  }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Persistence
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (void)saveCurrentConversation
{
  NSString *filename;
  NSString *path;
  NSDictionary *data;

  if (!currentConversation)
  {
    return;
  }

  // Build file path
  filename = [[currentConversation conversationId]
             stringByAppendingPathExtension:@"plist"];
  path = [storageDirectory stringByAppendingPathComponent:filename];

  // Create data dictionary
  data = [NSDictionary dictionaryWithObjectsAndKeys:
         [currentConversation conversationId], @"id",
         [currentConversation title], @"title",
         [currentConversation lastModified], @"lastModified",
         [currentConversation messages], @"messages",
         nil];

  // Write to disk
  [data writeToFile:path atomically:YES];
}


- (void)saveCurrentConversationInBackground
{
  Conversation *conv;

  if (!currentConversation)
  {
    return;
  }

  // Retain conversation for background operation
  conv = [currentConversation retain];

  // Perform save on background thread
  [self performSelectorInBackground:@selector(saveConversationToFile:)
                         withObject:conv];
}


- (void)saveConversationToFile:(Conversation *)conversation
{
  NSAutoreleasePool *pool;
  NSString *filename;
  NSString *path;
  NSDictionary *data;

  pool = [[NSAutoreleasePool alloc] init];

  // Build file path
  filename = [[conversation conversationId]
             stringByAppendingPathExtension:@"plist"];
  path = [storageDirectory stringByAppendingPathComponent:filename];

  // Create data dictionary
  data = [NSDictionary dictionaryWithObjectsAndKeys:
         [conversation conversationId], @"id",
         [conversation title], @"title",
         [conversation lastModified], @"lastModified",
         [conversation messages], @"messages",
         nil];

  // Write to disk
  [data writeToFile:path atomically:YES];

  // Release retained conversation
  [conversation release];

  [pool release];
}


- (void)loadConversations
{
  NSFileManager *fm;
  NSArray *files;
  NSMutableArray *plistFiles;
  NSSortDescriptor *sortDesc;
  NSUInteger loadLimit;
  int i;

  fm = [NSFileManager defaultManager];
  files = [fm directoryContentsAtPath:storageDirectory];
  plistFiles = [NSMutableArray array];

  // Collect plist files with modification dates
  for (i = 0; i < [files count]; i++)
  {
    NSString *file = [files objectAtIndex:i];

    if ([[file pathExtension] isEqualToString:@"plist"])
    {
      NSString *path = [storageDirectory stringByAppendingPathComponent:file];
      NSDictionary *attrs = [fm fileAttributesAtPath:path traverseLink:YES];
      NSDictionary *fileInfo;

      fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                 path, @"path",
                 [attrs fileModificationDate], @"modified",
                 nil];

      [plistFiles addObject:fileInfo];
    }
  }

  // Sort by modification date (newest first)
  sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"modified"
                                          ascending:NO];
  [plistFiles sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];

  // Limit number of conversations loaded into memory
  loadLimit = [plistFiles count];
  if (loadLimit > MAX_CONVERSATIONS_IN_MEMORY)
  {
    loadLimit = MAX_CONVERSATIONS_IN_MEMORY;
  }

  // Load conversations from files
  for (i = 0; i < loadLimit; i++)
  {
    NSString *path = [[plistFiles objectAtIndex:i] objectForKey:@"path"];
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:path];

    if (data)
    {
      Conversation *conv = [[[Conversation alloc] init] autorelease];

      [conv setConversationId:[data objectForKey:@"id"]];
      [conv setTitle:[data objectForKey:@"title"]];
      [conv setLastModified:[data objectForKey:@"lastModified"]];
      [conv setMessages:[NSMutableArray arrayWithArray:
                        [data objectForKey:@"messages"]]];

      [conversations addObject:conv];
    }
  }

  // Invalidate cache after loading
  [self invalidateSortCache];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cache Management
// MARK: -
////////////////////////////////////////////////////////////////////////////////

- (void)invalidateSortCache
{
  [cachedSortedConversations release];
  cachedSortedConversations = nil;
  sortCacheValid = NO;
}

@end
