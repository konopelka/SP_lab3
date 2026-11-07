all: parser

parser: parser.tab.cpp lex.yy.cpp
	g++ -std=c++17 parser.tab.cpp lex.yy.cpp -o parser

parser.tab.cpp parser.tab.h: parser.y
	bison -d -o parser.tab.cpp --defines=parser.tab.h parser.y

lex.yy.cpp: lexer.l parser.tab.h
	flex -o lex.yy.cpp lexer.l

clean:
	rm -f parser parser.tab.cpp parser.tab.h lex.yy.cpp ast.json
