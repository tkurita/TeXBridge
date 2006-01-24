#import <Cocoa/Cocoa.h>
#include <ApplicationServices/ApplicationServices.h>

@interface EditorClient : NSObject {

}

+(BOOL) jumpToFile:(FSRef *)pFileRef paragraph:(NSNumber *)npar;

@end
