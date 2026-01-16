#import "FileOperations.h"

/*
 * FileOperations.m
 * -----------------
 * This file contains intentionally messy Objective-C file I/O code
 * with a huge variety of comment styles for parsing tests.
 */

@implementation FileOperations

+ (BOOL)writeData:(NSData *)data withAPI:(NSString *)api toPath:(NSString *)path {
    // Entry point for write operations using different Foundation APIs

    if ([api isEqualToString:@"NSFileManager"]) {
        // Using NSFileManager
        return [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];

    } else if ([api isEqualToString:@"NSData"]) {
        // Using NSData
        return [data writeToFile:path options:NSDataWritingAtomic error:nil];

    } else if ([api isEqualToString:@"NSFileHandle"]) {
        // Using NSFileHandle
        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:path]) {
            [fm createFileAtPath:path contents:nil attributes:nil];
        }

        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!handle) return NO;

        [handle writeData:data];
        [handle closeFile];
        return YES;
    }

    return NO;
}

+ (NSData * _Nullable)readDataWithAPI:(NSString *)api fromPath:(NSString *)path {
    // Read operation using various Foundation APIs

    if ([api isEqualToString:@"NSFileManager"]) {
        return [[NSFileManager defaultManager] contentsAtPath:path];

    } else if ([api isEqualToString:@"NSData"]) {
        return [NSData dataWithContentsOfFile:path];

    } else if ([api isEqualToString:@"NSFileHandle"]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
        if (!handle) return nil;

        NSData *data = [handle readDataToEndOfFile];
        [handle closeFile];
        return data;
    }

    return nil;
}

+ (void)testObjCParsingMessySafe
{
    /*******************************************************
     * MASSIVE TEST METHOD
     *******************************************************/

    // ==== FILE MANAGER ====

    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* pathA = @"/tmp/a.txt";
    NSString* pathB = @"/tmp/b.txt";

    [fm createFileAtPath:pathA
                contents:[@"Hello, World!" dataUsingEncoding:NSUTF8StringEncoding]
              attributes:nil];

    BOOL existsFlag = [fm fileExistsAtPath:pathA isDirectory:nil];
    NSError* err = nil;

    NSDictionary* attrs = [fm attributesOfItemAtPath:pathA error:&err];
    NSArray* contents = [fm contentsOfDirectoryAtPath:@"/tmp" error:&err];

    [fm moveItemAtPath:pathA toPath:pathB error:&err];
    [fm copyItemAtPath:pathB toPath:@"/tmp/c.txt" error:&err];
    [fm removeItemAtPath:@"/tmp/c.txt" error:&err];

    // ==== FILE HANDLE ====

    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:pathB];
    NSData* dataRead = [fh readDataToEndOfFile];

    [fh seekToFileOffset:0];
    [fh writeData:[@" appended" dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];

    // ==== NSData ====

    NSData* d1 = [NSData dataWithContentsOfFile:pathB];
    NSData* d2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:pathB]];

    [d2 writeToFile:@"/tmp/out1.bin" atomically:YES];
    [d2 writeToURL:[NSURL fileURLWithPath:@"/tmp/out2.bin"] atomically:NO];

    // ==== NSData (OPTIONS+ERROR versions) ====

    NSError* e1 = nil;
    NSData* d3 = [[NSData alloc] initWithContentsOfFile:pathB
                                                options:NSDataReadingMappedIfSafe
                                                error:&e1];

    NSError* e2 = nil;
    NSData* d4 = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:pathB]
                                                options:NSDataReadingUncached
                                                error:&e2];

    NSLog(@"d3=%@, e1=%@", d3, e1);
    NSLog(@"d4=%@, e2=%@", d4, e2);

    // ==== NSString ====

    NSString* s1 = [NSString stringWithContentsOfFile:pathB encoding:NSUTF8StringEncoding error:nil];
    [s1 writeToFile:@"/tmp/sOut.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // ==== NSArray / NSDictionary ====

    NSArray* arr = [NSArray arrayWithContentsOfFile:@"/tmp/arr.plist"];
    [arr writeToFile:@"/tmp/arrOut.plist" atomically:YES];

    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:@"/tmp/dict.plist"];
    [dict writeToFile:@"/tmp/dictOut.plist" atomically:YES];

    // ==== STREAMS ====

    NSInputStream* inStream = [NSInputStream inputStreamWithFileAtPath:pathB];
    [inStream open];
    uint8_t buf[128];
    NSInteger rlen = [inStream read:buf maxLength:128];
    [inStream close];

    NSOutputStream* outStream = [NSOutputStream outputStreamToFileAtPath:@"/tmp/streamOut.txt" append:YES];
    [outStream open];
    uint8_t outbuf[5] = {1,2,3,4,5};
    [outStream write:outbuf maxLength:5];
    [outStream close];

    // ==== NSURL ====

    NSURL* urlFile = [NSURL fileURLWithPath:@"/tmp/url.txt"];
    NSString* urlPath = [urlFile path];

    NSLog(@"Test done: %@ %@", s1, urlPath);

    /*
        Multi-line comment block
        spanning several lines
        meant to confuse parsers
    */

    // ==== POSIX I/O ====

    int fd = open("/tmp/posix_test.txt", O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd >= 0) {
        const char *msg = "posix write\n";
        write(fd, msg, (size_t)strlen(msg));

        fsync(fd);
        lseek(fd, 0, SEEK_SET);

        char rbuf[32] = {0};
        read(fd, rbuf, sizeof(rbuf) - 1);

        int fd2 = dup(fd);
        if (fd2 >= 0) {
            const char *msg2 = "dup write\n";
            write(fd2, msg2, (size_t)strlen(msg2));
            fsync( fd2 );
            close(     fd2       );
        }

        close(fd);
    }

    // FILE* I/O

    FILE *fp = fopen("/tmp/posix_test_f.txt", "w+");
    if (fp) {
        const char *buf = "fwrite test\n";
        fwrite(buf, 1, strlen(buf), fp);
        fflush(fp);

        fseek(fp, 0, SEEK_SET);
        char fbuf[32] = {0};
        fread(fbuf, 1, sizeof(fbuf) - 1, fp);

        int ffd = fileno(fp);
        if (ffd >= 0) {
            ftruncate(ffd, 0);
            fsync(ffd);
        }

        fclose(fp);
    }

    unlink("/tmp/posix_test.txt");
    remove("/tmp/posix_test_f.txt");
}

@end
