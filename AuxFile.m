#import "AuxFile.h"
#import "PathExtra.h"
#import "StringExtra.h"
#import "AppController.h"
#import "LabelDatum.h"
#import "miClient.h"
#import "RegexKitLite.h"

@implementation AuxFile

@synthesize basename;
@synthesize nodeIcon;
@synthesize texDocument;
@synthesize auxFilePath;
@synthesize labelsFromAux;
@synthesize labelsFromEditor;
@synthesize checkedTime;
@synthesize texDocumentSize;

- (void)dealloc
{
	[basename release];
	[nodeIcon release];
	[texDocument release];
	[auxFilePath release];
	[labelsFromAux release];
	[labelsFromEditor release];
	[checkedTime release];
	[super dealloc];
}

+ (AuxFile *)auxFileWithTexDocument:(TeXDocument *)aTeXDocument
{
	AuxFile *result = [[AuxFile new] autorelease];
	result.basename = [aTeXDocument.name stringByDeletingPathExtension];
	result.texDocument = aTeXDocument;
	result.labelsFromAux = [NSMutableArray array];
	result.labelsFromEditor = [NSMutableArray array];
	if (aTeXDocument.file) {
		[result checkAuxFile];
	}
	
	return result;
}

// check existance of path before calling this method.
+ (AuxFile *)auxFileWithPath:(NSString *)path textEncoding:(NSString *)encodingName
{
	AuxFile *result = [[AuxFile new] autorelease];
	NSString *tex_doc_path = [[path stringByDeletingPathExtension] 
							  stringByAppendingPathExtension:@"tex"];
	TeXDocument *tex_doc = [TeXDocument texDocumentWithPath:tex_doc_path 
											   textEncoding:encodingName];
	result.texDocument = tex_doc;
	result.basename = [tex_doc.name stringByDeletingPathExtension];
	result.auxFilePath = path;
	result.labelsFromAux = [NSMutableArray array];
	result.labelsFromEditor = [NSMutableArray array];

	return result;
}

- (NSTreeNode *)treeNode
{
	//NSLog(@"start treeNode, retainCount:%d", [self retainCount]);
	if (! treeNode) {
		treeNode = [[NSTreeNode treeNodeWithRepresentedObject:self] retain];
	}
	//NSLog(@"end treeNode, retainCount:%d", [self retainCount]);
	return treeNode;
}

- (BOOL)hasTreeNode
{
	return (treeNode != nil);
}

- (BOOL)hasMaster
{
	return [texDocument hasMaster];
}

- (void)checkAuxFile
{
	if (! auxFilePath) {
		NSString *aux_file_path = [[[texDocument.file path] stringByDeletingPathExtension]
								   stringByAppendingPathExtension:@"aux"];
		if ([aux_file_path fileExists]) {
			self.auxFilePath = aux_file_path;
		}
	}
}

- (NSString *)readAuxFileReturningError:(NSError **)error
{
	NSData *data = [NSData dataWithContentsOfFile:auxFilePath options:0 error:error];
	if (! data) return nil;
	NSArray *encodings = orderdEncodingCandidates(texDocument.textEncoding);
	return [NSString stringWithData:data encodingCandidates:encodings];
}

- (void)addLabelFromAux:(NSString *)labelName referenceName:(NSString *)refName
{
	[labelsFromAux addObject:
		[LabelDatum labelDatumWithName:labelName referenceName:refName]];
}

- (void)addLabelFromEditor:(NSString *)labelNamel
{
	[labelsFromEditor addObject:
	 [LabelDatum labelDatumWithName:labelNamel referenceName:@"--"]];
}

- (void)addChildAuxFile:(AuxFile *)childAuxFile
{
	[labelsFromAux addObject:childAuxFile];
}

- (BOOL)hasLabel:(NSString *)labelName
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", labelName];
	NSArray *array = [labelsFromAux filteredArrayUsingPredicate:predicate];
	return ([array count] > 0);
}

- (void)updateCheckTime
{
	self.checkedTime = [NSDate date];
}

- (BOOL)isTexFileUpdated
{
	if (!texDocument.file) return NO;
	
	NSError *error = nil;
	NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[texDocument.file path]
																		  error:&error];
	if (! dict) return NO; // unknown error
	
	NSDate *mod_date = [dict fileModificationDate];
	
	return ([mod_date compare:checkedTime] == NSOrderedDescending);
}

- (void)clearLabelsFromEditor
{
	self.labelsFromEditor = [NSMutableArray array];
}

- (BOOL)findLabelsFromEditorWithForceUpdate:(BOOL)forceUpdate
{
	miClient *editor_client = [miClient sharedClient];
	NSString *content = [editor_client currentDocumentContent];
	if (! content) return NO;
	NSArray *paragraphs = [content paragraphs];
	NSUInteger current_doc_size = [content length];
	if ((!forceUpdate) && (![self isTexFileUpdated])) {
		if (texDocumentSize == current_doc_size) return NO;
	}
	
	[self clearLabelsFromEditor];
	NSCharacterSet *spaces_set = [NSCharacterSet whitespaceCharacterSet];
	NSString *scaned_string;	
	for (NSString *a_line in paragraphs ) {
#if useLog
		NSLog(@"findLabelsFromEditor : %@", a_line);
#endif		
		a_line = [a_line stringByTrimmingCharactersInSet:spaces_set];		
		if (! [a_line length] ) continue;
		if ([a_line hasPrefix:@"%"]) continue;
		
		// remove comment
		NSScanner *scanner = [NSScanner scannerWithString:a_line];
		NSMutableString *clean_line = [NSMutableString stringWithCapacity:[a_line length]];
		while (![scanner isAtEnd]) {
			if ([scanner scanUpToString:@"%" intoString:&scaned_string]) {
				[clean_line appendString:scaned_string];
				if (! [scaned_string hasSuffix:@"\\"]) break;
				[clean_line appendString:@"%"];
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
			//NSLog(@"isAtEnd : %d, scan location : %d", [scanner isAtEnd], [scanner scanLocation]);
		}
		
		// find label command
		NSArray *captures = [clean_line arrayOfCaptureComponentsMatchedByRegex:@"\\\\label\\{([^{}]+)\\}"];
		if (! [captures count]) continue;
		for (NSArray *a_capture in captures) {
			NSString *label_name = [a_capture objectAtIndex:1];
			if (![self hasLabel:label_name]) {
				[self addLabelFromEditor:label_name];
			}
		}
#if useLog
		NSLog(@"%@", captures);
#endif				
	}
	[self updateCheckTime];
	texDocumentSize = current_doc_size;
	return YES;
}

- (void)insertIntoTree:(NSTreeController *)treeController atIndexPath:(NSIndexPath *)indexPath // may not used
{
	[treeController insertObject:[self treeNode] atArrangedObjectIndexPath:indexPath];
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	for (id child_item in labelsFromAux) {
		NSTreeNode *child_node = [child_item treeNode];
		[child_nodes addObject:child_node];
	}
}

- (void)updateLabelsFromEditor
{
	NSLog(@"start updateLabelsFromEditor");
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	NSUInteger n_labels_from_editor = [labelsFromEditor count];
	NSUInteger lab_count = 0;
	
	for (NSUInteger n=[labelsFromAux count]; n < [child_nodes count]; n++) {
		if (lab_count < n_labels_from_editor) {
			[child_nodes replaceObjectAtIndex:n 
						   withObject:[[labelsFromEditor objectAtIndex:lab_count] treeNode]];
		} else {
			[child_nodes removeObjectAtIndex:n];
		}
		lab_count++;
	}

	for (NSUInteger n=lab_count; n < n_labels_from_editor; n++) {
		[child_nodes addObject:[[labelsFromEditor objectAtIndex:n] treeNode]];
	}
	
	NSLog(@"end updateLabelsFromEditor");
}

- (NSString *)name
{
	return basename;
}

- (NSString *)referenceName
{
	return @"";
}

- (NSString *)pathWithoutSuffix
{
	return texDocument.pathWithoutSuffix;
}
@end
