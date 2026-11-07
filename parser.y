%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <string>

#define DEBUG_NODE(n) \
    if (!(n)) { std::cerr << "DEBUG: NULL node at " << __FILE__ << ":" << __LINE__ << "\n"; }

extern int yylex(void);
void yyerror(const char *s);

/* --- AST Node (C++ struct) --- */
typedef struct Node {
    std::string name;
    std::string val;
    bool has_val;
    struct Node *first;    // first child
    struct Node *sibling; // next sibling
} Node;

Node* new_node(const std::string &name, const std::string &val = "", bool has_val = false);
void add_child(Node *p, Node *c);
void node_to_json(FILE *f, Node *n);
void write_ast_json(const char *path);

Node *ast_root = nullptr;

/* --- Node functions --- */
Node* new_node(const std::string &name, const std::string &val, bool has_val) {
    Node *n = new Node();
    DEBUG_NODE(n);
    n->name = name;
    n->val = val;
    n->has_val = has_val;
    n->first = nullptr;
    n->sibling = nullptr;
    return n;
}

void add_child(Node *p, Node *c) {
    if (!p || !c) return;
    DEBUG_NODE(p); DEBUG_NODE(c);
    if (!p->first) p->first = c;
    else {
        Node *t = p->first;
        while (t->sibling) t = t->sibling;
        t->sibling = c;
    }
}

/* --- JSON output --- */
void json_escape(FILE *f, const std::string &s){
    fputc('"', f);
    for (char p : s){
        switch(p){
            case '\"': fputs("\\\"", f); break;
            case '\\': fputs("\\\\", f); break;
            case '\n': fputs("\\n", f); break;
            case '\r': fputs("\\r", f); break;
            case '\t': fputs("\\t", f); break;
            default: fputc(p, f);
        }
    }
    fputc('"', f);
}

void node_to_json(FILE *f, Node *n){
    if (!n) return;
    fputs("{", f);
    fputs("\"name\":", f); json_escape(f, n->name); fputs(",", f);
    fputs("\"val\":", f); if(n->has_val) json_escape(f, n->val); else fputs("null", f);
    fputs(",\"children\":[", f);
    Node *c = n->first;
    int first = 1;
    while(c){
        if(!first) fputs(",", f);
        node_to_json(f, c);
        first = 0;
        c = c->sibling;
    }
    fputs("]}", f);
}

void write_ast_json(const char *path){
    FILE *f = fopen(path,"w");
    if(!f){ perror("fopen ast.json"); return; }
    node_to_json(f, ast_root);
    fputs("\n", f);
    fclose(f);
}
%}

%union {
    char *sval;
    Node *node;
}

%token <sval> ID NUMBER TYPE
%token PRINT IF ELSE WHILE FOR
%token ASSIGN SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token PLUS MINUS MUL DIV
%token LT GT LE GE EQ NEQ

%type <node> program statement_list statement decl assign print_stmt if_stmt while_stmt for_stmt block expr

%left PLUS MINUS
%left MUL DIV

%define parse.trace
%%

program:
    statement_list { ast_root = $1; }
;

statement_list:
      /* empty */        { $$ = new_node("program"); }
    | statement_list statement { add_child($1, $2); $$ = $1; }
;

statement:
    decl SEMICOLON       { $$ = $1; }
  | assign SEMICOLON     { $$ = $1; }
  | print_stmt SEMICOLON { $$ = $1; }
  | if_stmt              { $$ = $1; }
  | while_stmt           { $$ = $1; }
  | for_stmt             { $$ = $1; }
  | block                { $$ = $1; }
  ;

decl:
    TYPE ID ASSIGN expr {
        $$ = new_node("decl");
        add_child($$, new_node($1, "", false));
        add_child($$, new_node("id", $2, true));
        add_child($$, $4);
        free($1); free($2);
    }
  | TYPE ID {
        $$ = new_node("decl");
        add_child($$, new_node($1, "", false));
        add_child($$, new_node("id", $2, true));
        free($1); free($2);
    }
  ;

assign:
    ID ASSIGN expr {
        $$ = new_node("assign");
        add_child($$, new_node("id", $1, true));
        add_child($$, $3);
        free($1);
    }
  ;

print_stmt:
    PRINT LPAREN expr RPAREN {
        $$ = new_node("print");
        add_child($$, $3);
    }
  ;

if_stmt:
    IF LPAREN expr RPAREN statement {
        $$ = new_node("if");
        add_child($$, $3);  // condition
        add_child($$, $5);  // then
    }
  | IF LPAREN expr RPAREN statement ELSE statement {
        $$ = new_node("ifelse");
        add_child($$, $3);  // condition
        add_child($$, $5);  // then
        add_child($$, $7);  // else
    }
  ;

while_stmt:
    WHILE LPAREN expr RPAREN statement {
        $$ = new_node("while");
        add_child($$, $3);
        add_child($$, $5);
    }
  ;

for_stmt:
    FOR LPAREN assign SEMICOLON expr SEMICOLON assign RPAREN statement {
        $$ = new_node("for");
        add_child($$, $3);  // init
        add_child($$, $5);  // condition
        add_child($$, $7);  // increment
        add_child($$, $9);  // body
    }
  ;

block:
    LBRACE program RBRACE { $$ = new_node("block"); add_child($$, $2); }
  ;

expr:
    expr PLUS expr   { $$ = new_node("binop", "+", true); add_child($$, $1); add_child($$, $3); }
  | expr MINUS expr  { $$ = new_node("binop", "-", true); add_child($$, $1); add_child($$, $3); }
  | expr MUL expr    { $$ = new_node("binop", "*", true); add_child($$, $1); add_child($$, $3); }
  | expr DIV expr    { $$ = new_node("binop", "/", true); add_child($$, $1); add_child($$, $3); }
  | expr EQ expr     { $$ = new_node("binop", "==", true); add_child($$, $1); add_child($$, $3); }
  | expr NEQ expr    { $$ = new_node("binop", "!=", true); add_child($$, $1); add_child($$, $3); }
  | expr LT expr     { $$ = new_node("binop", "<", true); add_child($$, $1); add_child($$, $3); }
  | expr GT expr     { $$ = new_node("binop", ">", true); add_child($$, $1); add_child($$, $3); }
  | expr LE expr     { $$ = new_node("binop", "<=", true); add_child($$, $1); add_child($$, $3); }
  | expr GE expr     { $$ = new_node("binop", ">=", true); add_child($$, $1); add_child($$, $3); }
  | LPAREN expr RPAREN { $$ = $2; }
  | NUMBER           { $$ = new_node("number", $1, true); free($1); }
  | ID               { $$ = new_node("id", $1, true); free($1); }
  ;

%%

void yyerror(const char *s) { std::cerr << "Parse error: " << s << "\n"; }

int main(int argc, char **argv){
    extern FILE *yyin;
    if(argc > 1){
        yyin = fopen(argv[1],"r");
        if(!yyin){ perror("fopen"); return 1; }
    }
    yyparse();
    write_ast_json("ast.json");
    std::cerr << "AST written to ast.json\n";
    return 0;
}
