#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileOperations : NSObject

+ (BOOL)writeData:(NSData *)data withAPI:(NSString *)api toPath:(NSString *)path;
+ (NSData * _Nullable)readDataWithAPI:(NSString *)api fromPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
