#import "EditorClient.h"
#import "SmartActivate.h"
#include <unistd.h>

#define useLog 0
const OSType miSignature = 'MMKE';

void typeCommandB() {
	/* emulate keytype of pressing Cmd-B */
	CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, true );
	CGPostKeyboardEvent( (CGCharCode)'B', (CGKeyCode)11, true );
	CGPostKeyboardEvent( (CGCharCode)'B', (CGKeyCode)11, false );
	CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, false );
}
#import "SmartActivate.h"

OSErr selectParagraphOfmi(long parIndex){
	/* send AppleEvent to me to select paragrah parIndex in Front document*/
	//OSType miSignature = 'MMKE';
	AppleEvent event, reply;
	OSErr err;
	
	err = AEBuildAppleEvent(
							kAEMiscStandards, kAESelect,
							typeApplSignature, &miSignature, sizeof(miSignature),
							kAutoGenerateReturnID, kAnyTransactionID,
							&event, /* 作成するイベント */
							NULL, /* エラー情報を必要としない */
							"'----':'obj '{form:indx, want:type(cpar), seld:long(@),from:'obj '{form:indx, want:type(docu), seld:short(1), from:'null'()}}", /* 書式指定文字列 */
							parIndex); 
	err = AESendMessage(&event,&reply,kAEWaitReply ,30);
	return(err);
}

@implementation EditorClient

+ (BOOL)jumpToFile:(FSRef *)pFileRef paragraph:(NSNumber *)npar
{
	OSErr err;
	
	FSRef appRef;
	LSLaunchFSRefSpec launchWithMiSpec;
	ProcessSerialNumber psn;	
	
	/* check mi process */
	NSDictionary *pDict = getProcessInfo(@"MMKE", nil, nil);
		
	if (pDict == NULL) {
		/* mi is not launched. */
		launchWithMiSpec.launchFlags = kLSLaunchDefaults;
		err = LSFindApplicationForInfo (miSignature, NULL, CFSTR("mi"), &appRef, NULL);
		if (err != noErr ) {
			//printf("Error in miclient : The Application mi could not be found.\n");
			return NO;
		}
	}
	else{
		/* mi is launched. */
		launchWithMiSpec.launchFlags = kLSLaunchDontSwitch;
		//launchWithMiSpec.launchFlags = kLSLaunchDefaults;
		
		[[pDict objectForKey:@"PSN"] getValue:&psn];
		err = GetProcessBundleLocation(&psn, &appRef);
	}
		
	launchWithMiSpec.appRef = &appRef;
	launchWithMiSpec.numDocs = 1;
	launchWithMiSpec.itemRefs = pFileRef;
	launchWithMiSpec.passThruParams = NULL;
	
	err = LSOpenFromRefSpec(&launchWithMiSpec, NULL);
	BOOL bFlag = YES;
	if (err == noErr) {
		//printf("success to launch mi\n");
		if (pDict != NULL) {
			//printf("mi will be activate\n");
			SetFrontProcessWithOptions(&psn,kSetFrontProcessFrontWindowOnly);
		}
		
		if (npar != nil) {
			long parIndex = [npar longValue];
			if (bFlag) {
				//printf("will type Command-B\n");
				typeCommandB();
				usleep(200000);
			}
			
			err = selectParagraphOfmi(parIndex);
		}
	}
	else {
		//printf("err in launch\n");
	}
	[pDict release];
	
	return err == noErr;
}

@end
