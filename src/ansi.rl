
#include <string.h>
#include <stdio.h>
#include <wchar.h>

#include "cp437.h"

#define ESC (char)(0x1b)

%%{
	machine ansi;
	alphtype unsigned char;

	action csi {
		argcount = m = n = k = 0;
	}
	action cp437_output {
		printf("%s", cp437_to_unicode[fc]);
	}
	action ascii_output {
		printf("%c", fc);
	}
	action crlf {
		printf("\n");
	}

	action ansi {
		printf("\e[");
		if(argcount >= 1)
			printf("%i", n);
		if(argcount >= 2)
			printf(";%i", m);
		if(argcount >= 3)
			printf(";%i", k);
		printf("%c", fc);
	}

	action setn { argcount = 1; n = n * 10 + (fc - '0'); }
	action setm { argcount = 2; m = m * 10 + (fc - '0'); }
	action setk { argcount = 3; k = k * 10 + (fc - '0'); }

	esc = 0x1b;
	csi = (esc "[") @csi;

	n = ([0-9] @setn)*;
	m = (';' ([0-9] @setm)*)?;
	k = (';' ([0-9] @setk)*)?;
	crlf = "\n" | "\r\n";

	ansi =  csi n m k [a-zA-Z] $ ansi;

	cp437 = (0x1 .. 0x1f | 0x80 .. 0xff) -- esc -- [\r\n];
	printable = (0x20 .. 0x7f);

	valid =
		      ansi |
		      crlf @crlf |
		      printable @ascii_output |
		      cp437 @cp437_output;

	main := (valid)*;
}%%

%%write data;

#define BUFSIZE 2048

int main(int argc, char *argv[]){
	char buf[BUFSIZE];

	int cs;
	int m, n, k, argcount;
	int sgr0, sgr1, sgr2;
	argcount = m = n = k = sgr0 = sgr1 = sgr2 = 0;

	%% write init;

	const unsigned char *p;
	const unsigned char *pe;
	while(fgets(buf, 2, stdin)){
		//printf("%c (0x%.2x)\n", buf[0], buf[0]);
		int oldstate = cs;
		p  = (unsigned char *)buf;
		pe = (unsigned char *)buf + strlen(buf);
		%% write exec;
		fflush(stdout);

		if(cs == 0){
		  fflush(stdout);
		  fprintf(stderr, "\n\n\n\n\n\n\n\n\n");
		  fprintf(stderr, "error parsing: reached character %li\n", (p - (unsigned char *)buf));
		  fprintf(stderr, "state was: %i\n", oldstate);
		  fprintf(stderr, "char was: '%c' (0x%.2x)\n", *p, *p);
		  return 0;
		}
	}

	return 0;
}

