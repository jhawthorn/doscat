
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
	action SGR { /* SGR – Select Graphic Rendition */
		//printf("ANSI: %i %i %c\n", n, m, fc);
		printf("\e[%i;%i;%i%c", n, m, k, fc);
	}
	action SCP { /* CSI s Save Cursor position */
		printf("\e[s");
	}
	action RCP { /* CSI u Restore Cursor position */
		printf("\e[u");
	}
	action ED { /* Erase Data */
		//printf("\e[2J");
	}
	action CURSOR { /* Cursor movement commands */
		if(n == 0) n = 1;
		printf("\e[%i%c", n, fc);
	}
	action CUP  { /* Cursor Position */
		printf("\e[%i;%iH", n, m);
	}
	action ansi { /* SGR – Select Graphic Rendition */
		//printf("ANSI: %i %i %c\n", n, m, fc);
		printf("\e[%i;%i%c", n, m, fc);
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

	action setn { argcount = 1; n = n * 10 + (fc - '0'); }
	action setm { argcount = 2; m = m * 10 + (fc - '0'); }
	action setk { argcount = 3; k = k * 10 + (fc - '0'); }

	esc = 0x1b;
	csi = (esc "[") @csi;

	n = ([0-9] @setn)*;
	m = (';' ([0-9] @setm)*)?;
	k = (';' ([0-9] @setk)*)?;
	crlf = "\n" | "\r\n";

	ansi =  csi (
			n m k 'm' $ SGR |
			's' $ SCP |
			'u' $ RCP |
			[012] 'J' $ ED |
			n [ABCD] $ CURSOR |
			n m [fH] $ CUP

		) ;

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

