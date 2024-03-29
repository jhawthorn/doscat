
TARGET := doscat

OBJFILES := src/doscat.o src/ansi.o src/raw_renderer.o src/term_renderer.o
DEPFILES := $(OBJFILES:%.o=%.d)
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

RAGEL:=ragel
DOT:=dot
#RLFLAGS:=-p

# User configuration
-include config.mk

CXXFLAGS ?= -g -O2 -Wall -Wextra -Weffc++ -DNDEBUG

all: $(TARGET)

$(TARGET): $(OBJFILES)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

-include $(DEPFILES)

%.png: %.dot
	$(DOT) -Tpng -o $@ $<

%.dot: %.rl
	$(RAGEL) $(RLFLAGS) -V -o $@ $<

%.cc: %.rl
	$(RAGEL) $(RLFLAGS) -C -o $@ $<

%.o: %.cc Makefile
	$(CXX) $(CXXFLAGS) -MMD -MP -MT "$*.d" -c -o $@ $<

view: src/ansi.png
	meh src/ansi.png

install:
	install -Dm 755 $(TARGET) $(BINDIR)

# Clean
clean:
	$(RM) src/*.o src/*.d src/*.png $(TARGET)

.PHONY: clean

