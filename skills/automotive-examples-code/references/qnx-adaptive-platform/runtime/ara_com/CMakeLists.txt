# ara::com - Communication Management for QNX
# AUTOSAR Adaptive Platform R23-11

cmake_minimum_required(VERSION 3.22)
project(ara_com VERSION 1.0.0 LANGUAGES CXX)

# Require C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ara::com library sources
set(ARA_COM_SOURCES
    src/skeleton.cpp
    src/proxy.cpp
    src/service_registry.cpp
    src/qnx_ipc_transport.cpp
    src/someip_transport.cpp
)

set(ARA_COM_HEADERS
    include/ara/com/types.h
    include/ara/com/skeleton.h
    include/ara/com/proxy.h
    include/ara/com/com_error_domain.h
    include/ara/com/instance_identifier.h
)

# Create ara::com shared library
add_library(ara_com SHARED ${ARA_COM_SOURCES})

# Include directories
target_include_directories(ara_com
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Link dependencies
target_link_libraries(ara_com
    PUBLIC
        ara_core       # ara::core::Result, ara::core::ErrorDomain
    PRIVATE
        ara_log        # ara::log::Logger
)

# Find vsomeip (optional, for SOME/IP transport)
find_package(vsomeip3 QUIET)
if(vsomeip3_FOUND)
    target_link_libraries(ara_com PRIVATE vsomeip3)
    target_compile_definitions(ara_com PRIVATE ENABLE_SOMEIP=1)
    message(STATUS "ara::com: vsomeip found, SOME/IP transport enabled")
else()
    message(STATUS "ara::com: vsomeip not found, using QNX IPC only")
endif()

# QNX-specific options
if(CMAKE_SYSTEM_NAME STREQUAL "QNX")
    # Enable QNX IPC optimizations
    target_compile_definitions(ara_com PRIVATE
        USE_QNX_CHANNELS=1
        USE_QNX_MESSAGE_PASSING=1
    )

    # Link against QNX-specific libraries (socket is in libc on QNX)
    # No additional libraries needed

    message(STATUS "ara::com: QNX-specific optimizations enabled")
endif()

# Compiler warnings
target_compile_options(ara_com PRIVATE
    -Wall
    -Wextra
    -Wpedantic
    -Wno-unused-parameter
)

# Enable position-independent code for shared library
set_target_properties(ara_com PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
)

# Installation
install(TARGETS ara_com
    EXPORT ara_com-targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/ara
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

install(EXPORT ara_com-targets
    FILE ara_com-config.cmake
    NAMESPACE ara::
    DESTINATION lib/cmake/ara_com
)

# Testing (optional)
option(BUILD_TESTS "Build unit tests" OFF)
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Benchmarks (optional)
option(BUILD_BENCHMARKS "Build performance benchmarks" OFF)
if(BUILD_BENCHMARKS)
    add_subdirectory(benchmarks)
endif()

# Print configuration summary
message(STATUS "========================================")
message(STATUS "ara::com Configuration")
message(STATUS "========================================")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "CXX Standard: C++${CMAKE_CXX_STANDARD}")
message(STATUS "System: ${CMAKE_SYSTEM_NAME}")
message(STATUS "vsomeip: ${vsomeip3_FOUND}")
message(STATUS "Build Tests: ${BUILD_TESTS}")
message(STATUS "Build Benchmarks: ${BUILD_BENCHMARKS}")
message(STATUS "========================================")
