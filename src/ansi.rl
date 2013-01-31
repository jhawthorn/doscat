
#include <cstdlib>
#include <cstring>
#include <cstdio>

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

	action arginc { csicount++; }
	action argnum { csiargs[csicount] = csiargs[csicount] * 10 + (fc - '0'); }

	esc = 0x1b;
	csi = (esc "[") @csi;

	n = (([0-9] @argnum)+ %arginc)?;
	m = ((';' ([0-9] @argnum)*) %arginc)?;
	crlf = "\n" | "\r\n";

	ansi = csi n m m m [a-zA-Z] $ ansi;

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

void parse(Renderer *renderer, FILE *file){
	char buf[BUFSIZE];

	int cs;

	int csiargs[4] = {0,0,0,0};
	int csicount = 0;

	%% write init;

	const unsigned char *p;
	const unsigned char *pe;
	while(fgets(buf, sizeof(buf), file)){
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
			abort();
		}
	}


}


