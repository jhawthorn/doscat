
#include <string.h>
#include <stdio.h>
#include <wchar.h>

#include "cp437.h"
#include "renderers.h"

%%{
	machine ansi;
	alphtype unsigned char;

	action csi {
		csicount = csiargs[0] = csiargs[1] = csiargs[2] = 0;
	}
	action char_output {
		renderer->emit_char(fc);
	}
	action crlf {
		renderer->emit_newline();
	}
	action ansi {
		renderer->emit_control(fc, csicount, csiargs);
	}

	action setn { csicount = 1; csiargs[0] = csiargs[0] * 10 + (fc - '0'); }
	action setm { csicount = 2; csiargs[1] = csiargs[1] * 10 + (fc - '0'); }
	action setk { csicount = 3; csiargs[2] = csiargs[2] * 10 + (fc - '0'); }

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
		      (printable | cp437) @char_output
		      ;

	main := (valid)*;
}%%

%%write data;

#define BUFSIZE 2048

int main(int argc, char *argv[]){
	char buf[BUFSIZE];

	int cs;

	int csiargs[3] = {0,0,0};
	int csicount = 0;

	TermRenderer *termrenderer = new TermRenderer();
	Renderer *renderer = termrenderer;

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

	termrenderer->flush();

	return 0;
}

