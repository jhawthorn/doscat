#ifndef RENDERER_H
#define RENDERER_H RENDERER_H

#include <cstdio>
#include <vector>
#include <limits.h>

#include "cp437.h"

#define DEFAULT(V, D) ((V) ? (V) : (D))

class Renderer {
	public:
		virtual ~Renderer(){};

		virtual void emit_char(unsigned char) = 0;
		virtual void emit_newline() = 0;
		virtual void emit_control(unsigned char, int, int[3]) = 0;
		virtual void flush(){};
};

class RawRenderer: public Renderer {
	public:
		void emit_char(unsigned char fc);
		void emit_newline();
		void emit_control(unsigned char fc, int argc, int argv[3]);
		void flush();
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

class TermRenderer: public Renderer {
	struct Position {
		int row, col;

		void wrap(int width){
			row += col / width;
			col %= width;
		}
	};

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

	void setcolor(int color);

	public:
	TermRenderer(int width=80): position(), saved_position(), term(), attr(), width(width){
	}
	void emit_char(unsigned char fc);
	void emit_newline();
	void emit_control(unsigned char fc, int argc, int argv[3]);
	void flush();
};

#endif

