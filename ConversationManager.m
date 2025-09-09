//
//  ConversationManager.m
//  ClaudeChat
//

#import "ConversationManager.h"

@implementation Conversation

@synthesize conversationId;
@synthesize title;
@synthesize lastModified;
@synthesize messages;
@synthesize displayContent;

- (id)initWithTitle:(NSString *)aTitle {
    self = [super init];
    if (self) {
        // Generate unique ID
        conversationId = [[NSString stringWithFormat:@"conv_%d_%d", 
                          (int)[[NSDate date] timeIntervalSince1970], 
                          arc4random()] retain];
        title = [aTitle retain];
        lastModified = [[NSDate date] retain];
        messages = [[NSMutableArray alloc] init];
        displayContent = nil;
    }
    return self;
}

- (void)dealloc {
    [conversationId release];
    [title release];
    [lastModified release];
    [messages release];
    [displayContent release];
    [super dealloc];
}

- (void)addMessage:(NSDictionary *)message {
    [messages addObject:message];
    [lastModified release];
    lastModified = [[NSDate date] retain];
}

- (NSString *)summary {
    if ([messages count] > 0) {
        NSDictionary *firstUserMessage = nil;
        int i;
        for (i = 0; i < [messages count]; i++) {
            NSDictionary *msg = [messages objectAtIndex:i];
            if ([[msg objectForKey:@"role"] isEqualToString:@"user"]) {
                firstUserMessage = msg;
                break;
            }
        }
        if (firstUserMessage) {
            NSString *content = [firstUserMessage objectForKey:@"content"];
            if ([content length] > 50) {
                return [[content substringToIndex:50] stringByAppendingString:@"..."];
            }
            return content;
        }
    }
    return title;
}

@end

@implementation ConversationManager

static ConversationManager *sharedInstance = nil;

+ (ConversationManager *)sharedManager {
    if (sharedInstance == nil) {
        sharedInstance = [[ConversationManager alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        conversations = [[NSMutableArray alloc] init];
        
        // Set up storage directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
                                                             NSUserDomainMask, YES);
        NSString *appSupport = [paths objectAtIndex:0];
        storageDirectory = [[appSupport stringByAppendingPathComponent:@"ClaudeChat"] retain];
        
        // Create directory if needed
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir;
        if (![fm fileExistsAtPath:storageDirectory isDirectory:&isDir]) {
            [fm createDirectoryAtPath:storageDirectory attributes:[NSDictionary dictionary]];
        }
        
        // Load existing conversations
        [self loadConversations];
        
        // Create initial conversation if none exist
        if ([conversations count] == 0) {
            [self createNewConversation];
        } else {
            currentConversation = [[conversations objectAtIndex:0] retain];
        }
    }
    return self;
}

- (void)dealloc {
    [conversations release];
    [currentConversation release];
    [storageDirectory release];
    [super dealloc];
}

- (NSArray *)allConversations {
    // Sort by last modified date
    NSSortDescriptor *sortDesc = [[[NSSortDescriptor alloc] 
                                   initWithKey:@"lastModified" 
                                   ascending:NO] autorelease];
    return [conversations sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
}

- (Conversation *)currentConversation {
    return currentConversation;
}

- (Conversation *)createNewConversation {
    NSString *title = [NSString stringWithFormat:@"Chat %lu", (unsigned long)([conversations count] + 1)];
    Conversation *newConv = [[[Conversation alloc] initWithTitle:title] autorelease];
    [conversations addObject:newConv];
    [self selectConversation:newConv];
    return newConv;
}

- (void)selectConversation:(Conversation *)conversation {
    if (currentConversation != conversation) {
        [self saveCurrentConversation];
        [currentConversation release];
        currentConversation = [conversation retain];
    }
}

- (void)saveCurrentConversation {
    if (!currentConversation) return;
    
    NSString *filename = [currentConversation.conversationId stringByAppendingPathExtension:@"plist"];
    NSString *path = [storageDirectory stringByAppendingPathComponent:filename];
    
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          currentConversation.conversationId, @"id",
                          currentConversation.title, @"title",
                          currentConversation.lastModified, @"lastModified",
                          currentConversation.messages, @"messages",
                          nil];
    
    [data writeToFile:path atomically:YES];
}

- (void)loadConversations {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm directoryContentsAtPath:storageDirectory];
    
    int i;
    for (i = 0; i < [files count]; i++) {
        NSString *file = [files objectAtIndex:i];
        if ([[file pathExtension] isEqualToString:@"plist"]) {
            NSString *path = [storageDirectory stringByAppendingPathComponent:file];
            NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:path];
            
            if (data) {
                Conversation *conv = [[[Conversation alloc] init] autorelease];
                conv.conversationId = [data objectForKey:@"id"];
                conv.title = [data objectForKey:@"title"];
                conv.lastModified = [data objectForKey:@"lastModified"];
                conv.messages = [NSMutableArray arrayWithArray:[data objectForKey:@"messages"]];
                [conversations addObject:conv];
            }
        }
    }
}

- (void)deleteConversation:(Conversation *)conversation {
    NSString *filename = [conversation.conversationId stringByAppendingPathExtension:@"plist"];
    NSString *path = [storageDirectory stringByAppendingPathComponent:filename];
    
    [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    
    // Handle current conversation first before removing from array
    if (currentConversation == conversation) {
        [currentConversation release];
        currentConversation = nil;
    }
    
    [conversations removeObject:conversation];
    
    // Now select or create new conversation
    if (currentConversation == nil) {
        if ([conversations count] > 0) {
            currentConversation = [[conversations objectAtIndex:0] retain];
        } else {
            // Create new conversation when all are deleted
            // createNewConversation already adds it to the array and selects it
            [self createNewConversation];
        }
    }
}

@end