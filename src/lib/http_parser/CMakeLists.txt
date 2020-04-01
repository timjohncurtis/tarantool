add_library(http_parser STATIC http_parser.c)

set(TEST "test_http_parser")
add_executable(${TEST} ${TEST}.c)
set_target_properties(${TEST}
        PROPERTIES
        COMPILE_FLAGS "-fsanitize=fuzzer -g -O1"
        LINK_FLAGS "-fsanitize=fuzzer")
target_link_libraries(${TEST} PRIVATE http_parser)
