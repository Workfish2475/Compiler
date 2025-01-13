/*   
 Emit Code 
 Name: Alexander Rivera
 Date: 4/23/2024
 Grading level: E

 This program is responsible for generating MIPS assembly code by traversing an Abstract Syntax Tree (AST).
 Most of the function within the program corresponds to a specific type of AST node and generates
 appropriate MIPS assembly instructions. 

 The primary function, EMIT, initializes the process by setting up the MIPS file structure and triggers the recursive 
 parsing of the AST. The program output takes care of memory mangement with MIPS
*/

#ifndef EMIT_H
#define EMIT_H
#include "ast.h"

#define WSIZE 4
#define LOG_WSIZE 2

char *createLabel();
void EMIT(ASTnode *p, FILE *fp);
void EMIT_AST(ASTnode *p,FILE *fp);
void EMIT_GLOBALS(ASTnode *p, FILE *fp);
void EMIT_STRINGS(ASTnode *p, FILE *fp);
void EMIT_FUNCTION(ASTnode *p, FILE *fp);
void EMIT_WRITE(ASTnode *p, FILE *fp);
void EMIT_EXPR(ASTnode *p, FILE *fp);
void EMIT_VAR(ASTnode *p, FILE *fp);
void EMIT_READ(ASTnode *p, FILE *fp);
void EMIT_ASSIGN(ASTnode *p, FILE *fp);
void EMIT_WHILE(ASTnode *p, FILE *fp);
void EMIT_CALL(ASTnode *p, FILE *fp);
void EMIT_RETURN(ASTnode *p, FILE *fp);
void EMIT_IF(ASTnode *p, FILE *fp);
void EMIT_TWIF(ASTnode *p, FILE *fp);
void emit(FILE *fp, char *label, char *command, char *comment);

int STRING_COUNT(ASTnode *p);
int GLOBAL_SPACE(ASTnode *p);

#endif