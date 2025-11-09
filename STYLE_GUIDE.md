# ClaudeChat Code Style Guide

Comprehensive coding standards for Mac OS X 10.4 Tiger through modern macOS compatibility.

## Core Principles

1. **Readability First**: Code should be easy to read and understand
2. **Consistency**: Follow these rules throughout the codebase
3. **Compatibility**: Write code that works across 20+ years of macOS versions
4. **Documentation**: Every public interface must be documented

## Indentation and Whitespace

### Indentation

- **2 spaces** for indentation
- **NO TABS** - convert all tabs to spaces
- Configure your editor to insert spaces

```objc
// ✓ CORRECT
- (void)myMethod
{
  if (condition)
  {
    doSomething();
  }
}

// ✗ WRONG (uses tabs)
- (void)myMethod
{
→ if (condition)
→ {
→ → doSomething();
→ }
}
```

### Vertical Whitespace

**Between functions/methods:**
```objc
- (void)firstMethod
{
  // Implementation
}


- (void)secondMethod  // <-- 2 blank lines above
{
  // Implementation
}
```

**Within functions:**
```objc
- (void)exampleMethod
{
  // Variable declarations at top
  NSString *name = @"example";
  int count = 0;
                              // <-- 1 blank line
  // Logic block 1
  if (condition)
  {
    doSomething();
  }
                              // <-- 1 blank line between logic blocks
  // Logic block 2
  for (int i = 0; i < count; i++)
  {
    process(i);
  }
                              // <-- 1 blank line before return
  return;
}
```

**Between sections in header files:**
```objc
#import <Foundation/Foundation.h>


@interface MyClass : NSObject
{
  // Instance variables
  NSString *_name;
  int _count;
}


// Properties
@property (nonatomic, retain) NSString *name;


// Initialization
- (id)initWithName:(NSString *)name;


// Public Methods
- (void)doSomething;
- (int)calculateValue;

@end
```

## Bracing Style

### Method/Function Definitions

Opening brace on **new line**:

```objc
// ✓ CORRECT
- (id)init
{
  self = [super init];

  if (self)
  {
    _count = 0;
  }

  return self;
}

// ✗ WRONG (K&R style - not used here)
- (id)init {
  self = [super init];
  if (self) {
    _count = 0;
  }
  return self;
}
```

### Control Structures

Opening brace on **new line**, matching indentation:

```objc
// ✓ CORRECT
if (condition)
{
  doSomething();
}

for (int i = 0; i < count; i++)
{
  process(i);
}

while (running)
{
  update();
}

// ✗ WRONG
if (condition) {
  doSomething();
}
```

### Single-Statement Conditionals

Always use braces, even for single statements:

```objc
// ✓ CORRECT
if (condition)
{
  return;
}

// ✗ WRONG (no braces)
if (condition)
  return;
```

## Variable Declarations

### Function-Scoped Variables

Declare **at the top** of the function (C89 compatibility):

```objc
- (void)processData:(NSArray *)items
{
  // ALL variables declared at top
  NSString *result = nil;
  int count = [items count];
  int i;
  BOOL success = NO;

  // Logic starts after blank line
  for (i = 0; i < count; i++)
  {
    NSString *item = [items objectAtIndex:i];
    // Process item...
  }

  if (success)
  {
    NSLog(@"Completed: %@", result);
  }

  return;
}
```

### Loop Variables (C89 Compatibility)

```objc
// ✓ CORRECT (Tiger-compatible)
int i;
for (i = 0; i < count; i++)
{
  // ...
}

// ✗ WRONG (requires C99)
for (int i = 0; i < count; i++)  // Not supported on Tiger!
{
  // ...
}
```

## Documentation

### Header File Documentation

Every public class, method, and property must be documented:

```objc
/**
 * @file ConversationManager.h
 * @brief Manages chat conversations and persistence
 *
 * ConversationManager handles creating, loading, saving, and managing
 * multiple chat conversations. It provides conversation history persistence
 * to disk using property list files.
 *
 * Compatibility: Mac OS X 10.4+
 */

/**
 * @class ConversationManager
 * @brief Singleton manager for chat conversations
 *
 * This class provides centralized management of all chat conversations
 * in the application. It handles persistence, creates new conversations,
 * and maintains the current active conversation.
 *
 * @note This is a singleton - use [ConversationManager sharedManager]
 */
@interface ConversationManager : NSObject
{
  NSMutableArray *conversations;
  Conversation *currentConversation;
  NSString *storageDirectory;
}


/**
 * Returns the shared ConversationManager singleton instance.
 *
 * @return The singleton ConversationManager instance
 */
+ (ConversationManager *)sharedManager;


/**
 * Creates a new conversation with a default title.
 *
 * The new conversation is automatically selected as the current conversation
 * and added to the conversation list.
 *
 * @return The newly created Conversation instance
 */
- (Conversation *)createNewConversation;


/**
 * Deletes a conversation from the manager and disk.
 *
 * If the deleted conversation is the current conversation, automatically
 * selects another conversation or creates a new one if none remain.
 *
 * @param conversation The conversation to delete
 */
- (void)deleteConversation:(Conversation *)conversation;

@end
```

### Implementation Comments

```objc
// MARK: - Initialization

- (id)init
{
  self = [super init];

  if (self)
  {
    // Initialize storage
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
      NSApplicationSupportDirectory,
      NSUserDomainMask,
      YES
    );
    NSString *appSupport = [paths objectAtIndex:0];

    // Create conversation directory if needed
    storageDirectory = [[appSupport stringByAppendingPathComponent:@"ClaudeChat"] retain];
    [self ensureDirectoryExists];

    // Load existing conversations from disk
    conversations = [[NSMutableArray alloc] init];
    [self loadConversations];

    // Ensure we always have at least one conversation
    if ([conversations count] == 0)
    {
      [self createNewConversation];
    }
  }

  return self;
}
```

## Code Organization

### #pragma mark Sections

Use `#pragma mark` to organize code into logical sections:

```objc
@implementation MyClass

////////////////////////////////////////////////////////////////////////////////
// MARK: - Lifecycle
////////////////////////////////////////////////////////////////////////////////

- (id)init
{
  // ...
}


- (void)dealloc
{
  // ...
}


////////////////////////////////////////////////////////////////////////////////
// MARK: - Public Methods
////////////////////////////////////////////////////////////////////////////////

- (void)publicMethod
{
  // ...
}


////////////////////////////////////////////////////////////////////////////////
// MARK: - Private Methods
////////////////////////////////////////////////////////////////////////////////

- (void)privateHelperMethod
{
  // ...
}


////////////////////////////////////////////////////////////////////////////////
// MARK: - Protocol Conformance
// MARK: NSTableViewDataSource
////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  // ...
}


@end
```

### Section Order

Standard order for implementation files:

1. License/Copyright header
2. `#import` statements
3. Constants and defines
4. Private interface extension
5. `@implementation`
   - Lifecycle (`init`, `dealloc`)
   - Properties
   - Public methods
   - Private methods
   - Protocol conformance methods

## Naming Conventions

### Classes

PascalCase:
```objc
@interface ConversationManager : NSObject
@interface HTTPSClient : NSObject
```

### Methods

camelCase, descriptive:
```objc
- (void)sendMessage:(NSString *)message;
- (BOOL)isConversationEmpty;
- (NSArray *)allConversations;
```

### Variables

camelCase, descriptive:
```objc
NSString *userName;
int messageCount;
BOOL isConnected;
```

### Instance Variables

Prefix with underscore:
```objc
@interface MyClass : NSObject
{
  NSString *_name;
  int _count;
}
@end
```

### Constants

Prefix with k or ALL_CAPS:
```objc
#define MAX_MESSAGES 100
static const int kDefaultPort = 443;
static NSString * const kAPIEndpoint = @"https://api.anthropic.com";
```

## Platform Compatibility

### Availability Checks

Use compile-time and runtime checks:

```objc
// Compile-time check
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_9
  // Code that requires 10.9 SDK to compile
  if (NSClassFromString(@"NSURLSession"))
  {
    // Runtime check: only execute if NSURLSession actually exists
    [self useModernNetworking];
  }
  else
  {
    [self useLegacyNetworking];
  }
#else
  // Tiger/Leopard fallback
  [self useLegacyNetworking];
#endif
```

### C99 Features

Avoid C99-only features on Tiger (10.4):

```objc
// ✗ WRONG (C99)
for (int i = 0; i < count; i++)  // Variable declaration in loop

// ✓ CORRECT (C89)
int i;
for (i = 0; i < count; i++)
```

### Modern Objective-C

Don't use features unavailable on Tiger:

```objc
// ✗ WRONG (Requires 10.5+)
@property (nonatomic, retain) NSString *name;
@synthesize name;

// ✓ CORRECT (Tiger-compatible using macros)
NEHProperty(NSString*, name, setName);

@implementation MyClass
NEMProperty(NSString*, name, setName);
@end
```

## Memory Management

Follow manual reference counting (MRC):

```objc
- (id)init
{
  self = [super init];

  if (self)
  {
    // Retain owned objects
    _name = [[NSString stringWithString:@"default"] retain];
    _items = [[NSMutableArray alloc] init];  // alloc/init already retained
  }

  return self;
}


- (void)dealloc
{
  // Release all retained objects
  [_name release];
  [_items release];
  [super dealloc];
}


- (void)setName:(NSString *)name
{
  // Proper setter with retain/release
  if (_name != name)
  {
    [_name release];
    _name = [name retain];
  }
}
```

## File Headers

Standard header for all files:

```objc
////////////////////////////////////////////////////////////////////////////////
// ConversationManager.m
// ClaudeChat
//
// Manages chat conversations and persistence across application sessions.
// Handles conversation creation, deletion, loading, and saving.
//
// Compatibility: Mac OS X 10.4 Tiger and later
// Copyright (c) 2024 Nyteshade. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import "ConversationManager.h"
```

## Examples

### Complete Header Example

```objc
////////////////////////////////////////////////////////////////////////////////
// HTTPSClient.h
// ClaudeChat
//
// Cross-platform HTTPS client supporting both modern and legacy macOS versions.
//
// Compatibility: Mac OS X 10.4 Tiger and later
// Copyright (c) 2024 Nyteshade. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>


/**
 * @class HTTPSClient
 * @brief HTTPS network client with TLS support
 *
 * Provides HTTPS communication capabilities across all supported macOS versions.
 * Uses platform-appropriate networking APIs (NSURLConnection on modern systems,
 * OpenSSL on Tiger/Leopard).
 */
@interface HTTPSClient : NSObject
{
  NSString *hostname;
  int port;
}


/**
 * Initializes an HTTPS client for the specified host and port.
 *
 * @param host The hostname or IP address to connect to
 * @param portNum The port number (typically 443 for HTTPS)
 * @return An initialized HTTPSClient instance
 */
- (id)initWithHost:(NSString *)host port:(int)portNum;


/**
 * Sends a synchronous POST request to the specified path.
 *
 * @param path The request path (e.g., "/v1/messages")
 * @param headers Dictionary of HTTP headers to include
 * @param bodyData Request body data
 * @return Response data, or nil on error
 */
- (NSData *)sendPOSTRequest:(NSString *)path
                    headers:(NSDictionary *)headers
                       body:(NSData *)bodyData;

@end
```

### Complete Implementation Example

```objc
////////////////////////////////////////////////////////////////////////////////
// HTTPSClient.m
// ClaudeChat
//
// Implementation of cross-platform HTTPS client.
//
// Compatibility: Mac OS X 10.4 Tiger and later
// Copyright (c) 2024 Nyteshade. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import "HTTPSClient.h"


@implementation HTTPSClient

////////////////////////////////////////////////////////////////////////////////
// MARK: - Lifecycle
////////////////////////////////////////////////////////////////////////////////

- (id)initWithHost:(NSString *)host port:(int)portNum
{
  self = [super init];

  if (self)
  {
    hostname = [host retain];
    port = portNum;
  }

  return self;
}


- (void)dealloc
{
  [hostname release];
  [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////
// MARK: - HTTP Methods
////////////////////////////////////////////////////////////////////////////////

- (NSData *)sendPOSTRequest:(NSString *)path
                    headers:(NSDictionary *)headers
                       body:(NSData *)bodyData
{
  NSString *urlString = [NSString stringWithFormat:@"https://%@:%d%@",
                         hostname, port, path];
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  NSEnumerator *keyEnum = [headers keyEnumerator];
  NSString *key;

  // Configure request
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:bodyData];

  // Add headers
  while ((key = [keyEnum nextObject]))
  {
    NSString *value = [headers objectForKey:key];
    [request setValue:value forHTTPHeaderField:key];
  }

  // Send request
  NSError *error = nil;
  NSURLResponse *response = nil;
  NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                               returningResponse:&response
                                                           error:&error];

  if (error)
  {
    NSLog(@"HTTPSClient error: %@", [error localizedDescription]);
    return nil;
  }

  return responseData;
}

@end
```

## Tools

Use the provided reformatting script:

```bash
# Reformat single file
./tools/reformat-code.sh ConversationManager.m

# Reformat all files
./tools/reformat-all.sh
```

## Editor Configuration

### Xcode

```
Preferences → Text Editing → Indentation
☑ Prefer indent using: Spaces
  Tab width: 2 spaces
  Indent width: 2 spaces
```

### VS Code

```json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true
}
```

### Vim

```vim
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
```

## Checklist

Before committing code:

- [ ] Indentation is 2 spaces (no tabs)
- [ ] Opening braces on new lines for methods
- [ ] 2 blank lines between methods/functions
- [ ] Variables declared at top of functions
- [ ] Comprehensive header documentation
- [ ] `#pragma mark` sections added
- [ ] No C99-only features (Tiger compatibility)
- [ ] Proper memory management (retain/release)
- [ ] Platform availability checks where needed
- [ ] Trailing whitespace removed
- [ ] File ends with newline
