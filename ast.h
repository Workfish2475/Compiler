/*   Abstract syntax tree code


 Header file
 Shaun Cooper Spring 2023
 Modified by: Alexander Rivera 2024

 astnode keeps track of various att of a node:
 - the type
 - the operator (if any)
 - the name
 - the value
 - the data type (int/void)
 - children nodes (s1, s2, and next)
 - funcs that print the ast, checks formal and actual params
 
 Defines structures and enumerations for constructing and manipulating an AST used in lab 9. 
 This includes node types for various syntax elements, operators for expressions, and data types. 
 
 Functions for:
   creating nodes, printing the AST, and semantic checks

*/

#include <stdio.h>
#include <malloc.h>

#include "symtable.h"

#ifndef AST_H
#define AST_H
int mydebug;

/* define the enumerated types for the AST.  THis is used to tell us what
sort of production rule we came across */

enum ASTtype
{
   A_FUNCTIONDEC,
   A_VARDEC,
   A_COMPOUND,
   A_WRITE,
   A_NUM,
   A_EXPR,
   A_READ,
   A_RETURN,
   A_VAR,
   A_CALL,
   A_ASSIGN,
   A_PARAM,
   A_LOCALDEC,
   A_WHILE,
   A_IF,
   A_IFBODY,
   A_ELSE,
   A_ARG,
   A_EXPRSTMT,
   A_IFEXPR,
   A_BREAK,
   A_CONTINUE,
   A_TWIF
};

// Math Operators
enum AST_OPERATORS
{
   A_PLUS,
   A_MINUS,
   A_TIMES,
   A_DIVIDE,
   A_MODULO,
   A_LT,
   A_GT,
   A_LE,
   A_GE,
   A_EQ,
   A_NE
};

enum AST_MY_DATA_TYPE
{
   A_INTTYPE,
   A_VOIDTYPE
};

/* define a type AST node which will hold pointers to AST structs that will
   allow us to represent the parsed code
*/
typedef struct ASTnodetype
{
   enum ASTtype type;
   enum AST_OPERATORS operator;
   char *name;
   int value;
   enum AST_MY_DATA_TYPE my_data_type;

   char *label; // added
   struct SymbTab *symbol;
   struct ASTnodetype *s1, *s2, *next; /* used for holding IF and WHILE components -- not very descriptive */
} ASTnode;

/* uses malloc to create an ASTnode and passes back the heap address of the newley created node */
ASTnode *ASTCreateNode(enum ASTtype mytype);

void PT(int howmany);

/*  Print out the abstract syntax tree */
void ASTprint(int level, ASTnode *p);

int check_params(ASTnode *a, ASTnode *b);

#endif // of AST_H
