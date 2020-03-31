#include <stdint.h>
#include <stddef.h>
#include "csv.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  struct csv *csv = NULL;
  csv_create(csv);
  char *end = (char*)data + size;
  csv_parse_chunk(csv, (const char*)data, end);
  csv_finish_parsing(csv);
  csv_destroy(csv);

  return 0;
}
