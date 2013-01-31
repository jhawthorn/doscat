
#include "renderers.h"

void TermRenderer::setcolor(int color){
	if(color == 0){
		attr = TextAttr();
	}else if(color <= 8){
		attr.attr = color;
	}else if(color >= 30 && color <= 37){
		attr.fg = color;
	}else if(color >= 40 && color <= 47){
		attr.bg = color;
	}
}

void TermRenderer::emit_char(unsigned char fc){
	term[position.row][position.col].c = fc;
	term[position.row][position.col].attr = attr;
	position.col++;
	position.wrap(width);
}

void TermRenderer::emit_newline(){
	position.row++;
	position.col = 0;
}

void TermRenderer::emit_control(unsigned char fc, int argc, int argv[3]){
	switch(fc){
		case 'A':
			position.row -= DEFAULT(argv[0], 1);
			if(position.row < 0)
				position.row = 0;
			break;
		case 'B':
			position.row += DEFAULT(argv[0], 1);
			break;
		case 'C':
			position.col += DEFAULT(argv[0], 1);
			if(position.col >= width)
				position.col = width-1;
			break;
		case 'D':
			break;
			position.col -= DEFAULT(argv[0], 1);
			if(position.col < 0)
				position.col = 0;
			break;
		case 'J':
			position.row = position.col = 0;
			break;
		case 'H':
		case 'f':
			position.row = argv[0] - 1;
			position.col = argv[1] - 1;
			break;
		case 'u':
			position = saved_position;
			break;
		case 's':
			saved_position = position;
			break;
		case 'm':
			/* COLOR */
			for(int i = 0; i < argc; i++){
				setcolor(argv[i]);
			}
			break;
		default:
			printf("Unknown ANSI code: %c\n", fc);
			break;
	}
}


void TermRenderer::flush(){
	for(unsigned int i = 0; i < term.size(); i++){
		for(unsigned int j = 0; j < term[i].size(); j++){
			unsigned char c = term[i][j].c;
			if(c == 0)
				c = ' ';
			const char *out = cp437_to_unicode[(int)c];
			printf("\e[%i;%i;%im", term[i][j].attr.attr, term[i][j].attr.fg, term[i][j].attr.bg);
			printf("%s", out);
		}
		printf("\e[0m\n");
	}
}


