/* 
* Author: Alexander Rivera 
* Date: Feb 27, 2024
* Desc: This is lex code that contains rules that deal with:
* - Strings in the "String" format
* - if, else, while, return, and write statements
* - operators like <, >, <=, etc.
* - handles characters that are not in the string format and numbers
* - eats whitespace and tab.
* - Keeps track of lineno and increments with every newline
*
* Works with lab7.y production rules to parse tokens. 
* 
* Update 5/1/2024: Started trying to implement the break and continue statment (did not complete)
*/

%{
int mydebug=0;
int lineno=1;
#include "ast.h"
#include "y.tab.h"
%}

%%
int         {return (T_INT);}
void        {return(T_VOID);}
read        {return(T_READ);}
"if"        {return(T_IF);}
"else"      {return(T_ELSE);}
"while"     {return(T_WHILE);}
"write"     {return(T_WRITE);}
"return"    {return(T_RETURN);}

"twif"		{return(T_TWIF);}

"break"		{return(T_BREAK);}
"continue"	{return(T_CONTINUE);}

"<"         {return(T_LT);}
">"         {return(T_GT);}
"<="        {return(T_LE);}
">="        {return(T_GE);}
"=="        {return(T_EQ);}
"!="        {return(T_NE);}
\".*\"         {yylval.string = strdup(yytext);return(T_STRING);} //checks for strings formatted as "STRING"
[;=\-+*/%&|(){},[\]]    { if (mydebug) fprintf(stderr,"return a token %c\n",*yytext); return (*yytext);} //checks for tokens
[ \t]       {/* eats whitespace */}
\/\/.*      {/* eats comments */}
[a-zA-Z][a-zA-Z0-9_]*           {yylval.string=strdup(yytext);  return(T_ID);}
[0-9][0-9]*                 {yylval.value=atoi((const char *)yytext); return(T_NUM);}
\n          {lineno++;}
%%

int yywrap(void)
{ return 1;}