#include "renderers.h"
#include "ansi.h"

int main(int argc, char *argv[]){
	TermRenderer *renderer = new TermRenderer();

	parse(renderer, stdin);
	renderer->flush();

	return 0;
}

