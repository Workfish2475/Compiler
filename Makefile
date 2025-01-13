# Name: Alexander Rivera
# Date: 4/23/2024
# Description: This makefile assembles and links various components of a compiler project (lab 9),
# including lexer and parser files (lab9.l and lab9.y), AST management (ast.c and ast.h), 
# symbol table management (symtable.c and symtable.h), and MIPS code emission (emit.c). 
# The resulting executable, lab9, parses C-like code, generates an AST, and handles symbol 
# table operations.

# Build the entire project.
# Usage: make all
all: lab9

# Compile and link the project sources into the executable 'lab9'.
# Dependencies: Lexical and syntax parsers, AST management, symbol table management, and MIPS code emission modules.
# Usage: make lab9
lab9: lab9.y lab9.l ast.c ast.h symtable.c symtable.h emit.c emit.h
	lex lab9.l
	yacc -d lab9.y
	gcc ast.c symtable.c lex.yy.c y.tab.c emit.c -o lab9

# Run the compiler without debug 'lab9test.c' and output to 'test.asm'.
# Usage: make test1
test1: lab9
	-./lab9 -o test < lab9test.c

# Run the compiler with debug 'lab9test.c' and output to 'test.asm'.
# Usage: make test2
test2: lab9
	./lab9 -d -o test < lab9test.c

# Makes from Cooper directory for testing
# Usage: make cooper
cooper: lab9
	-~scooper/lab9 -o outfile < lab9test.c

# Run MIPS on test.asm and outfile.asm
# Usage: make javatest
javatest: 
	-java -jar /usr/local/lib/Mars4_5.jar sm test.asm
	@echo ""
	-java -jar /usr/local/lib/Mars4_5.jar sm outfile.asm

# Run a full suite of tests combining test1, cooper, and javatest.
# Usage: make test
test: test1 cooper javatest

# Clean up the project by removing the executable and any generated assembly files. Clears the screen.
# Usage: make clean
clean:
	rm -rf lab9
	rm -rf *.asm
	clear