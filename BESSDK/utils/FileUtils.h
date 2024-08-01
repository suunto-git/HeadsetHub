//
//  FileUtils.h
//  BesAll
//
//  Created by 范羽 on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileUtils : NSObject

+ (NSString *)getDocumentPath;

+ (void)saveStringToDocumentWithName:(NSString *)name text:(NSString *)text;

+ (void)delegateFile:(NSString *)path;

+ (void)dealAirDropFile;

@end

NS_ASSUME_NONNULL_END
