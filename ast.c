/*
  ast.c 
  Name: Alexander Rivera

  Implementation of the Abstract Syntax Tree (AST) for lab 9.

  It's used to support working with the AST in lab 9

  Detailed functionalities include:
  - Creating nodes: Functions here allocate and initialize new nodes for the AST with specified attributes.
  - Printing the AST: Implements a detailed recursive function to visually display the structure of the AST
  - Semantic checks: Contains routines to compare expected and actual parameters in function calls, ensuring
    the semantic integrity of the code.

 */

#include <stdio.h>
#include <malloc.h>
#include "ast.h"
extern int lineno;

/* uses malloc to create an ASTnode and passes back the heap address of the newley created node */
//  PRE:  Ast Node Type
//  POST:   PTR To heap memory and ASTnode set and all other pointers set to NULL
ASTnode *ASTCreateNode(enum ASTtype mytype)
{
  ASTnode *p;
  if (mydebug)
    fprintf(stderr, "Creating AST Node \n");
  p = (ASTnode *)malloc(sizeof(ASTnode));
  p->type = mytype;
  p->s1 = NULL;
  p->s2 = NULL;
  p->next = NULL;
  p->value = 0;
  p->symbol = NULL;
  p->label = NULL;

  return (p);
}

/*  Helper function to print tabbing */
// PRE:  Number of spaces desired
// POST:  Number of spaces printed on standard output
void PT(int howmany)
{
  if (howmany == 0)
  {
    return;
  }
  for (int i = 0; i < howmany; i++)
  {
    printf(" ");
  }
}

//  PRE:  A declaration type
//  POST:  A character string that is the name of the type
//          Typically used in formatted printing
char *ASTtypeToString(enum AST_MY_DATA_TYPE mytype)
{
  switch (mytype)
  {
  case A_INTTYPE:
    return "INT";
  case A_VOIDTYPE:
    return "VOID";
  default:
    return "UNKNOWN";
  }
}

// PRE: An operator
// POST: a character string that corresponds to the operator passed.
char *ASToperatorToString(enum AST_OPERATORS operator)
{
  switch (operator)
  {
  case A_PLUS:
    return "PLUS";
  case A_MINUS:
    return "MINUS";
  case A_TIMES:
    return "TIMES";
  case A_DIVIDE:
    return "/";
  case A_MODULO:
    return "%";
  case A_LT:
    return "<";
  case A_GT:
    return ">";
  case A_LE:
    return "<=";
  case A_GE:
    return ">=";
  case A_EQ:
    return "==";
  case A_NE:
    return "!=";
  default:
    return "UNKNOWN";
  }
}

// PRE: PTRS to actual and formals
// POST: 0 if they are not same type or length
//       1 if they are
int check_params(ASTnode *a, ASTnode *b)
{

  // a is actuals, b is formals (base case)
  if (a == NULL && b == NULL)
  {
    return 1;
  }

  if (a == NULL || b == NULL)
  {
    return 0;
  }

  // checks if the data types do not match and recursively calls check_params if they do.
  if (a->my_data_type != b->my_data_type)
  {
    return 0;
  }

  // both are next connected, was using s1 initially...idk why
  return check_params(a->next, b->next);
}

/*  Print out the abstract syntax tree */
// PRE:   PRT to an ASTtree
// POST:  indented output using AST order printing with indentation
void ASTprint(int level, ASTnode *p)
{
  int i;
  if (p == NULL)
    return;
  switch (p->type)
  {
  case A_VARDEC:
    PT(level);
    if (p->value > 0)
    {
      printf("Variable %s %s[%d] level %d offset %d\n", ASTtypeToString(p->my_data_type), p->name, p->value, p->symbol->level, p->symbol->offset);
    }
    else
    {
      printf("Variable %s %s level %d offset %d\n", ASTtypeToString(p->my_data_type), p->name, p->symbol->level, p->symbol->offset);
    }
    ASTprint(level, p->s1);
    ASTprint(level + 1, p->s2);
    ASTprint(level, p->next);
    break;
  case A_FUNCTIONDEC:
    PT(level);
    printf("Function %s %s level %d offset %d\n", ASTtypeToString(p->my_data_type), p->name, p->symbol->level, p->symbol->offset);
    ASTprint(level + 1, p->s1); // params
    ASTprint(level + 1, p->s2); // compound
    ASTprint(level, p->next);
    break;
  case A_COMPOUND:
    PT(level);
    printf("Compound Statement \n");
    ASTprint(level + 1, p->s1); // local decs
    ASTprint(level + 1, p->s2); // statement list
    ASTprint(level, p->next);
    break;
  case A_WRITE:
    PT(level);
    if (p->name != NULL)
    {
      printf("Write String %s\n", p->name);
    }
    else
    {
      printf("Write Expression\n");

      ASTprint(level + 1, p->s1);
    }
    ASTprint(level, p->next);
    break;
  case A_NUM:
    PT(level);
    printf("NUMBER value %d\n", p->value);
    break;
  case A_EXPR:
    PT(level);
    printf("EXPRESSION operator %s\n", ASToperatorToString(p->operator));
    ASTprint(level + 1, p->s1);
    ASTprint(level + 1, p->s2);
    ASTprint(level, p->next);
    break;
  case A_RETURN:
    PT(level);
    printf("Return statement\n");
    ASTprint(level + 1, p->s1);
    break;
  case A_BREAK:
    PT(level);
    printf("Break statement\n");
    break;
  case A_CONTINUE:
    PT(level);
    printf("Continue statement\n");
    break;
  case A_PARAM:
    PT(level);
    printf("Param %s %s level %d offset %d\n", ASTtypeToString(p->my_data_type), p->name, p->symbol->level, p->symbol->offset);
    ASTprint(level, p->s1);
    ASTprint(level, p->next);
    break;
  case A_VAR:
    PT(level);
    // This causes a seg fault if we print the level and offset.
    printf("VAR %s level %d offset %d\n", p->name, p->symbol->level, p->symbol->offset);
    ASTprint(level + 1, p->s1);
    ASTprint(level, p->next);
    break;
  case A_ASSIGN:
    PT(level);
    printf("ASSIGNMENT statement\n");
    ASTprint(level + 1, p->s1);
    PT(level);
    printf("is assigned\n");
    ASTprint(level + 1, p->s2);
    ASTprint(level, p->next);
    break;
  case A_IF:
    PT(level);
    printf("IF STATEMENT\n");
    ASTprint(level + 1, p->s1);
    ASTprint(level + 1, p->s2);
    ASTprint(level + 2, p->next);
    break;
  case A_IFEXPR:
    PT(level);
    printf("IF expression\n");
    ASTprint(level + 1, p->s1);
    break;
  case A_ELSE:
    PT(level);
    printf("IF body\n");
    ASTprint(level + 1, p->s1);

    if (p->s2 != NULL)
    {
      PT(level);
      printf("Else body\n");
    }

    ASTprint(level + 1, p->s2);
    break;
  case A_READ:
    PT(level);
    printf("READ statement\n");
    ASTprint(level + 1, p->s1);
    break;
  case A_WHILE:
    PT(level);
    printf("WHILE statement\n");
    ASTprint(level + 1, p->s1);
    PT(level);
    printf("While body\n");
    ASTprint(level + 1, p->s2);
    ASTprint(level + 2, p->next);
    break;
  case A_LOCALDEC:
    PT(level);
    printf("%s \n", p->name);
    ASTprint(level + 1, p->s1);
    ASTprint(level + 1, p->s2);
    break;
  case A_CALL:
    PT(level);
    printf("CALL statement function %s\n", p->name);
    ASTprint(level + 1, p->s1);
    ASTprint(level, p->s2);
    ASTprint(level, p->next);
    break;
  case A_ARG:
    PT(level);
    printf("CALL argument\n");
    ASTprint(level + 1, p->s1);
    if (p->next != NULL)
    {
      ASTprint(level, p->next);
    }
    break;
  case A_EXPRSTMT:
    PT(level);
    printf("Expression STATEMENT\n");
    ASTprint(level + 1, p->s1);
    ASTprint(level, p->s2);
    ASTprint(level, p->next);
    break;

  case A_TWIF:
    PT(level);
    printf("Twif statement\n");
    

  default:
    printf("UNKNOWN AST Node type %d in ASTprint on line%d\n", p->type, lineno);
  }
}

/* dummy main program so I can compile for syntax error independently
main()
{
}
/* */
