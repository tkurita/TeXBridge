/* SettingWindowController */

#import <Cocoa/Cocoa.h>

@interface SettingWindowController : NSWindowController
{
	IBOutlet id appArrayController;
	IBOutlet NSTabView *tabView;
	IBOutlet NSPopUpButton *settingMenu;
	IBOutlet NSDictionaryController *userRIDictController;
}

@property NSMutableArray *arrangedInternalReplaceInputDict_;

- (IBAction)showSettingHelp:(id)sender;
- (IBAction)addApp:(id)sender;
- (IBAction)reloadSettingsMenu:(id)sender;
- (IBAction)revertToFactoryDefaults:(id)sender;
- (IBAction)changeDVIPreviewer:(id)sender;
- (IBAction)changePDFPreviewer:(id)sender;
- (NSMutableArray *)arrangedInternalReplaceInputDict;

@end
