#import "TeXDocument.h"
#import "mi.h"
#import "PathExtra.h"

@implementation TeXDocument

@synthesize file;
@synthesize textEncoding;
@synthesize name;
@synthesize pathWithoutSuffix;
@synthesize hasMaster;

static NSArray *SUPPORTED_MODES = nil;

+ (void)initialize
{
	if (! SUPPORTED_MODES) {
		SUPPORTED_MODES = [[NSArray arrayWithObjects:@"TEX", @"TeX", @"LaTeX", nil] retain];
	}
}

+ (TeXDocument *)frontTexDocumentReturningError:(NSError **)error;
{	
	miDocument *front_doc = nil;
	TeXDocument *result = nil;
	miApplication *mi_app = [SBApplication applicationWithBundleIdentifier:@"net.mimikaki.mi"];
	if ([[[mi_app documents] objectAtIndex:0] exists]) {
		front_doc = [[mi_app documents] objectAtIndex:0];
	} else {
		// ToDo : describe error
		goto bail;
	}
	NSString *mode = [front_doc mode];
	if (! [SUPPORTED_MODES containsObject:mode]) {
		// ToDo : describe error
		goto bail;
	}
	
	NSURL *url = [front_doc file];
	
	result = [TeXDocument new];
	if (url) {
		result.file = url;
		NSString *a_path = [url path];
		result.pathWithoutSuffix = [a_path stringByDeletingPathExtension];
		result.name = [a_path lastPathComponent];
	} else {
		result.name = [front_doc name];
	}
	
	result.textEncoding = [front_doc textEncoding];
	
bail:
	return result;
}

+ (TeXDocument *)texDocumentWithPath:(NSString *)pathname textEncoding:(NSString *)encodingName
{
	TeXDocument *tex_doc = [[TeXDocument new] autorelease];
	tex_doc.file = [NSURL fileURLWithPath:pathname];
	tex_doc.textEncoding = encodingName;
	tex_doc.pathWithoutSuffix = [pathname stringByDeletingPathExtension];
	tex_doc.name = [pathname lastPathComponent];
	return tex_doc;
}

- (TeXDocument *)resolveMasterFromEditor
{
	TeXDocument *result = self;
	miApplication *mi_app = [SBApplication applicationWithBundleIdentifier:@"net.mimikaki.mi"];
	miDocument *front_doc = [[mi_app documents] objectAtIndex:0];
	SBElementArray *lines = [front_doc paragraphs];
	NSString *line_content = nil;
	NSString *masterfile_command = @"%ParentFile";
	for (miParagraph *a_line in lines) {
		line_content = [a_line content];
		if (! [line_content hasPrefix:@"%"] ) goto bail;
		if ([line_content hasPrefix:masterfile_command]) break;
	}
	NSUInteger command_len = [masterfile_command length];
	NSRange range = NSMakeRange(command_len+1, [line_content length]-command_len-2);
	NSString *masterfile_path = [line_content substringWithRange:range];
	// ToDo : remove tailing and headding spaces
	if ([masterfile_path hasPrefix:@":"]) { //relative HFS path
		NSString *hfs_base_path = [[[file path] stringByDeletingLastPathComponent] hfsPath];
		NSString *hfs_abs_path = [hfs_base_path stringByAppendingString:masterfile_path];
		masterfile_path = [hfs_abs_path posixPath];
		
	} else if (! [masterfile_path hasPrefix:@"/"]) { //relative POSIX Path
		masterfile_path = [[NSURL URLWithString:masterfile_path relativeToURL:file] path];
	}
	result = [TeXDocument texDocumentWithPath:masterfile_path textEncoding:textEncoding];
	if (result) hasMaster = YES;
bail:	
	return result;
}

- (void)dealloc
{
	[file release];
	[textEncoding release];
	[name release];
	[pathWithoutSuffix release];
	[super dealloc];
}

@end
