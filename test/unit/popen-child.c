#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int
main(int argc, char *argv[])
{
	char buf[1024];

	if (argc < 2) {
		fprintf(stderr, "Not enough args\n");
		exit(1);
	}

	// read -n X and the just echo data read
	if (!strcmp(argv[1], "read") &&
	    !strcmp(argv[2], "-n")) {
		ssize_t nr = (ssize_t)atoi(argv[3]);
		if (nr <= 0) {
			fprintf(stderr, "Wrong number of args\n");
			exit(1);
		}

		if (nr >= (ssize_t)sizeof(buf)) {
			fprintf(stderr, "Too many bytes to read\n");
			exit(1);
		}

		ssize_t n = read(STDIN_FILENO, buf, nr);
		if (n != nr) {
			fprintf(stderr, "Can't read from stdin\n");
			exit(1);
		}

		n = write(STDOUT_FILENO, buf, nr);
		if (n != nr) {
			fprintf(stderr, "Can't write to stdout\n");
			exit(1);
		}

		exit(0);
	}

	// just echo the data
	if (!strcmp(argv[1], "echo")) {
		ssize_t nr = (ssize_t)strlen(argv[2]) + 1;
		if (nr <= 0) {
			fprintf(stderr, "Wrong number of bytes\n");
			exit(1);
		}

		ssize_t n = write(STDOUT_FILENO, argv[2], nr);
		if (n != nr) {
			fprintf(stderr, "Can't write to stdout\n");
			exit(1);
		}

		exit(0);
	}

	// just sleep forever
	if (!strcmp(argv[1], "loop")) {
		for (;;)
			sleep(10);
		exit(0);
	}

	fprintf(stderr, "Unknown command passed\n");
	return 1;
}
