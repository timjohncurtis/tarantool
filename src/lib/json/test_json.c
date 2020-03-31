#include <stdint.h>
#include <stddef.h>
#include "json.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  size = 0;
  data = NULL;
/*
  struct json_lexer lexer;
  struct json_token token;
  lexer.src = (char*)data;
  lexer.src_len = (int)size;
  int rc = json_lexer_next_token(&lexer, &token);
  if (rc != 0) {
    return rc;
  }
*/

  return 0;
}
