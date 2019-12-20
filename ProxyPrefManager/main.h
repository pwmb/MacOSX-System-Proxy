//
//  main.h
//  ProxyPrefManager
//
//  Created by Soumesh on 2019/12/19.
//  Copyright © 2019 Soumesh. All rights reserved.
//
#ifndef main_h
#define main_h

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
bool SetUnsetSystemProxy(AuthorizationRef authRef, NSSet* interfaceList, NSString* address, NSNumber* port, bool usePAC, bool isClear);
#endif /* main_h */
