# C-minus-simple-compiler
Project from course "Introduction to Compiler" in NCTU (Sep.2014-Jan.2015)

### Introduction
A simple C-minus compiler which support basic C-minus commands and generate assembly code after parsing source code.

### Environment
Ubuntu 14.04

### Dependencies
Yacc, Lex
```
sudo apt-get install flex bison
```
jasmin.jar (download from https://sourceforge.net/projects/jasmin/files/)


### Usage
Generate the parser
```
make
```
Use the parser to compile .c file and generate Java bytecode **test.j**
```
./parser [filename]
```
Generate Java bytecode from Java assembly code by jasmin.jar
```
java -jar jasmin.jar test.j
```
Run the bytecode
```
java test
```
bytecode generated from 'assignment.c', 'if_stmt.c', 'simple_func.c' should run with the following commend
```
java test < [filename].txt
```
Clean the files
```
make clean
```
