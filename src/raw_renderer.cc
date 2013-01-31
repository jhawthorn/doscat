
#include "renderers.h"

void RawRenderer::emit_char(unsigned char fc){
	printf("%s", cp437_to_unicode[fc]);
}
void RawRenderer::emit_newline(){
	printf("\n");
}
void RawRenderer::emit_control(unsigned char fc, int argc, int argv[3]){
	printf("\e[");
	if(argc >= 1)
		printf("%i", argv[0]);
	if(argc >= 2)
		printf(";%i", argv[1]);
	if(argc >= 3)
		printf(";%i", argv[2]);
	printf("%c", fc);
}
void RawRenderer::flush(){
	fflush(stdout);
}

