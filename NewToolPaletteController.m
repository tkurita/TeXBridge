#import "NewToolPaletteController.h"

#define useLog 0
@implementation NewToolPaletteController

- (BOOL)windowShouldClose:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:NO 
											forKey:@"IsOpenedToolPalette"];
	return [super windowShouldClose:sender];	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillTerminate in NewToolPaletteController");
#endif
    NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:[self isOpened] forKey:@"IsOpenedToolPalette"];
	[super applicationWillTerminate:aNotification];
}


- (void)awakeFromNib
{
	[self setFrameName:@"NewToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
    [self setCollapsedStateName:@"IsCollapsedToolPalette"];
	[self.window setShowsToolbarButton:NO];
    self.toolbarItems=[NSMutableDictionary dictionary];
}

- (void)showStatusMessage:(NSString *)msg
{
	[statusLabel setStringValue:msg];
	[self.window displayIfNeeded];
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
                                       label:(NSString *)label
                                 paleteLabel:(NSString *)paletteLabel
                                     toolTip:(NSString *)toolTip
                                      target:(id)target
                                 itemContent:(id)imageOrView
                                      action:(SEL)action
                                        menu:(NSMenu *)menu
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    [item setAction:action];
    
    // Set the right attribute, depending on if we were given an image or a view
    if([imageOrView isKindOfClass:[NSImage class]]){
        [item setImage:imageOrView];
    } else if ([imageOrView isKindOfClass:[NSView class]]){
        [item setView:imageOrView];
    }else {
        assert(!"Invalid itemContent: object");
    }
    
    
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it
    // (for text-only mode), we set it up here.  Actually, you have to hand an NSMenuItem
    // (not a complete NSMenu) to the toolbar item, so we create a dummy NSMenuItem that has our real
    // menu as a submenu.
    //
    if (menu != nil)
    {
        // we actually need an NSMenuItem here, so we construct one
        NSMenuItem *mItem = [NSMenuItem new];
        [mItem setSubmenu:menu];
        [mItem setTitle:label];
        [item setMenuFormRepresentation:mItem];
    }
    return item;
}

//It looks called for only toolbar items which is not defined in Nib.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
#if useLog
    NSLog(@"start toolbar:itemForItemIdentifier:%@", itemIdentifier);
#endif
    NSToolbarItem *toolbar_item = _toolbarItems[itemIdentifier];
    if (toolbar_item) {
        return toolbar_item;
    }
    
    NSString *label;
    NSString *tool_tip;
    if ([itemIdentifier isEqualToString:@"Help"]) {
        label = NSLocalizedString(@"Help", @"Toolbar's label for Help");
        tool_tip = NSLocalizedString(@"Show TeX Tools Help", @"Toolbar's tool tip for Help");
        toolbar_item = [self toolbarItemWithIdentifier:itemIdentifier
                                                 label:label
                                           paleteLabel:label
                                               toolTip:tool_tip
                                                target:nil
                                           itemContent:helpButtonView
                                                action:nil
                                                  menu:nil];
    } else {
        NSLog(@"unknown toolbar identifier : %@", itemIdentifier);
    }
    _toolbarItems[itemIdentifier] = toolbar_item;
    return toolbar_item;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[@"QuickTeXtoDVI", @"DVIPreview", @"DVItoPDF", @"TypesetPDFPreview", @"TeXToolsSettings", @"Help"];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return @[@"QuickTeXtoDVI", @"DVIPreview", @"DVItoPDF", @"TypesetPDFPreview", @"TeXToolsSettings", @"Help"];
}

@end
