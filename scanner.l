%Start COMMENT_LINE
%Start COMMENT_BLOCK
%Start String
%Start Pragma
%Start Pragma_no_input
%{
#include "y.tab.h"
#include <string.h>
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define StringLIST(s)		{ strncat(stringbuf, s, sizeof(stringbuf) - strlen(stringbuf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<%s>\n", #t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_ID_NUMBER 257
#define MAX_STRING_LENGTH 257
int Opt_Source = 0;
int Opt_Token = 0;
int Opt_Statistic = 0;
int Opt_Symbol = 0;
int linenum = 1;
int idnum = 0;
int from_pragma = 0;
char buf[MAX_LINE_LENGTH];
char stringbuf[MAX_STRING_LENGTH];
char* idlist[MAX_ID_NUMBER];
int idlist_num[MAX_ID_NUMBER];
%}
digit [0-9]
digits [1-9][0-9]*
letter [_a-zA-Z]+

%%
<INITIAL>"/*"			LIST; BEGIN COMMENT_BLOCK;
<COMMENT_BLOCK>"\n" 	{
							from_pragma = 0;
							LIST;
							if (Opt_Source) printf("%d:%s\n", linenum, buf);
							++linenum;
							buf[0] = '\0';
						}
<COMMENT_BLOCK>"*/"		{
							LIST;
							if (from_pragma == 1) {
								from_pragma = 0;
								BEGIN Pragma_no_input;
							}
							else BEGIN INITIAL;
						}
<COMMENT_BLOCK>.		LIST;

<INITIAL>"//"			LIST; BEGIN COMMENT_LINE;
<COMMENT_LINE>"\n" 		{
							LIST;
							if (Opt_Source) printf("%d:%s\n", linenum, buf);
							++linenum;
							buf[0] = '\0';
							BEGIN INITIAL;
						}
<COMMENT_LINE>.			LIST;

<INITIAL>"#pragma "				LIST; BEGIN Pragma;
<Pragma>"source on"				LIST; Opt_Source = 1; BEGIN Pragma_no_input;
<Pragma>"source off" 			LIST; Opt_Source = 0; BEGIN Pragma_no_input;
<Pragma>"token on" 				LIST; Opt_Token = 1; BEGIN Pragma_no_input;
<Pragma>"token off" 			LIST; Opt_Token = 0; BEGIN Pragma_no_input;
<Pragma>"statistic on"			LIST; Opt_Statistic = 1; BEGIN Pragma_no_input;
<Pragma>"statistic off"			LIST; Opt_Statistic = 0; BEGIN Pragma_no_input;
<Pragma>"symbol on"				LIST; Opt_Symbol = 1; BEGIN Pragma_no_input;
<Pragma>"symbol off"			LIST; Opt_Symbol = 0; BEGIN Pragma_no_input;
<Pragma>[ \t]					LIST;
<Pragma>.						{
									fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
									exit(1);							
								}	
<Pragma_no_input>[ \t]			LIST;
<Pragma_no_input>"//"			BEGIN COMMENT_LINE;
<Pragma_no_input>"/*"			from_pragma = 1; BEGIN COMMENT_BLOCK; 
<Pragma_no_input>"\n"			{
									LIST;
									if (Opt_Source) printf("%d:%s\n", linenum, buf);
									++linenum;
									buf[0] = '\0';
									BEGIN INITIAL;
								}
<Pragma_no_input>.				{
									fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
									exit(1);							
								}		

<INITIAL>\"				LIST; BEGIN String;
<String>\\\"			LIST; StringLIST("\"");
<String>\\\\			LIST; StringLIST("\\");
<String>\"				{
							tokenString("string", stringbuf); 
							yylval.value.text = strdup(stringbuf);
							stringbuf[0] = '\0'; 
							yylval.value.type = 3;
							BEGIN INITIAL;
							return sentence;  
						}
<String>.				LIST; StringLIST(yytext);
<String>"\n"			{
							fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
							exit(1);							
						}
						
<INITIAL>"(" 		    tokenString("delim", "("); return OPEN_PARENTHESIS;
<INITIAL>")" 		    tokenString("delim", ")"); return CLOSE_PARENTHESIS; 
<INITIAL>"," 			tokenString("delim", ","); return COMMA;
<INITIAL>";" 		    tokenString("delim", ";"); return SEMICOLON;
<INITIAL>"[" 		    tokenString("delim", "["); return OPEN_BRACKET;
<INITIAL>"]" 		    tokenString("delim", "]"); return CLOSE_BRACKET;
<INITIAL>"{" 		    tokenString("delim", "{"); return OPEN_BRACE;
<INITIAL>"}" 		    tokenString("delim", "}"); return CLOSE_BRACE;

<INITIAL>"+" 			token("+"); return PLUS;
<INITIAL>"-" 			token("-"); return MINUS;
<INITIAL>"*" 			token("*"); return MULTI;
<INITIAL>"/" 			token("/"); return DIVIDE;
<INITIAL>"%" 			token("%"); return MOD;
<INITIAL>"&&" 			token("&&"); return AND;
<INITIAL>"||" 			token("||"); return OR;
<INITIAL>"<=" 			token("<="); return LESSOREQUAL;
<INITIAL>">=" 			token(">="); return LARGEOREQUAL;
<INITIAL>"<" 			token("<"); return LESS;
<INITIAL>">" 			token(">"); return LARGE;
<INITIAL>"==" 			token("=="); return EQUAL;
<INITIAL>"!=" 			token("!="); return NOTEQUAL;
<INITIAL>"=" 			token("="); return ASSIGN;
<INITIAL>"!" 			token("!"); return NOT;

<INITIAL>while			tokenString("KW", yytext); return WHILE;
<INITIAL>do				tokenString("KW", yytext); return DO;
<INITIAL>if				tokenString("KW", yytext); return CONDITION_IF;
<INITIAL>else			tokenString("KW", yytext); return CONDITION_ELSE;
<INITIAL>true			{tokenString("KW", yytext); yylval.value.val = 1; return SCARLAR_BOOLEAN;}
<INITIAL>false			{tokenString("KW", yytext); yylval.value.val = 0;return SCARLAR_BOOLEAN;}
<INITIAL>for			tokenString("KW", yytext); return FOR;
<INITIAL>int			{
							yylval.type = 0;
							tokenString("KW", yytext); 
							return INT;
						}
<INITIAL>print			tokenString("KW", yytext); return PRINT;
<INITIAL>const			tokenString("KW", yytext); return CONST;
<INITIAL>read			tokenString("KW", yytext); return READ;
<INITIAL>boolean		{
							yylval.type = 4;
							tokenString("KW", yytext); 
							return BOOL;
						}
<INITIAL>bool			{
							yylval.type = 4;
							tokenString("KW", yytext); 
							return BOOL;
						}

<INITIAL>void			{
							yylval.type = 5;
							tokenString("KW", yytext); 
							return VOID;
						}
<INITIAL>float			{
							yylval.type = 1;
							tokenString("KW", yytext); 
							return FLOAT;
						}
<INITIAL>double			{
							yylval.type = 2;
							tokenString("KW", yytext);
							return DOUBLE;
						}
<INITIAL>string			{
							yylval.type = 3;
							tokenString("KW", yytext);
							return STRING;
						}
<INITIAL>continue		tokenString("KW", yytext); return CONTINUE;
<INITIAL>break			tokenString("KW", yytext); return BREAK;
<INITIAL>return			tokenString("KW", yytext); return RETURN;

<INITIAL>[ \t] 			LIST;

<INITIAL>\n 			{
							LIST;
							if (Opt_Source) printf("%d:%s\n", linenum, buf);
							++linenum;
							buf[0] = '\0';
						}

<INITIAL>0|{digits} 				{
										tokenString("integer", yytext); 
										yylval.value.type = 0;
										yylval.value.val = atoi(yytext);
										return integer;
									}
<INITIAL>{digit}+\.{digit}* 		{
										tokenString("float", yytext); 
										yylval.value.type = 1;
										yylval.value.dval = atof(yytext);
										return floating;
									}
<INITIAL>{digit}+(\.{digit}*)?(e|E)((-+)?|"+"?){digit}+ {		
															tokenString("scientific", yytext); 
															yylval.type = 1;
															yylval.value.dval = atof(yytext);
															return floating;
														}
<INITIAL>{letter}({letter}|{digit})* 	{
											int i = 0;
											for (;i < idnum; i++) {
												if (strcmp(idlist[i], yytext) == 0) {
													idlist_num[ i ]++;
													break;
												}
											}
											if (i == idnum) {
												idlist[ i ] = malloc(sizeof(char) * ( strlen(yytext) + 1 ) );
												int j = 0;
												for (;j < strlen( yytext ); j++) {
													idlist[ i ][ j ] = yytext[ j ];
												}
												idlist[ i ][ j ] = '\0';
												idlist_num[ i ] = 1;
												idnum++;
											}
											tokenString("id", yytext);
											yylval.text = strdup(yytext);
											return ID;
										}	

<INITIAL>. 				{ // Unrecognized character
							fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
							exit(1);
						}
%%
