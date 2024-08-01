//
//  FileUtils.m
//  BesAll
//
//  Created by 范羽 on 2021/2/25.
//

#import "FileUtils.h"

@implementation FileUtils

+ (NSString *)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return documentDir;
}

+ (void)saveStringToDocumentWithName:(NSString *)name text:(NSString *)text {
    NSString *saveText = [NSString stringWithFormat:@"%@ %@", [self getTimestamp], text];
    NSString *filePath = [NSString stringWithFormat:@"%@/BESLOG/%@", [self getDocumentPath], [name stringByReplacingOccurrencesOfString:@"/" withString:@""]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *stringData = [[NSString stringWithFormat:@"\n%@", saveText] dataUsingEncoding:NSUTF8StringEncoding];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        [fileHandle seekToEndOfFile]; //将节点跳到文件的末尾
        [fileHandle writeData:stringData]; // 追加写入数据
        [fileHandle closeFile];
    } else {
        [fileManager createDirectoryAtPath:[NSString stringWithFormat:@"%@/BESLOG", [self getDocumentPath]] withIntermediateDirectories:NO attributes:nil error:nil];
        [fileManager createFileAtPath:filePath contents:stringData attributes:nil];
    }
}

+ (NSString *)getTimestamp {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Beijing"]];
    NSString *dateString = [formatter stringFromDate: date];
    return dateString;
}

+ (void)delegateFile:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
}

+ (void)dealAirDropFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *customerFilePath = [NSString stringWithFormat:@"%@/CustomerCMD", [self getDocumentPath]];
    NSError *customerError = nil;
    NSArray *customerFileList = [[NSArray alloc] init];
    NSMutableArray *mutCustomerFileList = [NSMutableArray array];
    customerFileList = [fileManager contentsOfDirectoryAtPath:customerFilePath error:&customerError];
    BOOL customerIsDirectory = NO;
    for (NSString *file in customerFileList) {
        if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", customerFilePath, file] isDirectory:&customerIsDirectory] && !customerIsDirectory) {
            [mutCustomerFileList addObject:file];
        }
    }

    NSError *error = nil;
    NSArray *docFileList = [[NSArray alloc] init];
    NSMutableArray *mutDocFileList = [NSMutableArray array];
    docFileList = [fileManager contentsOfDirectoryAtPath:[self getDocumentPath] error:&error];
    BOOL docIsDirectory = NO;
    for (NSString *file in docFileList) {
        if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", [self getDocumentPath], file] isDirectory:&docIsDirectory] && !docIsDirectory) {
            [mutDocFileList addObject:file];
        }
    }
    NSString *airDropFile = [NSString stringWithFormat:@"%@/Inbox", [self getDocumentPath]];
    NSArray *fileList = [[NSArray alloc] init];
    fileList = [fileManager contentsOfDirectoryAtPath:airDropFile error:&error];
    NSLog(@"------%@", fileList);
    BOOL isDirectory = NO;
    for (NSString *file in fileList) {
        if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", airDropFile, file] isDirectory:&isDirectory] && !isDirectory) {
            NSString *name = file;
            //是否重复
            if ([name containsString:@".txt"]) {
                if ([mutCustomerFileList containsObject:file]) {
                    int i = 0;
                    name = [NSString stringWithFormat:@"0-%@", file];
                    while ([mutCustomerFileList containsObject:name]) {
                        i ++;
                        name = [NSString stringWithFormat:@"%d-%@", i, file];
                    }
                }
                [fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", airDropFile, file] toPath:[NSString stringWithFormat:@"%@/%@", customerFilePath, name] error:nil];
                continue;
            }
            
            if ([mutDocFileList containsObject:file]) {
                int i = 0;
                name = [NSString stringWithFormat:@"0-%@", file];
                while ([mutDocFileList containsObject:name]) {
                    i ++;
                    name = [NSString stringWithFormat:@"%d-%@", i, file];
                }
            }
            [fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", airDropFile, file] toPath:[NSString stringWithFormat:@"%@/%@", [self getDocumentPath], name] error:nil];
        }
    }

}



@end
