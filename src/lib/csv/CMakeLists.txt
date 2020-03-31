set(lib_sources
    csv.c
)

set_source_files_compile_flags(${lib_sources})
add_library(csv STATIC ${lib_sources})

set(TEST "test_csv")
add_executable(${TEST} ${TEST}.c)
target_compile_options(${TEST}
            PRIVATE $<$<C_COMPILER_ID:Clang>:-g -O1 -fsanitize=fuzzer>
            )
target_link_libraries(${TEST}
            PRIVATE $<$<C_COMPILER_ID:Clang>:-fsanitize=fuzzer>
            csv)
