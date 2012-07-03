#ifndef RENDERER_H
#define RENDERER_H RENDERER_H

#include <vector>
#include <limits.h>

#define DEFAULT(V, D) ((V) ? (V) : (D))

class Renderer {
	public:
		virtual ~Renderer(){};

		virtual void emit_char(unsigned char) = 0;
		virtual void emit_newline() = 0;
		virtual void emit_control(unsigned char, int, int[3]) = 0;
};

class RawRenderer: public Renderer {
	public:
		void emit_char(unsigned char fc){
			printf("%s", cp437_to_unicode[fc]);
		}
		void emit_newline(){
			printf("\n");
		}
		void emit_control(unsigned char fc, int argc, int argv[3]){
			printf("\e[");
			if(argc >= 1)
				printf("%i", argv[0]);
			if(argc >= 2)
				printf(";%i", argv[1]);
			if(argc >= 3)
				printf(";%i", argv[2]);
			printf("%c", fc);
		}
};

template <class T>
class AutoVector {
	std::vector<T> v;
	public:
		AutoVector(): v() {};
		T &operator[](unsigned int i){
			if(i >= v.size()){
				v.resize(i+1);
			}
			return v[i];
		}
		unsigned int size(){
			return v.size();
		}
};

struct Position {
	int row, col;

	Position(): row(0), col(0){}
	Position(int row, int col): row(row), col(col){}

	void wrap(int width){
		col %= width;
		row += col / width;
	}
};

class TermRenderer: public Renderer {
	Position position;
	Position saved_position;

	struct TextAttr{
		int attr, fg, bg;
		TextAttr(): attr(0), fg(37), bg(40) {};
	};
	struct OutputChar{
		unsigned char c;
		TextAttr attr;
		OutputChar(): c(0), attr(){}
	};


	AutoVector< AutoVector<OutputChar> > term;
	TextAttr attr;
	int width;

	void setcolor(int color){
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

	public:
		TermRenderer(): position(), saved_position(), term(), attr(), width(INT_MAX){
		}
		void emit_char(unsigned char fc){
			term[position.row][position.col].c = fc;
			term[position.row][position.col].attr = attr;
			position.col++;
			position.wrap(width);
		}
		void emit_newline(){
			position.row++;
			position.col = 0;
		}
		void emit_control(unsigned char fc, int argc, int argv[3]){
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
		void flush(){
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
};

#endif

