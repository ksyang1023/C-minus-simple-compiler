all:
	lex scanner.l
	yacc -d -v parser.y
	gcc -o parser lex.yy.c y.tab.c -ly -lfl
	rm lex.yy.c y.*
clean:
	rm parser *.j *.class