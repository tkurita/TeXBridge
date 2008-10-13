/* SettingWindowController */

#import <Cocoa/Cocoa.h>

@interface SettingWindowController : NSWindowController
{
	IBOutlet id appArrayController;
	IBOutlet NSTabView *tabView;
	IBOutlet NSPopUpButton *settingMenu;
	IBOutlet NSDictionaryController *userRIDictController;
	NSMutableArray *arrangedInternalReplaceInputDict;
}

- (IBAction)showSettingHelp:(id)sender;
- (IBAction)addApp:(id)sender;
- (IBAction)reloadSettingsMenu:(id)sender;
- (IBAction)revertToFactoryDefaults:(id)sender;
- (NSMutableArray *)arrangedInternalReplaceInputDict;

@end
