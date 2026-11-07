%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <string>

typedef struct Node Node;
#include "parser.tab.h"

void yyerror(const char *s);
%}

DIGIT       [0-9]
HEX_DIGIT   [0-9a-fA-F]
ID_START    [a-zA-Z_]
ID_CONT     [a-zA-Z0-9_]

%%

"int"       { yylval.sval = strdup(yytext); std::cout << "LEX: TYPE(int)\n"; return TYPE; }
"float"     { yylval.sval = strdup(yytext); std::cout << "LEX: TYPE(float)\n"; return TYPE; }
"print"     { std::cout << "LEX: PRINT\n"; return PRINT; }
"if"        { std::cout << "LEX: IF\n"; return IF; }
"else"      { std::cout << "LEX: ELSE\n"; return ELSE; }
"while"     { std::cout << "LEX: WHILE\n"; return WHILE; }
"for"       { std::cout << "LEX: FOR\n"; return FOR; }

"=="        { std::cout << "LEX: EQ\n"; return EQ; }
"!="        { std::cout << "LEX: NEQ\n"; return NEQ; }
"<="        { std::cout << "LEX: LE\n"; return LE; }
">="        { std::cout << "LEX: GE\n"; return GE; }
"<"         { std::cout << "LEX: LT\n"; return LT; }
">"         { std::cout << "LEX: GT\n"; return GT; }
"="         { std::cout << "LEX: ASSIGN\n"; return ASSIGN; }
";"         { std::cout << "LEX: SEMICOLON\n"; return SEMICOLON; }
"("         { std::cout << "LEX: LPAREN\n"; return LPAREN; }
")"         { std::cout << "LEX: RPAREN\n"; return RPAREN; }
"{"         { std::cout << "LEX: LBRACE\n"; return LBRACE; }
"}"         { std::cout << "LEX: RBRACE\n"; return RBRACE; }
"+"         { std::cout << "LEX: PLUS\n"; return PLUS; }
"-"         { std::cout << "LEX: MINUS\n"; return MINUS; }
"*"         { std::cout << "LEX: MUL\n"; return MUL; }
"/"         { std::cout << "LEX: DIV\n"; return DIV; }

"0x"{HEX_DIGIT}+  { yylval.sval = strdup(yytext); std::cout << "LEX: NUMBER(hex " << yytext << ")\n"; return NUMBER; }
{DIGIT}+          { yylval.sval = strdup(yytext); std::cout << "LEX: NUMBER(" << yytext << ")\n"; return NUMBER; }

{ID_START}{ID_CONT}* { yylval.sval = strdup(yytext); std::cout << "LEX: ID(" << yytext << ")\n"; return ID; }

[ \t\r\n]+    ;   
"//".*        ;   
"/*"([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*"*"+"/" ;  

. { std::cerr << "LEX ERROR: Unexpected character: " << yytext << "\n"; }

%%

int yywrap(void) { return 1; }
