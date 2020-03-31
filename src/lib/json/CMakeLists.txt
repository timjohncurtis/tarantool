set(lib_sources
    json.c
)

set_source_files_compile_flags(${lib_sources})
add_library(json STATIC ${lib_sources})
target_link_libraries(json misc)

set(TEST "test_json")
add_executable(${TEST} ${TEST}.c)
target_compile_options(${TEST}
            PRIVATE $<$<C_COMPILER_ID:Clang>:-g -O1 -fsanitize=fuzzer>
            )
target_link_libraries(${TEST}
            PRIVATE $<$<C_COMPILER_ID:Clang>:-fsanitize=fuzzer>
            json misc)
