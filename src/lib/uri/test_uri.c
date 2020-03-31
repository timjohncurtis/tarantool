#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include "uri.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  size = 0;
  struct uri *uri = NULL;
  uri = calloc(1, sizeof(*uri));
  int rc = uri_parse(uri, (char*)data);
  free(uri);
  if (rc != 0) {
    return rc;
  }

  return 0;
}
