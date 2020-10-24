#include <stdio.h>

extern void test(const char* v);

int main(int argc, char** argv)
{
	if (argc != 2)
	{
		printf("Required argument: 4-digit uppercase hex number, zeroes required.\n"
		       "A 5th digit produces a null test.\n");
		return -1;
	}
	test(argv[1]);
	return 0;
}
