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
- (void)quickTypesetPreview;
- (void)dviPreview;
- (void)typesetPDFPreview;
- (void)dviToPDF;
@end

@interface AppController : NSObject
{
	IBOutlet id startupWindow;
	IBOutlet id startupMessageField;
}

@property NSTimer *appQuitTimer;
@property NSDictionary *factoryDefaults;
@property SettingWindowController *settingWindow;
@property NewToolPaletteController *toolPaletteController;
@property NewRefPanelController *refPanelController;
@property (assign) IBOutlet id texBridgeController;

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

@end


