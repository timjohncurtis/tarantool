set(lib_sources
    csv.c
)

set_source_files_compile_flags(${lib_sources})
add_library(csv STATIC ${lib_sources})

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(TEST "test_csv")
    add_executable(${TEST} ${TEST}.c)
    set_target_properties(${TEST}
            PROPERTIES
            COMPILE_FLAGS "-fsanitize=fuzzer -g -O1"
            LINK_FLAGS "-fsanitize=fuzzer")
    target_link_libraries(${TEST} PRIVATE csv)
endif (CMAKE_CXX_COMPILER_ID)
