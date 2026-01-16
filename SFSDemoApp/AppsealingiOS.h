//
//  AppsealingiOS.h
//  AppsealingiOS
//
//  Created by puzznic on 23/01/2019.
//  Copyright © 2019 Inka. All rights reserved.
//

#ifndef AppsealingiOS_h
#define AppsealingiOS_h

// 앱 해킹 UI용 샘플코드에 사용되는 코드
extern const int kAppSealingErrorNone;
extern const int kAppSealingErrorJailbreakDetected;
extern const int kAppSealingErrorDRMDecrypted;
extern const int kAppSealingErrorDebugAttached;
extern const int kAppSealingErrorHashInfoCorrupted;
extern const int kAppSealingErrorCodesignCorrupted;
extern const int kAppSealingErrorHashModified;
extern const int kAppSealingErrorExecutableCorrupted;
extern const int kAppSealingErrorCertificateChanged;
extern const int kAppSealingErrorBlacklistCorrupted;
extern const int kAppSealingErrorCheatToolDetected;

#import <Foundation/Foundation.h>

#if REACT_NATIVE_0_71
#if __has_include(<React/RCTAssert.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif
#endif

#define CFSTR(cStr)  __CFStringMakeConstantString( cStr )

extern void Appsealing(void);
#ifdef __cplusplus
extern "C" {
#endif
extern int ObjC_IsAbnormalEnvironmentDetected() __attribute__((deprecated("This method is deprecated. Use _IsAbnormalEnvironmentDetectedAsync instead.")));
extern int ObjC_IsSwizzlingDetected();
extern int ObjC_IsSwizzlingDetectedReturn();
extern int ObjC_GetAppSealingDeviceID( char* deviceIDBuff );
extern int ObjC_GetEncryptedCredential( char* buffer ) __attribute__((deprecated("This method is deprecated. Use _GetEncryptedCredentialAsync instead.")));
extern char* ObjC_DecryptString( char* string );
#ifdef __cplusplus
}
#endif

@interface AppSealingInterface : NSObject
- ( int )_IsAbnormalEnvironmentDetected __attribute__((deprecated("This method is deprecated. Use _IsAbnormalEnvironmentDetectedAsync instead.")));
- ( void )_IsAbnormalEnvironmentDetectedAsync:(void (^)(int result))completion;
+ ( void )_NotifySwizzlingDetected:(void (^)(NSString*))handler;
- ( const char* )_GetAppSealingDeviceID;
- ( const char* )_GetEncryptedCredential __attribute__((deprecated("This method is deprecated. Use _GetEncryptedCredentialAsync instead.")));
- ( void )_GetEncryptedCredentialAsync:(void (^)(const char *result))completion;
+ ( NSString* )_DSS: ( NSString* )string;  // Decrypt String (for Objective-C / Swift string)
+ ( NSString* )_DSC: ( char* )string;      // Decrypt String (for C string)
@end

#if REACT_NATIVE_0_71
@interface AppSealingInterfaceBridge : NSObject <RCTBridgeModule>
@end
#endif

#endif /* AppsealingiOS_h */
