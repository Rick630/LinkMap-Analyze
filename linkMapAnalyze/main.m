//
//  main.m
//  linkMapAnalyze
//
//  Created by Rick on 15/11/10.
//
//

#import <Foundation/Foundation.h>

@interface symbolModel : NSObject

@property (nonatomic, copy) NSString *file;
@property (nonatomic, assign) NSUInteger size;

@end
@implementation symbolModel

@end
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
//        NSString *ss = @"0x0000000c";
//        NSUInteger aa = strtoul([ss UTF8String], nil, 16);
//        
//        return 0;
        if(argc != 3)
        {
            NSLog(@"input as the format linkMapAnalyze <LinkMap-file-path> <result-file-path>");
            return -1;
        }
        
        NSString *srcPath = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
        NSString *destPath = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
        
        NSMutableDictionary <NSString *,symbolModel *>*sizeMap = [NSMutableDictionary new];
        
        NSString *content = [NSString stringWithContentsOfFile:srcPath encoding:NSASCIIStringEncoding error:nil];
        
        if(!content)
            return -1;
        
        NSArray *lines = [content componentsSeparatedByString:@"\n"];

        BOOL reachFiles = NO;
        BOOL reachSymbols = NO;
        BOOL reachSections = NO;
        
        for(NSString *line in lines)
        {
            if([line hasPrefix:@"#"])   //注释行
            {
                if([line hasPrefix:@"# Object files:"])
                    reachFiles = YES;
                else if ([line hasPrefix:@"# Sections:"])
                    reachSections = YES;
                else if ([line hasPrefix:@"# Symbols:"])
                    reachSymbols = YES;
            }
            else
            {
                if(reachFiles == YES && reachSections == NO && reachSymbols == NO)
                {
                    NSRange range = [line rangeOfString:@"]"];
                    if(range.location != NSNotFound)
                    {
                        symbolModel *symbol = [symbolModel new];
                        symbol.file = [line substringFromIndex:range.location+1];
                        NSString *key = [line substringToIndex:range.location+1];
                        sizeMap[key] = symbol;
                    }
                }
                else if (reachFiles == YES &&reachSections == YES && reachSymbols == NO)
                {
                }
                else if (reachFiles == YES && reachSections == YES && reachSymbols == YES)
                {
                    NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                    if(symbolsArray.count == 3)
                    {
                        //Address Size File Name
                        NSString *fileKeyAndName = symbolsArray[2];
                        NSUInteger size = strtoul([symbolsArray[1] UTF8String], nil, 16);
                        
                        NSRange range = [fileKeyAndName rangeOfString:@"]"];
                        if(range.location != NSNotFound)
                        {
                            symbolModel *symbol = sizeMap[[fileKeyAndName substringToIndex:range.location+1]];
                            if(symbol)
                            {
                                symbol.size = size;
                            }
                        }
                    }
                }
            }
            
        }
        
        NSArray <symbolModel *>*symbols = [sizeMap allValues];
        NSArray *sorted = [symbols sortedArrayUsingComparator:^NSComparisonResult(symbolModel *  _Nonnull obj1, symbolModel *  _Nonnull obj2) {
            if(obj1.size > obj2.size)
                return NSOrderedAscending;
            else if (obj1.size < obj2.size)
                return NSOrderedDescending;
            else
                return NSOrderedSame;
        }];
        
        NSMutableString *result = [@"各模块体积大小\n" mutableCopy];
        NSUInteger totalSize = 0;
        
        for(symbolModel *symbol in sorted)
        {
            [result appendFormat:@"%@\t%.2fM\n",[[symbol.file componentsSeparatedByString:@"/"] lastObject],(symbol.size/1024.0)];
            totalSize += symbol.size;
        }
        
        [result appendFormat:@"总体积: %.2fM\n",(totalSize/1024.0)];
        
        [result writeToFile:destPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return 0;
}
