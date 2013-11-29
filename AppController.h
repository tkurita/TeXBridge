/* AppController */

#import <Cocoa/Cocoa.h>
//#import <OSAKit/OSAScript.h>
#import "miClient.h"
#import "SettingWindowController.h"
#import "NewToolPaletteController.h"
#import "NewRefPanelController.h"

NSArray *orderdEncodingCandidates(NSString *firstCandidateName);

@interface TeXBridgeController : NSObject
- (void)setup;
- (void)changePDFPreviewer:(id)sender;
- (id)performTask:(id)script;
- (void)performHandler:(NSString *)handlerName;
- (id)checkGUIScripting;
@end

@interface AppController : NSObject
{
	IBOutlet id startupWindow;
	IBOutlet id startupMessageField;
	IBOutlet id texBridgeController;
	NSTimer *appQuitTimer;
	NSDictionary *factoryDefaults;
	SettingWindowController *settingWindow;
	NewToolPaletteController *toolPaletteController;
	NewRefPanelController *refPanelController;
//	OSAScript *script; 
}

+ (id)sharedAppController;

- (void)anApplicationIsTerminated:(NSNotification *)aNotification;
- (void)checkQuit:(NSTimer *)aTimer;
- (id)factoryDefaultForKey:(NSString *)theKey;
- (void)revertToFactoryDefaultForKey:(NSString *)theKey;

- (IBAction)quickTypesetPreview:(id)sender;
- (IBAction)dviPreview:(id)sender;
- (IBAction)dviToPDF:(id)sender;
- (IBAction)typesetPDFPreview:(id)sender;
- (IBAction)showSettingWindow:(id)sender;
- (IBAction)showToolPalette:(id)sender;
- (IBAction)showRefPalette:(id)sender;
- (TeXBridgeController *)texBridgeController;
@end


