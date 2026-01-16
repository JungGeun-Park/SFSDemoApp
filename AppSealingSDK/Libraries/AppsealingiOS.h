//
//  AppsealingiOS.h
//  AppsealingiOS
//
//  Created by puzznic on 23/01/2019.
//  Copyright © 2019 Inka. All rights reserved.
//

#ifndef AppsealingiOS_h
#define AppsealingiOS_h

// Code used in sample code for app hacking UI
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

extern void Appsealing(void);
#ifdef __cplusplus
extern "C" {
#endif
int ObjC_IsAbnormalEnvironmentDetected() __attribute__((deprecated("This method is deprecated. Use _IsAbnormalEnvironmentDetectedAsync instead.")));
int ObjC_IsSwizzlingDetected();
int ObjC_IsSwizzlingDetectedReturn();
int ObjC_GetAppSealingDeviceID( char* deviceIDBuff );
int ObjC_GetEncryptedCredential( char* buffer ) __attribute__((deprecated("This method is deprecated. Use _GetEncryptedCredentialAsync instead.")));
char* ObjC_DecryptString( char* string );
int SecureStorage_AES256_Encrypt( uint8_t* plaintext, size_t plaintext_len, const uint8_t* iv, uint8_t* ciphertext_out, size_t* ciphertext_len_out );
int SecureStorage_AES256_Decrypt( const uint8_t* ciphertext, size_t ciphertext_len, const uint8_t* iv, uint8_t* plaintext_out, size_t* plaintext_len_out );
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
- ( BOOL )_EncryptData:( NSData* )plain iv:( NSData* )iv cipherOut:( NSMutableData* )cipherOut outLen:( size_t* )outLen;
- ( BOOL )_DecryptData:( NSData* )cipher iv:( NSData* )iv plainOut:( NSMutableData* )plainOut outLen:( size_t* )outLen;
- ( NSString* )_EncryptString:( NSString* )plain iv:( NSData* )iv;
- ( NSString* )_DecryptString:( NSString* )cipher iv:( NSData* )iv;
@end

#if REACT_NATIVE_0_71
@interface AppSealingInterfaceBridge : NSObject <RCTBridgeModule>
@end
#endif

#endif /* AppsealingiOS_h */
