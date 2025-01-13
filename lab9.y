%{

/* 

	Author: Alexander Rivera
	Date: April 8, 2024
	Desc: YACC file that is capable of handling:
	- if, else, while, write, and return statements
	- variable declarations
	- expressions
	- conditionals
	- function defs

	Updated Desc: includes all above and also the ability to:
	- check if formal and actuals match (params)
	- check if symbol is already in table or declared
	- tracks space needed through use of global vars (OFFSET, GOFFSET, maxoffset)
	- is able to track scope though use of global var LEVEL
	- makes space for expression operations
	- checks for duplicate params

	Creates context specific nodes that are then passed to a C program for printing out. Handles the assingment
	of node nodes, values, types, etc.
*/


/* begin specs */
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtable.h"
#include "emit.h"

ASTnode *PROGRAM;

extern int mydebug;
extern int lineno;
int yylex();

int LEVEL = 0; //Globabl context variable to know how deep we are. 
int OFFSET = 0; //Global variable for accululation needed runtime space.
int GOFFSET = 0; //globab var for addum global var offset
int maxoffset = 0; //largest offset needed for print function

void yyerror (s)  /* Called by yyparse on error */
     char *s;
{
  printf ("\tYACC PARSE ERROR: %s on line number %d\n", s, lineno);
}

%}

/*  defines the start symbol, what values come back from LEX and how the operators are associated  */

%start Program

%union {
    int value;
    char * string;
	ASTnode *node;
	enum AST_MY_DATA_TYPE d_type;
	enum AST_OPERATORS operator;
}

%token <value> T_NUM
%token <string> T_ID T_STRING //moved this here from T_WRITE
%token T_INT
%token T_VOID
%token T_READ
%token T_RETURN
%token T_LT T_GT T_GE T_LE T_EQ T_NE
%token T_IF T_ELSE T_WHILE T_WRITE

%token T_BREAK 
%token T_CONTINUE

%token T_TWIF

%type <node> Declaration_List Declaration Var_Declaration Var_List
%type <node> Fun_Declaration Params Compound_Stmt Local_Declarations Statement_List Param_List Simple_Expression Param
%type <node> Write_Stmt Expression Additive_Expression Term Factor Var Call Return_Stmt Read_Stmt
%type <node> Args Arg_List Assignment_Stmt Iteration_Stmt Statement Selection_Stmt  Expression_Stmt
%type <node> Break_Stmt Continue_Stmt

%type <node> Twif_Stmt

%type <d_type> Type_Specifier
%type <operator> Addop Relop Multop 

%left '+' '-'
%left '*' '/'

%%	/* end specs, begin rules */
Program: Declaration_List {PROGRAM = $1;}
	;

Declaration_List: Declaration {$$=$1;}
	| Declaration Declaration_List
	{
		$$=$1;
		$$->next=$2;
	}
	;

Declaration: Var_Declaration {$$=$1;}
	| Fun_Declaration {$$=$1;}
	;

Fun_Declaration: Type_Specifier T_ID 
	{
		//Check to see if function has been defined
		if (Search($2, LEVEL, 0) != NULL)
		{
			//ID has already been used, barf
			yyerror($2);
			yyerror("function name already in use");
			exit(1);
		}

		//Not in table, install it
		Insert($2, $1, SYM_FUNCTION, LEVEL, 0, 0);

		GOFFSET = OFFSET;
		OFFSET  = 2;
		maxoffset = OFFSET;
	} 
		'(' Params ')' {Search($2, LEVEL, 0)->fparms=$5; } Compound_Stmt 
	{
		$$=ASTCreateNode(A_FUNCTIONDEC);
		$$->name=$2;
		$$->my_data_type=$1;
		$$->s1=$5; 
		$$->s2=$8;
		$$->symbol = Search($2, LEVEL, 0);

		$$->symbol->offset = maxoffset;

		OFFSET = GOFFSET; //reset the offset for the local vars
	}
	;

Var_Declaration: Type_Specifier Var_List ';'
	{
		ASTnode *p = $2;
		while (p != NULL)
		{
			p->my_data_type = $1;
	
			//Checking each var in list to see if already defined at corresponding level. 
			if (Search(p->name, LEVEL, 0) != NULL){
				//Symbol arlready defined == BARF
				yyerror(p->name);
				yyerror("Symbol already defined");
				exit(1);
			}

			if (p->value == 0){
				//Was not in table
				p->symbol = Insert(p->name, p->my_data_type, SYM_SCALAR, LEVEL, 1,OFFSET);
				OFFSET = OFFSET + 1;
			} else {
				//We have an array
				p->symbol = Insert(p->name, p->my_data_type, SYM_ARRAY, LEVEL, p->value,OFFSET);
				OFFSET = OFFSET + p->value;
			}
			//incs p
			p = p->s1;
		}
		$$=$2;
	};

Var_List: T_ID 
	{
		$$=ASTCreateNode(A_VARDEC);
		$$->name = $1;
	}
	| T_ID '[' T_NUM ']' 
	{
		$$=ASTCreateNode(A_VARDEC);
		$$->name = $1; 
		$$->value = $3;
	}
	| T_ID ',' Var_List 
	{
		$$=ASTCreateNode(A_VARDEC);
		$$->name = $1; 
		$$->s1 = $3;
	}
	| T_ID '[' T_NUM ']' ',' Var_List 
	{
		$$=ASTCreateNode(A_VARDEC);
		$$->name = $1;
		$$->value = $3;
		$$->s1 = $6;
	}
	;


Type_Specifier: T_INT {$$=A_INTTYPE;}
	| T_VOID {$$=A_VOIDTYPE;}
	;

Params: T_VOID {$$=NULL;}
	| Param_List {$$=$1;}
	;

Param_List: Param {$$=$1;}
	| Param ',' Param_List
	{
		$$=$1;
		$$->next=$3;
	}
	;

Param: Type_Specifier T_ID 
	{
		if (Search($2, LEVEL+1, 0) != NULL){
			yyerror($2);
			yyerror("parameter already used");
			exit(1);
		}

		$$=ASTCreateNode(A_PARAM);
		$$->my_data_type=$1;
		$$->value = 0;
		$$->name=$2;
		$$->symbol = Insert($$->name, $$->my_data_type, SYM_SCALAR, LEVEL + 1, 1, OFFSET);
		OFFSET = OFFSET + 1;
	}
	| Type_Specifier T_ID '['']' 
	{
		if (Search($2, LEVEL+1, 0) != NULL){
			yyerror($2);
			yyerror("parameter already used defined already");
			exit(1);
		}

		$$=ASTCreateNode(A_PARAM);
		$$->my_data_type=$1;
		$$->name=$2;
		$$->value = -1;
		$$->symbol = Insert($$->name, $$->my_data_type, SYM_ARRAY, LEVEL + 1, 1, OFFSET);
		OFFSET = OFFSET + 1;
	}
	;

Compound_Stmt: '{' {LEVEL++;} Local_Declarations Statement_List '}' 
	{
		$$=ASTCreateNode(A_COMPOUND);
		$$->s1=$3;
		$$->s2=$4;
		
		if (mydebug){
			Display();
		}

		//We set the max offset 
		if (OFFSET > maxoffset){
			maxoffset = OFFSET;
		}

		OFFSET -= Delete(LEVEL);
		LEVEL--;
	}
	;

Local_Declarations: /* empty */ {$$=NULL;}
	| Var_Declaration Local_Declarations {
		$$=$1;
		$$->next=$2;
	}
	;
Statement_List: /* empty */ {$$=NULL;}
	| Statement Statement_List 
	{
		$$=$1;
		$$->next=$2;
	}
	;

Statement : Read_Stmt {$$=$1;}
	| Compound_Stmt	{$$=$1;}
	| Selection_Stmt {$$=$1;}
	| Iteration_Stmt {$$=$1;}
	| Assignment_Stmt {$$=$1;}
	| Return_Stmt {$$=$1;}
	| Write_Stmt {$$=$1;}
	| Expression_Stmt {$$=$1;}
	| Break_Stmt {$$=$1;}
	| Continue_Stmt {$$=$1;}
	| Twif_Stmt {$$=$1;}
	;

Expression_Stmt: Expression ';' {$$=ASTCreateNode(A_EXPRSTMT); $$->s1=$1;}
	| ';' {$$=ASTCreateNode(A_EXPRSTMT);}
	;

Selection_Stmt: T_IF '(' Expression ')' Statement 
	{
		$$=ASTCreateNode(A_IF);
		$$->s1=ASTCreateNode(A_EXPR); //was A_IFEXPR
		$$->s1->s1=$3;
		$$->s2=ASTCreateNode(A_ELSE);
		$$->s2->s1=$5;


	}
	| T_IF '(' Expression ')' Statement T_ELSE Statement 
	{
		$$=ASTCreateNode(A_IF);
		$$->s1=ASTCreateNode(A_EXPR); //was A_IFEXPR
		$$->s1->s1=$3;
		$$->s2=ASTCreateNode(A_ELSE); 
		$$->s2->s1=$5;
		$$->s2->s2=$7;
	}
	;

Twif_Stmt: T_TWIF '(' Expression ')' Statement Statement Statement
	{
		$$=ASTCreateNode(A_TWIF);
		//Something goes here.
	}

Break_Stmt: T_BREAK ';' 
	{
		//Need to add type checking here to check if in loop
		$$=ASTCreateNode(A_BREAK);
	}

Continue_Stmt: T_CONTINUE ';'
{
	//Need to add type checking here to check if in loop
	$$=ASTCreateNode(A_CONTINUE);
}

Iteration_Stmt: T_WHILE '(' Expression ')' Statement 
	{ 

		$$=ASTCreateNode(A_WHILE);
		$$->s1=$3;
		$$->s2=$5;

	}
	;

Return_Stmt: T_RETURN ';' {$$=ASTCreateNode(A_RETURN);}
	| T_RETURN Expression ';' 
	{
		$$=ASTCreateNode(A_RETURN); 
		$$->s1=$2;
	}
	;

Read_Stmt: T_READ Var ';' 
	{
		$$=ASTCreateNode(A_READ);
		$$->s1=$2;
	}
	;

Write_Stmt: T_WRITE Expression ';' {$$=ASTCreateNode(A_WRITE); $$->s1=$2;}
	| T_WRITE T_STRING ';' 
	{
		$$=ASTCreateNode(A_WRITE);
		$$->name=$2;
	}
	;

Expression: Simple_Expression {$$=$1;}
	;

Simple_Expression: Additive_Expression {$$=$1;}
	| Additive_Expression Relop Simple_Expression 
	{
		//insert here? 
		
		$$=ASTCreateNode(A_EXPR);
		$$->s1=$1;
		$$->s2=$3;
		$$->operator=$2;

		//creates temp for expression 
		$$->name = CreateTemp();
		$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
		OFFSET++;
	} //! was set to Additive_Expression Relop Additive_Expression
	;

Assignment_Stmt: Var '=' Simple_Expression ';' 
	{
		$$=ASTCreateNode(A_ASSIGN);
		$$->s1=$1;
		$$->s2=$3;

		//creates temp for expression
		$$->name = CreateTemp();
		$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
		OFFSET++;
	}
	;

Relop: T_LT  {$$ = A_LT;}
    | T_GT  {$$ = A_GT;}
    | T_LE  {$$ = A_LE;}
    | T_GE  {$$ = A_GE;}
    | T_EQ  {$$ = A_EQ;}
    | T_NE  {$$ = A_NE;}
    ;

Additive_Expression: Term {$$=$1;}
	|  Additive_Expression Addop Term  
	{
		//Checks if the types match
		if ($1->my_data_type != $3->my_data_type){
			yyerror("Type mismatch");
			exit(1);
		}

		//! insert here?

		//Creates the actual node for an expr
		$$=ASTCreateNode(A_EXPR);
		$$->s1=$1;
		$$->s2=$3;
		$$->operator = $2;
		
		//creates temp for expression
		$$->name = CreateTemp();
		$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
		OFFSET = OFFSET + 1;

	} //!Was set to Term Addop Additive_Expression
	;

Addop: '+' {$$=A_PLUS;}
	| '-' {$$=A_MINUS;}
	;

Term: Factor {$$=$1;}
	| Term Multop Factor 
	{
		$$=ASTCreateNode(A_EXPR);
		$$->s1=$1;
		$$->s2=$3;
		$$->operator=$2;
		$$->my_data_type = $1->my_data_type;

		//creates temp for expression
		$$->name = CreateTemp();
		$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
		OFFSET = OFFSET + 1;
	} 
	;

Multop: '*'  {$$=A_TIMES;}
	| '/' {$$=A_DIVIDE;}
	| '%' {$$=A_MODULO;} 
	;

Var: T_ID 
	{
		struct SymbTab *p;
		p = Search($1, LEVEL, 1);
		if (p == NULL){
			//A ref not in sym table
			yyerror($1);
			yyerror("symbol used but not defined");
			exit(1);
		}

		if (p->SubType != SYM_SCALAR){
			//A ref to a non scalar variable
			yyerror($1);
			yyerror("symbol used must be a scalar");
			exit(1);
		}

		$$=ASTCreateNode(A_VAR);
		$$->name = $1;
		$$->symbol = p;
		$$->my_data_type = p->Declared_Type;

	}
    | T_ID '[' Expression ']' 
	{	

		//Added most of this code.
		struct SymbTab *p;
		p = Search($1, LEVEL, 1);
		if (p == NULL){
			yyerror($1);
			yyerror("Symbol used but not defined");
			exit(1);
		}

		//checks if the subtype is a arr
		if (p->SubType != SYM_ARRAY){
			yyerror($1);
			yyerror("Symbol used must be an arry");
			exit(1);	
		}

		$$=ASTCreateNode(A_VAR);
		$$->name = $1;
		$$->s1=$3;
		$$->symbol = p;
		$$->my_data_type = p->Declared_Type; //assumes type from symbtab entry
	}
	;

Factor: '(' Expression ')' {$$=$2;}
	| T_NUM {
		$$=ASTCreateNode(A_NUM); 
		$$->value=$1;
		$$->my_data_type = A_INTTYPE; 
	}
	| Var {$$=$1;}
	| Call {$$=$1;}
	| '-' Factor 
	{
		if ($2->my_data_type != A_INTTYPE){
			yyerror("Type mismatch unary minus");
			exit(1);
		}
		$$=ASTCreateNode(A_EXPR);
		$$->operator=A_MINUS;
		$$->s1=$2;

		/*
		$$->name = CreateTemp();
		$$->my_data_type = A_INTTYPE;
		$$->symbol = Insert($$->name, $2->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
		*/
	}
	;

Call: T_ID '(' Args ')' 
	{
		struct SymbTab *p;
		p = Search($1, 0, 0);

		if (p == NULL){
			//Function name not know
			yyerror($1);
			yyerror("Function name not defined");
			exit(1);
		}

		//Name is there, but is it a function?
		if (p->SubType != SYM_FUNCTION){
			yyerror($1);
			yyerror("is not defined as function");
			exit(1);
		}

		//checks if the formals match the actuals by making call to external func
		if (check_params($3,p->fparms) == 0){
			yyerror($1);
			yyerror("actuals and formals do not match");
			exit(1);
		}

		$$=ASTCreateNode(A_CALL);
		$$->name=$1;
		$$->s1=$3;
		$$->symbol = p;

	}
	;

Args: /* Empty */ {$$ = NULL;}
    | Arg_List {$$=$1;}
    ;

Arg_List: Expression {
    $$ = ASTCreateNode(A_ARG);
    $$->s1=$1;
	$$->my_data_type = $1->my_data_type;

	//creates temp for expression
	$$->name = CreateTemp();
	$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
	OFFSET++;
    }

    | Expression ',' Arg_List {
    
	//Consider making this left recursive instead of right.
	$$ = ASTCreateNode(A_ARG);

	//! The s1 is the actual expression
    $$->s1 = $1;
	$$->my_data_type = $1->my_data_type;

	//The next is the next argument 
	$$->next=$3;

	//creates temp for expression
	$$->name = CreateTemp();
	$$->symbol = Insert($$->name, $1->my_data_type, SYM_SCALAR, LEVEL, 1, OFFSET);
	OFFSET++;
    }
    ;

%%	/* end of rules, start of program */

int main(int argc, char *argv[])
{

	FILE *fp;
	char s[100];

	// option -d turn on debug

	for (int i = 0; i < argc; i++){

		if (strcmp(argv[i], "-d") == 0){
			mydebug = 1;
		}

		if (strcmp(argv[i], "-o") == 0){
			printf("We have file input");
			strcpy(s, argv[i + 1]);
			strcat(s, ".asm");
			printf("File name is %s\n", s);
		}
	}

	fp = fopen(s, "w");

	if (fp == NULL){
		printf("Cannot open file %s\n", s);
		exit(1);
	}

	yyparse();

	EMIT(PROGRAM, fp);
	exit(1);

	//Never getting to this point in the code. Even when passing -d
	if (mydebug){
		printf("\n\nFinished parsing\n\n");
		Display(); //Shows our global variables and functions.
		printf("\n\nAST Print \n\n");
		ASTprint(0, PROGRAM);
	}
}