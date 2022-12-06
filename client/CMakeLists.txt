cmake_minimum_required(VERSION 3.23.0 FATAL_ERROR)

set(PROJECT AmneziaVPN)
project(${PROJECT})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS 
    Widgets Core Gui Network Xml 
    RemoteObjects Quick Svg QuickControls2 
    Core5Compat
)
qt_standard_project_setup()

# silent builds on CI env
set(IS_CI ${CI})
if(IS_CI)
  message("Detected CI env")
#   CONFIG += silent ccache
  find_program(CCACHE "ccache")
  if(CCACHE)
      set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE}")
  endif()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/3rd/QtSsh/src/ssh/qssh.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/3rd/QtSsh/src/botan/botan.cmake)
if(NOT IOS AND NOT ANDROID)
   include(${CMAKE_CURRENT_LIST_DIR}/3rd/SingleApplication/singleapplication.cmake)
endif()

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/3rd/SortFilterProxyModel)
set(LIBS ${LIBS} SortFilterProxyModel)

include(${CMAKE_CURRENT_LIST_DIR}/3rd/qrcodegen/qrcodegen.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/3rd/QSimpleCrypto/QSimpleCrypto.cmake)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/3rd/zlib)
set(ZLIB_LIBRARY ${CMAKE_CURRENT_BINARY_DIR}/3rd/zlib)
set(ZLIB_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/3rd/zlib)
set(WITH_SERVER OFF)
set(WITH_GSSAPI OFF)
set(WITH_EXAMPLES OFF)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/include)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/3rd/libssh)

set(BUILD_WITH_QT6 ON)
set(BUILD_SHARED_LIBS OFF)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/3rd/qtkeychain)
set(LIBS ${LIBS} qt6keychain)

include_directories(
    ${CMAKE_CURRENT_LIST_DIR}/3rd/QSimpleCrypto/include
    ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/include
    ${CMAKE_CURRENT_LIST_DIR}/../ipc
    ${CMAKE_CURRENT_LIST_DIR}/3rd/qtkeychain
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/3rd/qtkeychain
)

set(HEADERS ${HEADERS}
    ${CMAKE_CURRENT_LIST_DIR}/../ipc/ipc.h
    ${CMAKE_CURRENT_LIST_DIR}/amnezia_application.h
    ${CMAKE_CURRENT_LIST_DIR}/containers/containers_defs.h
    ${CMAKE_CURRENT_LIST_DIR}/core/defs.h
    ${CMAKE_CURRENT_LIST_DIR}/core/errorstrings.h
    ${CMAKE_CURRENT_LIST_DIR}/core/scripts_registry.h
    ${CMAKE_CURRENT_LIST_DIR}/core/server_defs.h
    ${CMAKE_CURRENT_LIST_DIR}/core/servercontroller.h
    ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/MobileUtils.h
    ${CMAKE_CURRENT_LIST_DIR}/platforms/linux/leakdetector.h
    ${CMAKE_CURRENT_LIST_DIR}/protocols/protocols_defs.h
    ${CMAKE_CURRENT_LIST_DIR}/ui/notificationhandler.h
    ${CMAKE_CURRENT_LIST_DIR}/ui/pages.h
    ${CMAKE_CURRENT_LIST_DIR}/ui/property_helper.h
    ${CMAKE_CURRENT_LIST_DIR}/ui/uilogic.h
    ${CMAKE_CURRENT_LIST_DIR}/ui/qautostart.h
    ${CMAKE_CURRENT_LIST_DIR}/protocols/vpnprotocol.h
    ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QRCodeReaderBase.h
)

set(SOURCES ${SOURCES}
    ${CMAKE_CURRENT_LIST_DIR}/amnezia_application.cpp
    ${CMAKE_CURRENT_LIST_DIR}/containers/containers_defs.cpp
    ${CMAKE_CURRENT_LIST_DIR}/core/errorstrings.cpp
    ${CMAKE_CURRENT_LIST_DIR}/core/scripts_registry.cpp
    ${CMAKE_CURRENT_LIST_DIR}/core/server_defs.cpp
    ${CMAKE_CURRENT_LIST_DIR}/core/servercontroller.cpp
    ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/MobileUtils.cpp
    ${CMAKE_CURRENT_LIST_DIR}/platforms/linux/leakdetector.cpp
    ${CMAKE_CURRENT_LIST_DIR}/protocols/protocols_defs.cpp
    ${CMAKE_CURRENT_LIST_DIR}/ui/notificationhandler.cpp
    ${CMAKE_CURRENT_LIST_DIR}/ui/uilogic.cpp
    ${CMAKE_CURRENT_LIST_DIR}/ui/qautostart.cpp
    ${CMAKE_CURRENT_LIST_DIR}/protocols/vpnprotocol.cpp
    ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QRCodeReaderBase.cpp
)

file(GLOB COMMON_FILES_H CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/*.h)
file(GLOB COMMON_FILES_CPP CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/*.cpp)

file(GLOB_RECURSE PAGE_LOGIC_H CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/ui/pages_logic/*.h)
file(GLOB_RECURSE PAGE_LOGIC_CPP CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/ui/pages_logic/*.cpp)

file(GLOB CONFIGURATORS_H CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/configurators/*.h)
file(GLOB CONFIGURATORS_CPP CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/configurators/*.cpp)

file(GLOB UI_MODELS_H CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/ui/models/*.h)
file(GLOB UI_MODELS_CPP CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/ui/models/*.cpp)

set(HEADERS ${HEADERS}
    ${COMMON_FILES_H}
    ${PAGE_LOGIC_H}
    ${CONFIGURATORS_H}
    ${UI_MODELS_H}
)
set(SOURCES ${SOURCES}
    ${COMMON_FILES_CPP}
    ${PAGE_LOGIC_CPP}
    ${CONFIGURATORS_CPP}
    ${UI_MODELS_CPP}
)

qt6_add_resources(QRC ${QRC} ${CMAKE_CURRENT_LIST_DIR}/resources.qrc)

if(WIN32)
    add_compile_definitions(MVPN_WINDOWS)

    set(HEADERS ${HEADERS}
        ${CMAKE_CURRENT_LIST_DIR}/protocols/ikev2_vpn_protocol_windows.h
        ${CMAKE_CURRENT_LIST_DIR}/ui/framelesswindow.h
    )

    set(SOURCES ${SOURCES}
        ${CMAKE_CURRENT_LIST_DIR}/protocols/ikev2_vpn_protocol_windows.cpp
        ${CMAKE_CURRENT_LIST_DIR}/ui/framelesswindow.cpp
    )

    set(RESOURCES ${RESOURCES}
        ${CMAKE_CURRENT_LIST_DIR}/platform_win/vpnclient.rc
    )

    set(LIBS ${LIBS}
        user32
        rasapi32
        shlwapi
        iphlpapi
        ws2_32
        gdi32
    )

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")

    if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
        message("Windows x86_64 build")
        link_directories(${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/windows/x86_64)
        set(LIBS ${LIBS}
            libssl
            libcrypto
        )
    else()
        message("Windows x86 build")
        link_directories(${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/windows/x86)
        set(LIBS ${LIBS}
            libssl
            libcrypto
        )
    endif()
endif()

if(APPLE)

    if(NOT BUILD_OSX_APP_IDENTIFIER)
           set(BUILD_OSX_APP_IDENTIFIER org.amnezia.AmneziaVPN CACHE STRING "OSX Application identifier")
       endif()
       if(NOT BUILD_IOS_APP_IDENTIFIER)
           set(BUILD_IOS_APP_IDENTIFIER org.amnezia.AmneziaVPN CACHE STRING "iOS Application identifier")
       endif()
       if(NOT BUILD_IOS_GROUP_IDENTIFIER)
           set(BUILD_IOS_GROUP_IDENTIFIER group.org.amnezia.AmneziaVPN.Guardian CACHE STRING "iOS Group identifier")
       endif()
       if(NOT BUILD_VPN_DEVELOPMENT_TEAM)
           set(BUILD_VPN_DEVELOPMENT_TEAM X7UJ388FXK CACHE STRING "Amnezia VPN Development Team")
       endif()

    if(IOS)
        message("ios in mac")
      #do nothing, IOS is added in below
     else() #mac
         set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE INTERNAL "" FORCE)

         message("MAC build")
         set(HEADERS ${HEADERS} ${CMAKE_CURRENT_LIST_DIR}/ui/macos_util.h)
         set(SOURCES ${SOURCES} ${CMAKE_CURRENT_LIST_DIR}/ui/macos_util.mm)

    #     set(CMAKE_OSX_DEPLOYMENT_TARGET 10.14)
         add_compile_definitions(MVPN_MACOS)
    # ICON   = $$PWD/images/app.icns


    message(STATUS "test ${PROJECT_SOURCE_DIR}")

    find_library(LIB_LIBCRYPTO NAMES "libcrypto.a"
      PATHS ${PROJECT_SOURCE_DIR}/3rd/OpenSSL/lib/macos/x86_64/ NO_DEFAULT_PATH)

  find_library(LIB_SSL NAMES "libssl.a"
    PATHS ${PROJECT_SOURCE_DIR}/3rd/OpenSSL/lib/macos/x86_64/ NO_DEFAULT_PATH)


    find_library(FW_COCOA Cocoa)
    find_library(FW_APPLICATIONSERVICES ApplicationServices)
    find_library(FW_CORESERVICES CoreServices)
    find_library(FW_FOUNDATION Foundation)
    find_library(FW_APPKIT AppKit)
    find_library(FW_SECURITY Security)

    set(LIBS ${LIBS} FW_COCOA FW_APPLICATIONSERVICES FW_FOUNDATION FW_APPKIT FW_SECURITY FW_CORESERVICES
                        LIB_LIBCRYPTO LIB_SSL)


    endif()

endif()


if(LINUX AND NOT ANDROID)
    add_compile_definitions(MVPN_LINUX)

    set(OPENSSL_USE_STATIC_LIBS TRUE)
    find_package(OpenSSL REQUIRED)
    set(LIBS ${LIBS}
        OpenSSL::Crypto
        OpenSSL::SSL
    )
    link_directories(${CMAKE_CURRENT_LIST_DIR}/platforms/linux)
endif()

if(WIN32 OR (APPLE AND NOT IOS) OR (LINUX AND NOT ANDROID))
    message("Client desktop build")
    add_compile_definitions(AMNEZIA_DESKTOP)
    
    set(HEADERS ${HEADERS}
        ${CMAKE_CURRENT_LIST_DIR}/core/ipcclient.h
        ${CMAKE_CURRENT_LIST_DIR}/core/privileged_process.h
        ${CMAKE_CURRENT_LIST_DIR}/ui/systemtray_notificationhandler.h
        ${CMAKE_CURRENT_LIST_DIR}/protocols/openvpnprotocol.h
        ${CMAKE_CURRENT_LIST_DIR}/protocols/openvpnovercloakprotocol.h
        ${CMAKE_CURRENT_LIST_DIR}/protocols/shadowsocksvpnprotocol.h
        ${CMAKE_CURRENT_LIST_DIR}/protocols/wireguardprotocol.h
    )

    set(SOURCES ${SOURCES}
        ${CMAKE_CURRENT_LIST_DIR}/core/ipcclient.cpp
        ${CMAKE_CURRENT_LIST_DIR}/core/privileged_process.cpp
        ${CMAKE_CURRENT_LIST_DIR}/ui/systemtray_notificationhandler.cpp
        ${CMAKE_CURRENT_LIST_DIR}/protocols/openvpnprotocol.cpp
        ${CMAKE_CURRENT_LIST_DIR}/protocols/openvpnovercloakprotocol.cpp
        ${CMAKE_CURRENT_LIST_DIR}/protocols/shadowsocksvpnprotocol.cpp
        ${CMAKE_CURRENT_LIST_DIR}/protocols/wireguardprotocol.cpp
    )
endif()

if(ANDROID)
    message("Client android ${CMAKE_ANDROID_ARCH_ABI} build")
    # We need to include qtprivate api's
    # As QAndroidBinder is not yet implemented with a public api
    set(LIBS ${LIBS} Qt6::CorePrivate)
    set(ANDROID_ABIS ANDROID_TARGET_ARCH)

    add_compile_definitions(MVPN_ANDROID)

    link_directories(${CMAKE_CURRENT_LIST_DIR}/platforms/android)

    set(HEADERS ${HEADERS}
        ${CMAKE_CURRENT_LIST_DIR}/platforms/android/android_controller.h
        ${CMAKE_CURRENT_LIST_DIR}/platforms/android/android_notificationhandler.h
        ${CMAKE_CURRENT_LIST_DIR}/protocols/android_vpnprotocol.h
    )

    set(SOURCES ${SOURCES}
        ${CMAKE_CURRENT_LIST_DIR}/platforms/android/android_controller.cp
        ${CMAKE_CURRENT_LIST_DIR}/platforms/android/android_notificationhandler.cpp
        ${CMAKE_CURRENT_LIST_DIR}/protocols/android_vpnprotocol.cpp
    )
endif()



if(IOS)
    message("Client iOS build")


    # CONFIG += static
    # CONFIG += file_copies


    find_library(FW_AUTHENTICATIONSERVICES AuthenticationServices)
    find_library(FW_UIKIT UIKit)
    find_library(FW_FOUNDATION Foundation)
    find_library(FW_STOREKIT StoreKit)
    find_library(FW_USERNOTIFICATIONS UserNotifications)

    set(LIBS ${LIBS} ${FW_AUTHENTICATIONSERVICES} ${FW_UIKIT} ${FW_FOUNDATION} ${FW_STOREKIT} ${FW_USERNOTIFICATIONS})

    add_compile_definitions(MVPN_IOS)

    message("shahzain ${CMAKE_CURRENT_LIST_DIR}")

    set(HEADERS ${HEADERS}
        ${CMAKE_CURRENT_LIST_DIR}/protocols/ios_vpnprotocol.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/iosnotificationhandler.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/json.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/bigint.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/bigintipv6addr.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/ipaddress.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/ipaddressrange.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QtAppDelegate.h 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QtAppDelegate-C-Interface.h
    )

    # i think in cmake it is not necessary? yes in iOS we are using native
    # SOURCES -= 
    #   platforms/ios/QRCodeReaderBase.cpp 
    #   platforms/ios/MobileUtils.cpp

    set(SOURCES ${SOURCES}
        ${CMAKE_CURRENT_LIST_DIR}/protocols/ios_vpnprotocol.mm 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/iosnotificationhandler.mm 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/json.cpp 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/iosglue.mm 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/ipaddress.cpp 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/ipaddressrange.cpp 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QRCodeReaderBase.mm 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/QtAppDelegate.mm 
        ${CMAKE_CURRENT_LIST_DIR}/platforms/ios/MobileUtils.mm
    )







    # Q_ENABLE_BITCODE.value = NO
    # Q_ENABLE_BITCODE.name = ENABLE_BITCODE
    # QMAKE_MAC_XCODE_SETTINGS += Q_ENABLE_BITCODE
endif()

if(CMAKE_OSX_SYSROOT STREQUAL "iphoneos")
    message("Building for iPhone OS")
    set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)




   # find_library(LIB_LIBCRYPTO NAMES "libcrypto.a"
    #                               PATHS ${PROJECT_SOURCE_DIR}/3rd/OpenSSL/lib/ios/iphone/ NO_DEFAULT_PATH)

    #find_library(LIB_SSL NAMES "libssl.a"
     #                            PATHS ${PROJECT_SOURCE_DIR}/3rd/OpenSSL/lib/ios/iphone/ NO_DEFAULT_PATH)



    #set(LIBS ${LIBS} LIB_LIBCRYPTO LIB_SSL)

      #    target_link_libraries(${PROJECT} PRIVATE ${LIB_LIBCRYPTO})

       #   target_link_libraries(${PROJECT} PRIVATE ${LIB_SSL})


endif()


#if(IPHONEOS)
    # message("Building for iPhone OS")
    # QMAKE_TARGET_BUNDLE_PREFIX = org.amnezia
    # QMAKE_BUNDLE = AmneziaVPN
    # QMAKE_IOS_DEPLOYMENT_TARGET = 12.0
    # QMAKE_APPLE_TARGETED_DEVICE_FAMILY = 1
    # QMAKE_DEVELOPMENT_TEAM = X7UJ388FXK
    # QMAKE_PROVISIONING_PROFILE = f2fefb59-14aa-4aa9-ac14-1d5531b06dcc          not added yet
    # QMAKE_XCODE_CODE_SIGN_IDENTITY = "Apple Distribution"
    # QMAKE_INFO_PLIST = $$PWD/ios/app/Info.plist

    # XCODEBUILD_FLAGS += -allowProvisioningUpdates                              not added yet

    # DEFINES += iphoneos

    # contains(QT_ARCH, arm64) {
    # message("Building for iOS/ARM v8 64-bit architecture")
    # ARCH_TAG = "ios_armv8_64"

    # LIBS += $$PWD/3rd/OpenSSL/lib/ios/iphone/libcrypto.a
    # LIBS += $$PWD/3rd/OpenSSL/lib/ios/iphone/libssl.a
    # } else {
    # message("Building for iOS/ARM v7 (32-bit) architecture")
    # ARCH_TAG = "ios_armv7"
    # }
#endif()


qt_add_executable(${PROJECT} ${SOURCES} ${HEADERS} ${RESOURCES} ${QRC})
qt_add_translations(${PROJECT} TS_FILES
    ${CMAKE_CURRENT_LIST_DIR}/translations/amneziavpn_ru.ts)

# NETWORKEXTENSION=1

if(IOS)
    enable_language(OBJC)
    enable_language(OBJCXX)
    enable_language(Swift)
    include(src/cmake/osxtools.cmake)

    set_target_properties(${PROJECT} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")


    set_target_properties(${PROJECT} PROPERTIES XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.amnezia.${PROJECT}"
                                     XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
                                     XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "X7UJ388FXK"
                                     XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development")
   set(LIBS ${LIBS}
        ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/ios/iphone/libcrypto.a
        ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/ios/iphone/libssl.a)

    target_include_directories(${PROJECT} PRIVATE ${Qt6Gui_PRIVATE_INCLUDE_DIRS})

    set_target_properties(${PROJECT} PROPERTIES
        XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
        XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES "YES"
        XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${CMAKE_SOURCE_DIR}/platforms/ios/WireGuard-Bridging-Header.h"
        XCODE_ATTRIBUTE_SWIFT_PRECOMPILE_BRIDGING_HEADER "NO"
        XCODE_ATTRIBUTE_SWIFT_OPTIMIZATION_LEVEL "-Onone"
        XCODE_ATTRIBUTE_SWIFT_OBJC_INTERFACE_HEADER_NAME "AmneziaVPN-Swift.h"
    )

set_target_properties(${PROJECT} PROPERTIES
    OUTPUT_NAME "AmneziaVPN"
    MACOSX_BUNDLE ON
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/ios/app/Info.plist.in
    MACOSX_BUNDLE_BUNDLE_NAME "AmneziaVPN"
    MACOSX_BUNDLE_BUNDLE_VERSION "${BUILD_ID}"
    MACOSX_BUNDLE_COPYRIGHT "MPL-2.0"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${BUILD_IOS_APP_IDENTIFIER}"
    MACOSX_BUNDLE_INFO_STRING "AmneziaVPN"
    MACOSX_BUNDLE_LONG_VERSION_STRING "${CMAKE_PROJECT_VERSION}-${BUILD_ID}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${BUILD_IOS_APP_IDENTIFIER}"
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/ios/app/main.entitlements"
    XCODE_ATTRIBUTE_MARKETING_VERSION "${CMAKE_PROJECT_VERSION}"
    XCODE_GENERATE_SCHEME TRUE
)
target_include_directories(${PROJECT} PRIVATE ${CMAKE_SOURCE_DIR})

    target_compile_options(${PROJECT} PRIVATE
        -DGROUP_ID=\"${BUILD_IOS_GROUP_IDENTIFIER}\"
        -DVPN_NE_BUNDLEID=\"${BUILD_IOS_APP_IDENTIFIER}.network-extension\"
       )


   target_sources(${PROJECT} PRIVATE
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/Shared/Keychain.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/IPAddressRange.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/InterfaceConfiguration.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/Shared/Model/NETunnelProviderProtocol+Extension.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/TunnelConfiguration.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/Shared/Model/TunnelConfiguration+WgQuickConfig.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/Endpoint.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/Shared/Model/String+ArrayConversion.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/PeerConfiguration.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/DNSServer.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardApp/LocalizationHelper.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/Shared/FileManager+Extension.swift
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKitC/x25519.c
       ${CMAKE_SOURCE_DIR}/3rd/wireguard-apple/Sources/WireGuardKit/PrivateKey.swift
)

       target_sources(${PROJECT} PRIVATE
           platforms/ios/iosvpnprotocol.swift
           platforms/ios/ioslogger.swift
       )
   add_subdirectory(ios/networkextension)
   add_dependencies(${PROJECT} networkextension)
   set_target_properties(${PROJECT} PROPERTIES XCODE_EMBED_APP_EXTENSIONS networkextension)

endif()


if(ANDROID)
    add_custom_command(
        TARGET ${PROJECT} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_LIST_DIR}/android/AndroidManifest.xml 
            ${CMAKE_CURRENT_LIST_DIR}/android/build.gradle 
            ${CMAKE_CURRENT_LIST_DIR}/android/gradle/wrapper/gradle-wrapper.jar 
            ${CMAKE_CURRENT_LIST_DIR}/android/gradle/wrapper/gradle-wrapper.properties 
            ${CMAKE_CURRENT_LIST_DIR}/android/gradlew 
            ${CMAKE_CURRENT_LIST_DIR}/android/gradlew.bat 
            ${CMAKE_CURRENT_LIST_DIR}/android/gradle.properties 
            ${CMAKE_CURRENT_LIST_DIR}/android/res/values/libs.xml 
            ${CMAKE_CURRENT_LIST_DIR}/android/src/org/amnezia/vpn/OpenVPNThreadv3.kt 
            ${CMAKE_CURRENT_LIST_DIR}/android/src/org/amnezia/vpn/VpnService.kt 
            ${CMAKE_CURRENT_LIST_DIR}/android/src/org/amnezia/vpn/VpnServiceBinder.kt 
            ${CMAKE_CURRENT_LIST_DIR}/android/src/org/amnezia/vpn/qt/VPNPermissionHelper.kt
            ${CMAKE_CURRENT_BINARY_DIR}
    )

    set_property(TARGET ${PROJECT} 
        QT_ANDROID_PACKAGE_SOURCE_DIR 
        ${CMAKE_CURRENT_LIST_DIR}/android
    )

    foreach(abi IN ANDROID_ABIS)
        if(ANDROID_TARGET_ARCH EQUAL ${abi})
            set(LIBS ${LIBS} 
                ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/android/${abi}/libcrypto.a
                ${CMAKE_CURRENT_LIST_DIR}/3rd/OpenSSL/lib/android/${abi}/libssl.a
            )
        endif()

        set_property(TARGET ${PROJECT} PROPERTY QT_ANDROID_EXTRA_LIBS
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/wireguard/${abi}/libwg.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/wireguard/${abi}/libwg-go.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/wireguard/${abi}/libwg-quick.so
    
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/openvpn/${abi}/libjbcrypto.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/openvpn/${abi}/libopenvpn.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/openvpn/${abi}/libopvpnutil.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/openvpn/${abi}/libovpn3.so
            ${CMAKE_CURRENT_LIST_DIR}/android/lib/openvpn/${abi}/libovpnexec.so
        )
    endforeach()
endif()

target_link_libraries(${PROJECT} PRIVATE 
    Qt6::Widgets Qt6::Core Qt6::Gui
    Qt6::Network Qt6::Xml Qt6::RemoteObjects
    Qt6::Quick Qt6::Svg Qt6::QuickControls2
    Qt6::Core5Compat ${LIBS}
)

if(WIN32 OR (APPLE AND NOT IOS) OR (LINUX AND NOT ANDROID))
    qt_add_repc_replicas(${PROJECT} ${CMAKE_CURRENT_LIST_DIR}/../ipc/ipc_interface.rep)
    qt_add_repc_replicas(${PROJECT} ${CMAKE_CURRENT_LIST_DIR}/../ipc/ipc_process_interface.rep)
endif()

# deploy artifacts required to run the application to the debug build folder
if(WIN32)
    if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
        set(DEPLOY_ARTIFACT_PATH "windows/x64")
    else()
        set(DEPLOY_ARTIFACT_PATH "windows/x32")
    endif()
elseif(LINUX)
    set(DEPLOY_ARTIFACT_PATH "linux/client")
elseif(APPLE AND NOT IOS)
    set(DEPLOY_ARTIFACT_PATH "macos")
endif()

add_custom_command(
    TARGET ${PROJECT} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E $<IF:$<CONFIG:Debug>,copy_directory,true>
    ${CMAKE_SOURCE_DIR}/deploy/data/${DEPLOY_ARTIFACT_PATH}
    $<TARGET_FILE_DIR:${PROJECT}>
    COMMAND_EXPAND_LISTS
)