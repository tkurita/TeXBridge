/* SettingWindowController */

#import <Cocoa/Cocoa.h>

@interface SettingWindowController : NSWindowController
{
    IBOutlet id tabView;
	IBOutlet id appArrayController;
}
- (IBAction)showSettingHelp:(id)sender;
- (IBAction)addApp:(id)sender;
@end
