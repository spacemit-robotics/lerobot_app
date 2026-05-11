cmake_minimum_required(VERSION 3.16)
project(lerobot_native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(STAGING_LIB_DIR "${REPO_ROOT}/output/staging/lib")

find_package(Components QUIET)

if(TARGET components::mlink_device)
    set(MLINK_DEVICE_TARGET components::mlink_device)
else()
    set(MLINK_INCLUDE_DIR
        ${REPO_ROOT}/components/agent_tools/mlink_device/include
    )
    set(MLINK_LIBRARY
        ${REPO_ROOT}/output/build/cmake/pkgs/components_agent_tools_mlink_device/libmlink_device.so
    )

    if(NOT EXISTS ${MLINK_INCLUDE_DIR}/mlink.h)
        message(FATAL_ERROR "mlink.h not found at ${MLINK_INCLUDE_DIR}")
    endif()

    if(NOT EXISTS ${MLINK_LIBRARY})
        message(FATAL_ERROR "libmlink_device not found at ${MLINK_LIBRARY}")
    endif()
endif()

add_library(lerobot_runner STATIC
    src/cpp/runner.cpp
)

target_include_directories(lerobot_runner PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

add_executable(lerobot_native
    src/cpp/main.cpp
)

target_link_libraries(lerobot_native PRIVATE lerobot_runner)

add_executable(lerobot_device
    src/cpp/lerobot_device.cpp
)

set_target_properties(lerobot_device PROPERTIES
    BUILD_RPATH ${STAGING_LIB_DIR}
    INSTALL_RPATH ${STAGING_LIB_DIR}
)

if(TARGET components::mlink_device)
    target_link_libraries(lerobot_device PRIVATE
        lerobot_runner
        ${MLINK_DEVICE_TARGET}
    )
else()
    target_include_directories(lerobot_device PRIVATE
        ${MLINK_INCLUDE_DIR}
    )

    target_link_libraries(lerobot_device PRIVATE
        lerobot_runner
        ${MLINK_LIBRARY}
    )
endif()

install(TARGETS lerobot_native lerobot_device lerobot_runner
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(DIRECTORY include/ DESTINATION include)
install(PROGRAMS
    scripts/setup_env.sh
    scripts/pick_cube_record.sh
    DESTINATION share/lerobot/scripts
)
