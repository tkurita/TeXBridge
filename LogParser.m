#import "LogParser.h"
#import "LogWindowController.h"
#import "FileRecord.h"

#define useLog 0 //Yes:1, No:0

NSMutableDictionary *makeLogRecord(NSString* logContents, unsigned int theNumber, NSRange theRange) {
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	NSNumber * lineNumber = [NSNumber numberWithUnsignedInt:theNumber];
	[dict setObject:logContents forKey:@"content"];
	[dict setObject:lineNumber forKey:@"lineNumber"];
	[dict setObject:[NSValue valueWithRange:theRange] forKey:@"range"];

	return dict;
}

@implementation LogParser

- (ErrorRecord *) makeErrorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn textRange:(NSValue *)theRange
{
	ErrorRecord *theErrorRecord = [ErrorRecord errorRecordWithString: errMsg paragraph:errpn];
	[theErrorRecord setLogContents:logContents];
	[theErrorRecord setTextRange:theRange];
	return theErrorRecord;
}

- (BOOL) isLabelsChanged
{
	return self->isLabelsChanged;
}

#pragma mark initilize and dealloc
- (id)init
{
	[super init];
	currentLineNumber = 0;
	newlineCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] retain];
	whitespaceCharSet = [[NSCharacterSet whitespaceCharacterSet] retain];
	isLabelsChanged = NO;
	errorRecordTree = [[NSMutableArray array] retain];
	texFileExtensions = [[NSArray arrayWithObjects:@".tex", @".cls", @".sty", @".aux", @".dtx", @".txt", @".bbl", @".ind",nil] retain];
	isNoError = YES;
	return self;
}

-(void)dealloc{
	[newlineCharacterSet release];
	[whitespaceCharSet release];
	[logFilePath release];
	[logContents release];
	[texFileExtensions release];
	[errorRecordTree release];
	[texFileExtensions release];
	[super dealloc];
}

- (id)initWithString:(NSString*)targetText
{
	[self init];
	isReadFile = NO;
	[self setLogFilePath:@""];
	[self setLogContents:targetText];
	int length = [logContents length];
	nextRange = NSMakeRange(0, length);
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
	[self init];
	[self setLogFilePath:path];
	isReadFile = YES;
	NSData *logData = [NSData dataWithContentsOfFile:logFilePath];
	[logContents release];
	[self setLogContents:[[[NSString alloc] initWithData:logData encoding:NSShiftJISStringEncoding] autorelease]];
	int length = [logContents length];
	nextRange = NSMakeRange(0, length);
	return self;
}

#pragma mark prepare to view parsed result
- (NSString *) checkTexFileExtensions:(NSString *)targetFile
{
	NSEnumerator * suffixEnumerator = [texFileExtensions objectEnumerator];
	NSString * theSuffix;
	while (theSuffix = [suffixEnumerator nextObject]) {
		if ([targetFile hasSuffix:theSuffix]) {
			return targetFile;
		}
	}
	
	suffixEnumerator = [texFileExtensions objectEnumerator];
	while (theSuffix = [suffixEnumerator nextObject] ) {
		theSuffix = [theSuffix stringByAppendingString:@" "];
		NSRange theRange = [targetFile rangeOfString:theSuffix];
		if (theRange.length != 0) {
			return [targetFile substringWithRange:NSMakeRange(0,NSMaxRange(theRange)-1)];
		}
	}
	return nil;
}

- (void) parseLogTree:(NSMutableArray *) logTree
{
#if useLog
	NSLog(@"start parseLogTree");
	NSLog([logTree description]);
#endif
	if ([logTree count] <= 1) {
		return;
	}
	
	NSEnumerator *enumerator = [logTree objectEnumerator];
	NSString *targetFile = [self getTargetFilePath:enumerator];
	ErrorRecord *theErrorRecord;
	NSMutableArray *errorRecordList = [NSMutableArray array];
	id logItem;
	while (logItem = [enumerator nextObject]) {
		theErrorRecord = [self findErrors:logItem withEnumerator:enumerator];
		if (theErrorRecord) {
			[errorRecordList addObject:theErrorRecord];
		}
	}
	
	if ([errorRecordList count]) {
		FileRecord *theFileRecord = [FileRecord fileRecordForPath:targetFile errorRecords:errorRecordList parent:self];
		[theFileRecord setBaseURL:_baseURL];
		[theFileRecord setLogContents:logContents];
		[errorRecordTree addObject:theFileRecord];
	}
#if useLog	
	NSLog(@"end parseLogTree");
#endif
}

- (ErrorRecord *) findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator
{
#if useLog
	NSLog(@"start findErrors");
#endif
	NSString * logContent;
	
	if ([logTree isKindOfClass: [NSMutableArray class]]) {
		[self parseLogTree:logTree];
		return nil;
	}
	else {
		logContent = [logTree objectForKey:@"content"];
	}

	if ([logContent length] < 1) {
		return nil;
	}
	
	int errpInt;
	NSNumber *errpn = nil;
	id object;
	NSString *nextLogContent;
	NSString *errMsg = nil;	
	
	if ([logContent hasPrefix:@"!"]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
		
		while(object = [enumerator nextObject]) {
			if ([object isKindOfClass: [NSMutableDictionary class]]) {
				nextLogContent = [object objectForKey:@"content"];
			}
			else {
				nextLogContent = [[object objectAtIndex:0] objectForKey:@"content"];
			}
			
			if ([nextLogContent hasPrefix:@"l."]) {
				NSScanner * scanner = [NSScanner scannerWithString:nextLogContent];
				NSString * scannedText;
				if ([scanner scanUpToCharactersFromSet:whitespaceCharSet intoString:&scannedText]) {
					errpInt =  [[scannedText substringWithRange:NSMakeRange(2,[scannedText length]-2)] intValue];
					errpn = [NSNumber numberWithInt:errpInt];
				}
				
				break;
			}
			else if ([nextLogContent hasPrefix:@"?"] || 
					 [nextLogContent hasPrefix:@"Enter file name:"] || [nextLogContent hasPrefix:@"<*>"]){
				break;
			}
		}

	}
	else if ([logContent contain:@"Warning:"]) {
		errMsg = [NSString stringWithString:logContent];	
		if (![logContent hasSuffix:@"."]) {
			object = [enumerator nextObject];
			if ([object isKindOfClass: [NSMutableDictionary class]]) {
				errMsg = [logContent stringByAppendingString:[object objectForKey:@"content"]];
			}			
		}
		
		if ([errMsg contain:@"Label(s) may have changed. Rerun to get cross-references right."]) {
			isLabelsChanged = YES;
		}
		
		NSMutableArray *wordList = [errMsg splitWithCharacterSet:whitespaceCharSet];
		if ([[wordList objectAtIndex:([wordList count] -2)] isEqualToString:@"line"]) {
			errpInt = [[wordList lastObject] intValue];
			errpn = [NSNumber numberWithInt:errpInt];
		}
	}
	
	else if ([logContent hasPrefix:@"Overfull"]||[logContent hasPrefix:@"Underfull"]) {
		errMsg = [NSString stringWithString:logContent];
		NSMutableArray *wordList = [logContent splitWithCharacterSet:whitespaceCharSet];
		NSScanner *scanner = [NSScanner scannerWithString:[wordList lastObject]];
		if ([scanner scanInt:&errpInt]) {
			errpn = [NSNumber numberWithInt:errpInt];	
		}
	}
	
	else if ([logContent hasPrefix:@"No file"]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
	}
	
	else if ([logContent isEqualToString:@"No pages of output."]) {
		errMsg = [NSString stringWithString:logContent];
		isNoError = NO;
		isDviOutput = NO;
	}
	
	else if ([logContent hasPrefix:@"Output written on"]) {
		isDviOutput = YES;
	}
	
#if useLog
	NSLog(@"end of findErrors");
#endif
	
	if (errMsg != nil) {
		return [self makeErrorRecordWithString:errMsg paragraph:errpn textRange:[logTree objectForKey:@"range"]];
	}
	else {
		return nil;
	}
}

- (void) parseLogTreeFirstLevel:(NSMutableArray *)logTree
{
	NSEnumerator *enumerator = [logTree objectEnumerator];
	NSString * targetFile = [[enumerator nextObject] objectForKey:@"content"];
	BOOL noLogFileRef = [targetFile isEqualToString:@""]; //when parsing STDOUT, targetFile will be ""

	ErrorRecord *theErrorRecord;
	NSMutableArray * errorRecordList = [NSMutableArray array];

	id logItem;
	while (logItem = [enumerator nextObject]) {
		theErrorRecord = [self findErrors:logItem withEnumerator:enumerator];
		if (theErrorRecord) {
			if (!noLogFileRef) {
				[theErrorRecord setParagraph:[logItem objectForKey:@"lineNumber"]];
			}
 			[theErrorRecord setParent:self];
			[errorRecordList addObject:theErrorRecord];
		}
	}
	
	if ([errorRecordList count]) {
		if (noLogFileRef) {
			[errorRecordTree addObjectsFromArray:errorRecordList];
		}
		else {
			FileRecord *theFileRecord = [FileRecord fileRecordForPath:targetFile errorRecords:errorRecordList parent:self];
			[theFileRecord setBaseURL:_baseURL];
			[theFileRecord setLogContents:logContents];
			[errorRecordTree addObject:theFileRecord];
		}
	}
}

#pragma mark parse logout of typeset
- (NSString *)getNextLine {
	
	if (nextRange.length > 0) {
		currentRange = [logContents lineRangeForRange:NSMakeRange(nextRange.location, 0)];
		currentString = [logContents substringWithRange:currentRange];
		nextRange.location = NSMaxRange(currentRange);
        nextRange.length -= currentRange.length;
		
		currentLineNumber++;
		
		if ([currentString length] == 1) {
			return [self getNextLine];
		} else {
			//NSLog(currentString);
			currentString = [currentString stringByTrimmingCharactersInSet:newlineCharacterSet];
			return currentString;
		}
	}
	else {
		return nil;
	}
}

- (void)addCurrentLine:(NSMutableArray*)currentList
{
	NSMutableDictionary * dict = makeLogRecord(currentString, currentLineNumber, currentRange);
	[currentList addObject:dict];	
}

- (NSString *)addCurrentLineAndNextLine:(NSMutableArray *)currentList
{
	NSMutableDictionary * dict = makeLogRecord(currentString, currentLineNumber, currentRange);
	[currentList addObject:dict];
	return [self getNextLine];
}

- (void) appendLogRecordWithString:(NSString *)targetText intoList:(NSMutableArray *)targetList {
	NSMutableDictionary * dict = makeLogRecord(targetText, currentLineNumber, currentRange);
	[targetList addObject:dict];
}

- (NSString *) getTargetFilePath:(NSEnumerator *) enumerator
{

	NSString *targetFile = [[enumerator nextObject] objectForKey:@"content"];
	NSString *checkedPath;
	
	if (checkedPath = [self checkTexFileExtensions:targetFile]){
		return checkedPath;
	}
	
	if ([targetFile length] >= 79) {
		NSString * nextCandidate = [targetFile stringByAppendingString:[[enumerator nextObject] objectForKey:@"content"]];
		if (checkedPath = [self checkTexFileExtensions:nextCandidate]) {
			return checkedPath;
		}
		else{
			return nextCandidate;
		}
	}
	return targetFile;
}

-(void) parseFooterWith:(NSMutableArray *)currentList startText:(NSString *)targetText 
{
	while(targetText != nil) {
		targetText = [self addCurrentLineAndNextLine:currentList];
	}
}

- (NSString *) parseLines:(NSString *)targetText withList:(NSMutableArray *)currentList {
#if useLog
	NSLog(@"start parseLines");
#endif
	if (targetText == nil) return nil;
#if useLog
	NSLog(targetText);
#endif
	if ([targetText hasPrefix:@"LaTeX Font Info:"] 
			||[targetText hasPrefix:@"Latex Info"]
			||[targetText hasPrefix:@"\\"]) {
		//skip this line
		return [self parseLines:[self getNextLine] withList:currentList];
		
	} else if ([targetText hasPrefix:@"LaTeX Font"]
			   ||[targetText hasPrefix:@"(FONT)"]
			   ||[targetText hasPrefix:@"Package hyperref"]
			   ||[targetText hasPrefix:@"(hyperref)"]) {
			  // ||[targetText hasPrefix:@"Package:"]) {
		//just add this line into currentList
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];
		
	} else if ([targetText contain:@"Warning:"]){
		unsigned int theCurrentLineNumber = currentLineNumber;
		while (! [targetText hasSuffix:@"."]) {
			targetText = [targetText stringByAppendingString:[self getNextLine]];
		}
		NSMutableDictionary * dict = makeLogRecord(targetText, theCurrentLineNumber, currentRange);
		[currentList addObject:dict];
		return [self parseLines:[self getNextLine] withList:currentList];
	
	} else if ([targetText hasPrefix:@"Overfull"]) {
		//targetText = [self addCurrentLineAndNextLine:currentList];
		[self addCurrentLine:currentList];
		if (isReadFile) {
			while (! ([targetText hasSuffix:@"[]"]||[targetText hasSuffix:@"[] "])) {
				targetText = [self getNextLine];
			}
		}
		return [self parseLines:[self getNextLine] withList:currentList];

	} else if ([targetText hasPrefix:@"Underfull"]) {
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];

	} else if ([targetText hasPrefix:@"Runaway argument?"]) {
		targetText = [self addCurrentLineAndNextLine:currentList];
		while (! [targetText hasPrefix:@"!"]) {
			targetText = [self addCurrentLineAndNextLine:currentList];
		}
		return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];

	} else if ([targetText hasPrefix:@"l."]) {
		targetText = [self addCurrentLineAndNextLine:currentList];
		while ([targetText hasPrefix:@" "]) {
			targetText = [self addCurrentLineAndNextLine:currentList];
		}
		//return [self parseLines:[self addCurrentLineAndNextLine:currentList] withList:currentList];
		return [self parseLines:targetText withList:currentList];

	} else if ([targetText hasPrefix:@"!"]) {
		unsigned int theCurrentLineNumber = currentLineNumber;
		if ([targetText length] >= 79) {
			//add two lines into current list
			targetText = [targetText stringByAppendingString:[self getNextLine]];
		}
		NSMutableDictionary * dict = makeLogRecord(targetText, theCurrentLineNumber, currentRange);
		[currentList addObject:dict];
		return [self parseLines:[self getNextLine] withList:currentList];

	} else if ([targetText hasPrefix:@"<argument>"]) {
		targetText = [self addCurrentLineAndNextLine:currentList];
		if (([targetText length] >= 79)||([targetText hasSuffix:@"..."])) {
			targetText = [self addCurrentLineAndNextLine:currentList];
		}
		return [self parseLines:targetText withList:currentList];
	} else {
#if useLog
		NSLog(@"back to parseBody");
#endif
		return targetText;
	}
}

- (NSString *) parseBodyWith:(NSMutableArray *)currentList startText:(NSString *)targetText isWholeLine:(BOOL *)wholeLineFlag {
#if useLog
	NSLog(@"start ParseBody");
	NSLog(targetText);
#endif
	NSCharacterSet* chSet = [NSCharacterSet characterSetWithCharactersInString:@"()`"];
	//NSCharacterSet* chSet = [NSCharacterSet characterSetWithCharactersInString:@"()"];
	NSString *scannedText;
	NSRange subRange;
	NSScanner *scanner;
	int matchLength;
	
	while(targetText != nil) {
		
		if (wholeLineFlag) {
			targetText = [self parseLines:targetText withList:currentList];
			if (targetText == nil) break;
		}
		targetText = [targetText stringByTrimmingCharactersInSet:whitespaceCharSet];
		scanner = [NSScanner scannerWithString:targetText];
		BOOL scanResult = [scanner scanUpToCharactersFromSet:chSet intoString:&scannedText];
		
		if ([scanner isAtEnd]) {
			[self appendLogRecordWithString:scannedText intoList:currentList];
			targetText = [self getNextLine];
			*wholeLineFlag = YES;
			
		}else {
			if (scanResult) {
				matchLength = [scannedText length];
			}else{
				matchLength = 0;
			}
			subRange = NSMakeRange(matchLength,1);
			if ([targetText compare:@"(" options:nil range:subRange] == NSOrderedSame) {
				if (scanResult) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
				}
				NSMutableArray *newList = [NSMutableArray array];
				[currentList addObject:newList];

				subRange = NSMakeRange(matchLength+1,[targetText length] - matchLength-1);
				if (subRange.length == 0) {
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}else{
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
				targetText = [self parseBodyWith:newList startText:targetText isWholeLine:wholeLineFlag];
			}
			else if ([targetText compare:@")" options:nil range:subRange] == NSOrderedSame) {
				if (scanResult) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
				}
				subRange = NSMakeRange(matchLength+1,[targetText length] - matchLength-1);
				if (subRange.length == 0) {
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}else{
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
				return targetText;
			}
			else if ([targetText compare:@"`" options:nil range:subRange] == NSOrderedSame) {
				//this block for ignoring "(" and ")" in between "`" and "'"
				scanResult = [scanner scanUpToString:@"'" intoString:&scannedText];
				matchLength += ([scannedText length]+1);
				if (![scanner isAtEnd]) {
					scanResult = [scanner scanUpToCharactersFromSet:chSet intoString:&scannedText];
					if (scanResult) {
						matchLength += ([scannedText length]-1);
					}
				}
				
				if ([scanner isAtEnd]) {
					[self appendLogRecordWithString:scannedText intoList:currentList];
					targetText = [self getNextLine];
					*wholeLineFlag = YES;
				}
				else {
					subRange = NSMakeRange(matchLength, [targetText length]-matchLength);
					targetText = [targetText substringWithRange:subRange];
					*wholeLineFlag = NO;
				}
			}
		}
	}
	return targetText;
}

- (NSString *) skipHeader {
#if useLog
	NSLog(@"start skipHeader");
#endif
	NSString *theLine = [self getNextLine];
#if useLog
	NSLog(theLine);
#endif
	NSRange beginningOne = NSMakeRange(0,1);
	NSString * fistParenth = @"(";
	while (theLine != NULL) {
#if useLog
	NSLog(theLine);
#endif
		if([theLine compare:fistParenth options:nil range:beginningOne] == NSOrderedSame) {
			break;
		}
		theLine = [self getNextLine];
	}
	NSRange subRange = NSMakeRange(1,[theLine length]-1);
#if useLog
	NSLog(@"end skipHeader");
#endif	
	return [theLine substringWithRange:subRange];
}

#pragma mark starting method to parse log
- (NSMutableArray *) parseLog
{
#if useLog
	NSLog(@"start parseLog");
#endif
	NSString *targetText = [self skipHeader];
	NSMutableDictionary * dict = makeLogRecord(targetText, currentLineNumber, currentRange);
	NSMutableArray *logTree = [NSMutableArray arrayWithObject:dict];
	targetText = [self getNextLine];
	BOOL wholeLineFlag = YES;
#if useLog
	NSLog(@"before parseBodyWith");
#endif
	targetText = [self parseBodyWith:logTree startText:targetText isWholeLine:&wholeLineFlag];
	
	dict = makeLogRecord(logFilePath, 0, currentRange);
	NSMutableArray *loglogTree = [NSMutableArray arrayWithObject:dict];
	[loglogTree addObject:logTree];
#if useLog
	NSLog(@"before parseFooterWith");
#endif
	[self parseFooterWith:loglogTree startText:targetText];
#if useLog
	NSLog([loglogTree description]);
#endif
	/* log を parse した結果は loglogTerre に収められる。loglogTree から必要な情報を抜き出す。 */
	isDviOutput = NO;
	isLabelsChanged = NO;
	if (![logContents hasSuffix:@"\n"]) {
		[self setLogContents:logContents];
	}
	[self parseLogTreeFirstLevel:loglogTree];
#if useLog
	NSLog([errorRecordTree description]);
	NSLog(@"end of parseLog");
#endif
	[[LogWindowController sharedLogManager] addLogRecords:self] ;
	
	return errorRecordTree;
}

#pragma mark methos for LogWindowItem
-(BOOL) jumpToFile
{
	return NO;
}

-(BOOL) hasChild
{
	return [errorRecordTree count] > 0 ;	
}

-(id)child
{
	return errorRecordTree ;
}

-(id) comment
{
	return _jobName;
}

-(id) paragraph
{
	return nil;
}

- (id)jobRecord;
{
	return self;
}

#pragma mark accessor methods
- (void)setJobName:(NSString *)jobName
{
	NSString *timeStamp = [[NSDate date] descriptionWithCalendarFormat:@" :%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
	NSString *nameWithTimeStamp = [jobName stringByAppendingString:timeStamp];
	[_jobName release];
	_jobName = [nameWithTimeStamp retain];
}


- (NSString *)logContents
{
	return logContents;
}

- (void)setLogContents:(NSString *)logText
{
	[logText retain];
	[logContents release];
	logContents = logText;
}

- (void)setLogFilePath:(NSString *)path
{
	[path retain];
	[logFilePath release];
	logFilePath = path;
}

- (void)setBaseURLWithPath:(NSString *)path
{
	[_baseURL release];
	_baseURL = [[NSURL fileURLWithPath: path] retain];
}

- (NSMutableArray *)errorRecordTree
{
	return errorRecordTree;
}

-(BOOL) isDviOutput
{
	return self->isDviOutput;
}

-(BOOL) isNoError
{
	return self->isNoError;
}

@end
