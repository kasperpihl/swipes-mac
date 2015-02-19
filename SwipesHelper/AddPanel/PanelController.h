#import <Cocoa/Cocoa.h>

#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
}

@property (nonatomic, weak) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, weak) IBOutlet NSTextField *textField;
@property (nonatomic, weak) IBOutlet NSButton *addButton;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, weak, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
-(IBAction)actionSent:(id)sender;

@end
