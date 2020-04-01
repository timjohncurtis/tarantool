set(lib_sources
    json.c
)

set_source_files_compile_flags(${lib_sources})
add_library(json STATIC ${lib_sources})
target_link_libraries(json misc)

set(TEST "test_json")
add_executable(${TEST} ${TEST}.c)
set_target_properties(${TEST}
        PROPERTIES
        COMPILE_FLAGS "-fsanitize=fuzzer -g -O1"
        LINK_FLAGS "-fsanitize=fuzzer")
target_link_libraries(${TEST} PRIVATE json misc)
