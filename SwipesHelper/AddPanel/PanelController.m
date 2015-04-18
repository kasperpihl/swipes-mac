#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"

#define OPEN_DURATION 0.15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 150
#define PANEL_WIDTH 320
#define MENU_ANIMATION_DURATION .1

#define BasicTableViewDragAndDropDataType @"BasicTableViewDragAndDropDataType"
#pragma mark -
@interface PanelController () <NSTextFieldDelegate>
@property (nonatomic, strong) NSProgressIndicator *indicator;
@end

@implementation PanelController
@synthesize indicator = _indicator;
@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize textField = _textField;
@synthesize addButton = _addButton;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
        _textField.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    NSLog(@"%@",fieldEditor);
    return YES;
}
-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    // See if it was due to a return
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement )
    {
        NSLog(@"Return was pressed!");
    }
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Follow search string
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark - Public accessors
-(IBAction)actionSent:(id)sender{
    NSString *task = [self.textField stringValue];
    task = [task stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(task.length > 255)
        task = [task substringToIndex:255];
    if(task.length == 0){
        return;
    }
    [self.window makeFirstResponder:nil];
    [self.textField setSelectable:NO];
    [self.textField setEditable:NO];
    self.indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, 30, 30)];
    [self.indicator setStyle:NSProgressIndicatorSpinningStyle];
    CGPoint center = CGPointMake(self.addButton.frame.origin.x+self.addButton.frame.size.width/2, self.addButton.frame.origin.y+self.addButton.frame.size.height/2);
    self.indicator.frame = CGRectMake(center.x-30/2, center.y-30/2, 30, 30);
    self.addButton.hidden = YES;
    [self.backgroundView addSubview:self.indicator];
    [self.indicator startAnimation:nil];
    [self addTaskToServer:task];
}
-(void)addTaskToServer:(NSString*)task{
    NSString *sessionToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"sessionToken"];
    if(sessionToken){
        NSMutableDictionary *syncData = [@{
                                           @"sessionToken": sessionToken,
                                           @"changesOnly" : @YES,
                                           @"hasMoreToSave": @(YES),
                                           @"platform" : @"mac",
                                           @"sendLogs": @(YES),
                                           @"version": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]}
                                         mutableCopy];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"];
        NSString *isoDate = [dateFormatter stringFromDate:[NSDate date]];
        
        NSDictionary *taskObject = @{@"title": task, @"schedule":@{@"__type": @"Date",@"iso":isoDate} , @"order": @(-1), @"tempId": [PanelController generateIdWithLength:14]};
        NSDictionary *objects = @{ @"ToDo":@[taskObject], @"Tag":@[]};
        [syncData setObject:objects forKey:@"objects"];
        
        /* Preparing request */
        NSError *error;
        
        NSString *url = @"http://api.swipesapp.com/v1/sync";
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setTimeoutInterval:35];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:syncData
                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if(error){
            
        }
        
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        [request setHTTPBody:jsonData];
        
        
        /* Performing request */
        NSHTTPURLResponse *response;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh-webview" object:self];
    }
    [self.indicator removeFromSuperview];
    self.indicator = nil;
    self.addButton.hidden = NO;
    [self.textField setEditable:YES];
    [self.textField setSelectable:YES];
    [self.textField setStringValue:@""];
    [self.window makeFirstResponder:self.textField];
    NSSound *sound = [NSSound soundNamed:@"swipes-notification.aiff"];
    [sound play];
}
+(NSString*)generateIdWithLength:(NSInteger)length{
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}
- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET;
    textRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(textRect);
    if (NSIsEmptyRect(textRect))
    {
        //[self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        //[self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = POPUP_HEIGHT;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel setLevel:NSStatusWindowLevel];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    NSLog(@"firing %f : %f",panelRect.origin.x, panelRect.origin.y);
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

@end
