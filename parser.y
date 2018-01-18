%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
extern int Opt_Symbol;

typedef struct array_type{
	int elements;
	struct array_type * next;
}array_type;

typedef struct symbol_table_attributes {
	char * variable_name;
	int array_dimension;                   
	int variable_type;
	int const_integer;
	double const_floating;
	char * const_string;
	array_type * array;
	struct symbol_table_attributes * next;
}symbol_table_attributes;

typedef struct symbol_table {
	char *name;
	char *kind;
	int level;
	int type;
	int func_def_bit;
	int array_dimension;
	array_type * array;
	symbol_table_attributes * attribute;	
	int location;
	struct symbol_table * next;
}symbol_table;

typedef struct table_stack {
	symbol_table * now;
	struct table_stack * next;
}table_stack;

typedef struct variable_list {
	char * name;
	int type;
	int array_dimension;
	array_type * array;
	int val;
	double dval;
	char * st; 
	int init;
	struct variable_list * next;
}variable_list;

symbol_table * global;
table_stack * head;
table_stack * top;
int level = 0;
int const_type_deliver = 0;
int var_decl_type_deliver = 0;
symbol_table_attributes * parameters;
variable_list * variables;
variable_list * call_func_variables;
array_type * array_head;
int array_dim = 0;
int id_array_dim = 0;
int call_array_dim = 0;
int func_array_dim = 0;
int count = 0;
int return_type = -1;
int return_last = 0;
int loop = 0;

int first_func = 0;
variable_list * global_va_list;
int global_init_num = 0;
int print_bool_num = 0;
int main_func = 0;
int return_stm = 0;
FILE * output;
int stack_pointer = 0;
int condition_num = 0;
int loop_num = 0;
int compare_num = 0;
typedef struct con_stack{
	int element;
	struct con_stack * next;
}con_stack;
con_stack * con_stack_top;
con_stack * con_stack_now;
con_stack * loop_stack_top;
con_stack * loop_stack_now;
con_stack * com_stack_top;
con_stack * com_stack_top;



variable_list * to_global_init_list_bottom()
{
	variable_list * temp = global_va_list;
	if (temp == NULL) return NULL;
	while (temp->next) temp = temp->next;
	return temp;	
}

variable_list * add_variable_to_global_init_list(char * name, int type, int integer, float floating, char * st)
{
	variable_list * temp = malloc(sizeof(variable_list));
	temp->name = malloc(sizeof(char) * strlen(name));
	strcpy(temp->name, name);
	temp->type = type;	
	temp->val = integer;
	temp->dval = floating;		
	if (st != NULL) {
		temp->st = malloc(strlen(st) * sizeof(char));
		strcpy(temp->st,st);
	}
	else temp->st = NULL;		
	temp->next = NULL;
	return temp;
}

void loop_stack_push(int num)
{
	if (loop_stack_now == NULL) {
		loop_stack_now = malloc(sizeof(con_stack));
		loop_stack_now->element = num;
		loop_stack_now->next = NULL;
		loop_stack_top = loop_stack_now;
	}
	else {
		loop_stack_now->next = malloc(sizeof(con_stack));
		loop_stack_now = loop_stack_now->next;
		loop_stack_now->element = num;
		loop_stack_now->next = NULL;
	}
}

int loop_stack_pop()
{
	if (loop_stack_now == NULL) return -1;
	else {
		if (loop_stack_now == loop_stack_top) {
			int t = loop_stack_now->element;
			free(loop_stack_now);
			loop_stack_now = NULL;
			loop_stack_top = NULL;
			return t;
		}
		con_stack * temp = loop_stack_top;
		while (temp->next != loop_stack_now && temp == NULL) temp = temp->next;
		if (temp == NULL) return -1;		
		int t = loop_stack_now->element;
		free(loop_stack_now);
		loop_stack_now = temp;
		return t;
	}
}

void con_stack_push(int num)
{
	if (con_stack_now == NULL) {
		con_stack_now = malloc(sizeof(con_stack));
		con_stack_now->element = num;
		con_stack_now->next = NULL;
		con_stack_top = con_stack_now;
	}
	else {
		con_stack_now->next = malloc(sizeof(con_stack));
		con_stack_now = con_stack_now->next;
		con_stack_now->element = num;
		con_stack_now->next = NULL;
	}
}

int con_stack_pop()
{
	if (con_stack_now == NULL) return -1;
	else {
		if (con_stack_now == con_stack_top) {
			int t = con_stack_now->element;
			free(con_stack_now);
			con_stack_now = NULL;
			con_stack_top = NULL;
			return t;
		}
		con_stack * temp = con_stack_top;
		while (temp->next != con_stack_now && temp == NULL) temp = temp->next;
		if (temp == NULL) return -1;		
		int t = con_stack_now->element;
		free(con_stack_now);
		con_stack_now = temp;
		return t;
	}
}

void calculating(int type, int operand)
{
	if (operand == 0) {
		if (type == 0) fprintf(output,"\tiadd\n");
		else if (type == 1 || type == 2) fprintf(output,"\tfadd\n"); 
	}
	else if (operand == 1) {
		if (type == 0) fprintf(output,"\tisub\n");
		else if (type == 2 || type == 1) fprintf(output,"\tfsub\n");
	}
	else if (operand == 2) {
		if (type == 0) fprintf(output,"\timul\n");
		else if (type == 1 || type == 2) fprintf(output,"\tfmul\n");
	}
	else if (operand == 3) {
		if (type == 0) fprintf(output,"\tidiv\n");
		else if (type == 1 || type == 2) fprintf(output,"\tfdiv\n");
	}
	else if (operand == 4) {
		if (type == 0) fprintf(output,"\tirem\n");
	}
}

void fprintf_type(int t)
{
	if (t == 0) fprintf(output,"I");
	else if (t == 1) fprintf(output,"F");
	else if (t == 2) fprintf(output,"D");
	else if (t == 3) fprintf(output,"Ljava/lang/String;");
	else if (t == 4) fprintf(output,"Z");	
}

void print_error_msg(char* msg)
{
	printf("##########Error at Line %d: ",linenum);
	printf("%s##########\n",msg);
}

void print_function_not_defined_error(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' is a function which is not defined##########\n",name);
}

void print_call_not_boolean_error(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' is not boolean type##########\n",name);
}


void print_array_index_error_msg(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' 's  index should be integer type##########\n",name);
}

void print_redeclared_msg(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' redeclared##########\n",name);
}

void print_ini_error_msg(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' initial type not match##########\n",name);
}

void print_undeclared_error_msg(char * name)
{
	printf("##########Error at Line %d: ",linenum);
	printf("'%s' has not declared##########\n",name);
}

void check_function_def()
{
	symbol_table * now = top->now;
	while (now) {
		if (strcmp(now->kind,"function") == 0 ) {
			if (now->func_def_bit == 0) print_function_not_defined_error(now->name);
		}
		now = now->next;
	}
}

void check_return_type(int type)
{
	if (return_type == 5) print_error_msg("function is void type");
	if (type > 5) type -= 6;
	else if (type != return_type) {
		if (return_type == 2) {
			if (type != 0 && type != 1 && type != 2) print_error_msg("should return double type");
		}
		else if (return_type == 1) {
			if (type != 0 && type != 1) print_error_msg("should return floating type");
		}
		else if (return_type == 0) {
			if (type != 0) print_error_msg("should return integer type");
		}
		else if (return_type == 3) print_error_msg("should return string type");
		else if (return_type == 4) {
			if (type != 0) print_error_msg("should return boolean type");
		}
	}
}

variable_list * add_to_call_func_pa(int type, int arr_dim)
{
	if (call_func_variables == NULL) {
		call_func_variables = malloc(sizeof(variable_list));
		call_func_variables->type = type;
		call_func_variables->array_dimension = arr_dim;
		return call_func_variables;
	}
	else {
		variable_list * v_list = call_func_variables;
		while (v_list->next) v_list = v_list->next;
		v_list->next = malloc(sizeof(variable_list));
		v_list->next->type = type;
		v_list->next->array_dimension = arr_dim;
		return v_list->next;
	}
}

int get_array_dimension(char * name)
{
	table_stack * trace_symbol_table = head;
	if (head == NULL) return -1;
	else {
		symbol_table * find_entry = trace_symbol_table->now;
		while (trace_symbol_table) {
			while (find_entry) {
				if (strcmp(name, find_entry->name) == 0) {
					if (strcmp(find_entry->kind,"function") == 0) return -1;
					else if (strcmp(find_entry->kind,"constant") == 0) return -1;
					return find_entry->array_dimension;
				}
				find_entry = find_entry->next;
			}
			trace_symbol_table = trace_symbol_table->next;
			if (trace_symbol_table == NULL) break;
			find_entry = trace_symbol_table->now;
		}
		return -1;
	}
}

int check_exprs_con_exprs_type(int type1, int type2)
{
	if (type1 > 5) type1 -= 6;
	if (type2 > 5) type2 -= 6;
	if (type1 == type2) return 1;
	else {
		if (type1 == 2 || type1 == 1 || type1 == 0)
			if (type2 == 2 || type2 == 1 || type2 == 0)
				return 1;
		return 0;
	}
}

//1:match 0:not match
int check_assign_type(int type1, int type2)
{
	if (type1 == type2) return 1;
	else if (type1 == 1 || type1 ==2){
		if ( type2 == 1 || type2 == 0)
			return 1;
		return 0;
	}
	else if (type1 ==2) {
		if (type2 == 2 || type2 == 1 || type2 == 0)
			return 1;
		return 0;
	}
	else return 0;
}

//1:match 0:not match
int check_exprs_type(int type1, int type2)
{
	if (type1 > 5) type1 -= 6;
	if (type2 > 5) type2 -= 6;	
	if (type1 == type2) return 1;
	else {
		if (type1 == 2 || type1 == 1 || type1 == 0)
			if (type2 == 2 || type2 == 1 || type2 == 0)
				return 1;
		return 0;
	}
}

/*----------------------------------------------------------------------------------------------*/
int check_call_funct_type(char * name) 
{
	table_stack * trace_symbol_table = head;
	if (head == NULL) {
		print_undeclared_error_msg(name);
		return -1;
	}
	else {
		symbol_table * find_entry = trace_symbol_table->now;
		while (trace_symbol_table) {
			while (find_entry) {
				if (strcmp(name, find_entry->name) == 0) {
					if (strcmp(find_entry->kind,"function") == 0) {
						symbol_table_attributes * s = find_entry->attribute;
						variable_list * v = call_func_variables;
						while (s != NULL) {
							if (v == NULL) {
								print_error_msg("number of parameters don't match");
								return -1;
							}
							if (s->array_dimension != v->array_dimension) {
								print_error_msg("parameters' type doesn't match");
								return -1; 
							}
							s = s->next;
							v = v->next;
						}
						if (v != NULL) {
							print_error_msg("number of parameters don't match");
							return -1;
						}
						fprintf(output,"\tinvokestatic test/%s(",find_entry->name);												
						s = find_entry->attribute;
						while (s != NULL) {
							fprintf_type(s->variable_type);
							s = s->next;
						}
						fprintf(output,")");
						if (find_entry->type == 5) fprintf(output,"V");
						else fprintf_type(find_entry->type);
						fprintf(output,"\n");
						return find_entry->type;
					}
					print_redeclared_msg(name);
					return -1;
				}
				find_entry = find_entry->next;
			}			
			trace_symbol_table = trace_symbol_table->next;
			if (trace_symbol_table == NULL) break;
			find_entry = trace_symbol_table->now;
		}
		print_undeclared_error_msg(name);
		return -1;
	}
}


int get_ID_type(char * name) 
{
	table_stack * trace_symbol_table = head;
	if (head == NULL) {
		print_undeclared_error_msg(name);
		return -1;
	}
	else {
		symbol_table * find_entry = trace_symbol_table->now;
		while (trace_symbol_table) {
			while (find_entry) {
				if (strcmp(name, find_entry->name) == 0) {
					if (strcmp(find_entry->kind,"function") == 0) {
						print_redeclared_msg(name);
						return -1;
					}
					else if (strcmp(find_entry->kind,"constant") == 0) return find_entry->type + 6;
					return find_entry->type;
				}
				find_entry = find_entry->next;
			}
			trace_symbol_table = trace_symbol_table->next;
			if (trace_symbol_table == NULL) break;
			find_entry = trace_symbol_table->now;
		}
		print_undeclared_error_msg(name);
		return -1;
	}
}


int check_type(int t1, int t2)
{
	if (t1 != t2) {
		if (t1 == 1) {
			if (t1 > 1) return 0;
		}
		else if(t1 == 2) {
			if (t2 > 2) return 0;
		}
		else return 0;
	}
	return 1;
}

variable_list * to_variable_list_bottom()
{
	variable_list * v_list = variables;
	if (v_list == NULL) return NULL;
	while (v_list->next) v_list = v_list->next;
	return v_list;
}

array_type * to_the_array_bottom()
{
	if (array_head == NULL) return NULL;
	else {
		array_type * temp = array_head;
		while (temp->next) temp = temp->next;
		return temp;
	}
}

array_type * add_dimension(int elements)
{
	array_dim ++;
	array_type * temp = malloc(sizeof(array_type));
	temp->elements = elements;
	temp->next = NULL;
	return temp;
}


//check if the name is already in the symbol table, return the entry if it is found, else return NULL
symbol_table * check_symbol_table(char * name)
{
	int i = 0;
	table_stack * temp_now = head;
	if (temp_now == NULL) return NULL;
	symbol_table * temp;
	while (i <= level) {
		temp = temp_now->now;
		while (temp) {
			if(strcmp(temp->name, name) == 0) return temp;
			temp = temp->next;
		}
		temp_now = temp_now->next;
		i++;
	}
	return NULL;
}

//free attribute's memory
void free_symbol_table_attributes(symbol_table_attributes * a)
{
	symbol_table_attributes * temp = a;
	while (a) {
		a = a->next;
		free(temp->variable_name);
		free(temp->const_string);
		free(temp);
		temp = a;
	}
}

//check if parameters is equal to attributes, if equal return 1, else 0
int check_func_attribute(symbol_table * s)
{
	if (s == NULL) return 0;
	symbol_table_attributes * p = parameters;
	symbol_table_attributes * q = s->attribute;
	if (q == NULL) {
		if (p == NULL) return 1;
		return 0;
	}
	while (p) {
		if (p->variable_type != q->variable_type) {
			free_symbol_table_attributes(parameters);
			return 0;
		}
		p = p->next;
		q = q->next;
	}
	//free_symbol_table_attributes(parameters);
	return 1;
}

variable_list * add_variable_to_list(char * name, int array_or_not, int type, int init, int integer, float floating, char * st)
{
	variable_list * temp = malloc(sizeof(variable_list));
	temp->name = malloc(sizeof(char) * strlen(name));
	strcpy(temp->name, name);
	temp->type = type;
	if (array_or_not == 1) {
		temp->array = array_head;
		temp->array_dimension = array_dim;
		array_dim = 0;		
		array_head = NULL;
	}
	else {
		if (init == 1) {
			temp->init = 1;
			temp->val = integer;
			temp->dval = floating;		
			if (st != NULL) {
				temp->st = malloc(strlen(st) * sizeof(char));
				strcpy(temp->st,st);
			}
			else temp->st = NULL;
		}
		else temp->init = 0;
		temp->array = NULL;
		temp->array_dimension = 0;
		array_dim = 0;		
		array_head = NULL;
	}
	temp->next = NULL;
	return temp;
}

void free_variable_list()
{
	variable_list * temp = variables;
	while (variables) {
		temp = variables;
		variables = variables->next;
		free(temp->name);
		//free(temp->array);
		free(temp);
	}
	variables = NULL;
}

symbol_table_attributes * add_parameters(int type, char * name, int arr_dim)
{
	symbol_table_attributes * temp = malloc(sizeof(symbol_table_attributes));
	temp->variable_name = malloc(sizeof(char) * strlen(name));
	strcpy(temp->variable_name,name);
	temp->variable_type = type;	
	temp->array_dimension = arr_dim;
	if (arr_dim != 0) {
		array_dim = 0;
		temp->array = array_head;
		array_head = NULL;
	}
	return temp;
}

void add_parameters_to_entry(symbol_table * s, char * ID)
{
	symbol_table * temp = s;
	if (temp == NULL) {
		free_symbol_table_attributes(parameters);
		parameters = NULL;
		return;
	}
	if (parameters == NULL) temp->attribute = NULL; 
	else temp->attribute = parameters;
	parameters = NULL;
}

void print_type(int type)
{
	switch (type) {	
		case 0: 
			printf("int");
			break;
		case 1: 
			printf("float");
			break;
		case 2: 
			printf("double");
			break;
		case 3: 
			printf("string");
			break;
		case 4: 
			printf("bool");
			break;
		case 5: 
			printf("void");
			break;	
	}
}

void print_attribute_type(int type, array_type * ar)
{
	print_type(type);
	while (ar != NULL) {
		printf("[%d]",ar->elements);
		ar = ar->next;
	}
}

symbol_table * insert(char * name, char * kind, int Level, int type, int array_dimension, array_type * Array)
{
	symbol_table * q;
	q = malloc(sizeof(symbol_table));;
	
	q->name = malloc(sizeof(char) * strlen(name));
	strcpy(q->name, name);

	q->kind = malloc(sizeof(char) * strlen(kind));
	strcpy(q->kind, kind);
	q->level = Level;
	q->type = type;
	q->next = NULL;
	q->array_dimension = array_dimension;
	if (array_dimension != 0) {
		q->array = Array;
	}
	if (level != 0) {
		q->location = stack_pointer;
		stack_pointer++;
	}
	return q;
}

void free_symbol_table(symbol_table * s)
{
	symbol_table * temp = s;
	while (s) {
		s = s->next;
		free(temp->name);
		free(temp->kind);
		free_symbol_table_attributes(temp->attribute);
		free(temp);
		temp = s;
	}
}

table_stack * push()
{
	level++;
	table_stack * temp = malloc(sizeof(table_stack));
	temp->now = NULL;
	return temp;
}

void pop()
{
	level--;
	table_stack * temp;
	temp = head;
	
	while (temp->next != top) temp = temp->next;
	free_symbol_table(top->now);
	temp->next = NULL;
	free(top);
	top = temp;
}

void add_value_to_const(symbol_table * s, char* name, int integer, double floating, char * string )
{
	symbol_table * t = s;
	while (t) {
		if (strcmp(t->name, name) == 0) {
			if (strcmp(t->kind, "constant") != 0) return;
			break;
		}
		t = t->next;
	}
	if (t == NULL) return;
	t->attribute = malloc(sizeof(symbol_table_attributes));
	switch(t->type) {
		case 0: 
			t->attribute->const_integer = integer;
			break;
		case 1:
			t->attribute->const_floating = floating;
			break;
		case 2:
			t->attribute->const_floating = floating;
			break;	
		case 3:
			t->attribute->const_string = malloc(sizeof(char) * strlen(string));
			strcpy(t->attribute->const_string, string);
			break;
		case 4:
			t->attribute->const_integer = integer;
			break;
	}
	
}

void add_attributes_to_symbol_table(symbol_table * source)
{
	top->next=push(); 
	top=top->next; 
	top->next = NULL;
	if (source == NULL) return;
	if (source->attribute != NULL) {
		symbol_table_attributes * temp = source->attribute;
		top->now = insert(temp->variable_name, "parameter", level, temp->variable_type, temp->array_dimension, temp->array);		
		temp = temp->next;
		symbol_table * s = top->now;
		fprintf_type(s->type);
		while(temp) {
			s->next = insert(temp->variable_name,"parameter",level,temp->variable_type, temp->array_dimension, temp->array);
			s = s->next;
			fprintf_type(s->type);
			temp = temp->next;
		}
	}
}

void print_const_element_value(symbol_table_attributes * t,int type)
{
	switch(type) {
		case 0: 
			printf("%d",t->const_integer);
			break;
		case 1: 
			printf("%f",t->const_floating);
			break;
		case 2: 
			printf("%lf",t->const_floating);
			break;
		case 3: 
			printf("%s",t->const_string);
			break;
		case 4:
			if (t->const_integer == 0) printf("false");
			else printf("true");
			break;
	}
}

void print_symbol_table(symbol_table *s)
{
	if (Opt_Symbol == 0) return;
	if (s == NULL) return;
	symbol_table *t = s;
	printf("Name                             Kind       Level       Type           Attribute\n");
	printf("--------------------------------------------------------------------------------\n");
	while (t!=NULL) {
		printf("%-32s %-11s",t->name, t->kind);
		printf("%d", t->level);
		if (t->level == 0) printf("(global)\t");
		else printf("(local)\t");
		print_type(t->type);
		
		int space;
		switch(t->type) {
			case 0: 
				space = 12;
				break;
			case 1: 
				space = 10;
				break;
			case 2: 
				space = 9;
				break;
			case 3: 
				space = 9;
				break;
			case 4: 
				space = 11;
				break;
			case 5: 
				space = 11;
				break;
		}
		
		
		if (t->array_dimension != 0) {
			int i = t->array_dimension;
			array_type * get_element = t->array;			
			while (i > 0) {
				if (get_element->elements > 999) space -= 6;
				else if (get_element->elements > 99) space -= 5; 
				else if (get_element->elements > 9) space -= 4;
				else space -= 3;
				printf("[%d]",get_element->elements);
				i--;
				get_element = get_element->next;
			}
			if (space > 0) {
				for (;space > 0; space--) printf(" ");
			}
			else printf("  ");
		}
		else {
			for (;space > 0;space --) printf(" ");
		}
		if (strcmp(t->kind, "constant") == 0) {
			int i;
			if (t->array_dimension != 0) {
				int total_elements = 1;
				array_type * trace_array = t->array;
				while (trace_array) {
					total_elements *= trace_array->elements;
					trace_array = trace_array->next;
				}
				i = total_elements - 1;
			}
			else i = 0;
			print_const_element_value(t->attribute, t->type);						
		}
		else if (strcmp(t->kind, "function") == 0) {
			symbol_table_attributes *p = t->attribute;
			if (p) {
				if (p->variable_type > 5) {
					printf("const ");
					print_type(p->variable_type - 6);
				}
				else print_attribute_type(p->variable_type, p->array);
				p = p->next;
			}
			while (p) {
				printf(",");
				if (p->variable_type > 5) {
					printf("const ");
					print_type(p->variable_type - 6);
				}
				else print_attribute_type(p->variable_type, p->array);
				p = p->next;
			}
		}		
		printf("\n");
		t = t->next;
	}
	printf("--------------------------------------------------------------------------------\n");
	printf("\n");
}
%}

%union {
	int type; // 0:int 1:float 2:double 3:string 4:bool 5:void (+6:const)
	char* text;
	struct {
		int type; 
		char* text;
		int val;
		double dval;		
	}value;
}

%token <value> integer SCARLAR_BOOLEAN 
%token <value> floating
%token <value> sentence


%token OPEN_PARENTHESIS	CLOSE_PARENTHESIS 	// ()
%token OPEN_BRACKET	CLOSE_BRACKET	 		// []
%token OPEN_BRACE CLOSE_BRACE 				// {}
%token COMMA SEMICOLON

%token WHILE DO FOR	CONDITION_IF CONDITION_ELSE READ PRINT RETURN BREAK CONTINUE
%token <type> VOID INT BOOL FLOAT DOUBLE STRING CONST

%right ASSIGN
%left AND
%left OR
%left NOT
%left EQUAL NOTEQUAL
%left LESSOREQUAL LARGEOREQUAL LARGE LESS 
%left PLUS MINUS
%left MULTI DIVIDE MOD
 

%token <text> ID
%type <value> assign_value identifier
%type <text> array_decl
%type <text> func_augment decl_argument decl_arguments
%type <type> const_list const_assign return_value operand_PLUS_MINUS operand_MULTI_DIV_MOD
%type <type> num expression expressions type call_funct array_decl_brackets  array_brackets
%type <type> identifier_assign  array_decl_values check_array_decl_values expressions_multi_divide
%type <type> boolexpression boolexpressions print_augment con_operand logicaloperand con_boolexpression
/*
	PLUS   0
	MINUS  1
	MULTI  2
	DIVIDE 3
	MOD    4
	AND    5
	OR     6	
*/
%%

program : push_global_symbol_table_into_stack 
	;

push_global_symbol_table_into_stack	:	{
											top = malloc(sizeof(table_stack));
											output = fopen("test.j","w");
											fprintf(output,".class public test\n");
											fprintf(output,".super java/lang/Object\n");
											fprintf(output,".field public static _sc Ljava/util/Scanner;\n");
										} decl_and_def_list_count {check_function_def(); print_symbol_table(global);fclose(output);}
									;
	
decl_and_def_list_count	: /*one definition*/  decl_list_and_one_def  
											| decl_list_and_one_def decl_list
			/*more than one definition*/	| decl_list_and_one_def more_def 
											| decl_list_and_one_def more_def decl_list
											;

more_def 	: more_def decl_list_and_one_def
			| decl_list_and_one_def
			;
											
decl_list_and_one_def	: decl_list funct_def 
						| funct_def
						;

decl_list	: decl_list declaration
			| declaration
			;
				
declaration : const_decl
            | var_decl
            | funct_decl
			;

compound	: OPEN_BRACE {top->next=push(); top=top->next; top->next = NULL;} statements CLOSE_BRACE {print_symbol_table(top->now);pop();}
			| OPEN_BRACE CLOSE_BRACE
			;				 
			 
//{-------------const declaration-------------------------------				  
const_decl	: CONST type {const_type_deliver = $2;} const_list SEMICOLON
			;
			
const_list	: const_list COMMA const_assign
			| const_assign 
			;			
			
const_assign	: ID ASSIGN integer 
					{ 
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver != 0) print_error_msg("wrong type");
						else {
							if (global == NULL) {
								global = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(global, $1, $3.val, 0, NULL);
								top->now = global;
								head = top;
							}
							else {
								symbol_table * temp = top->now;
								while (temp ->next != NULL) temp = temp->next;
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);								
								add_value_to_const(top->now, $1, $3.val, 0, NULL);
							}
						}
					}
				| ID ASSIGN floating 
					{
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver > 2) print_error_msg("wrong type");
						else {
							if (global == NULL) {
								global = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(global, $1, 0, $3.dval, NULL);
								top->now = global;
								head = top;
							}
							else {
								symbol_table * temp = top->now;							
								while (temp ->next != NULL) temp = temp->next;	
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(top->now, $1, 0, $3.dval, NULL);						
							}
						}
					}
				| ID ASSIGN MINUS integer 
					{
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver != 0) print_error_msg("wrong type");
						else {
							if (global == NULL) {
								global = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(global, $1, -$4.val, 0, NULL);
								top->now = global;
								head = top;
							}
							else {
								symbol_table * temp = top->now;
								while (temp ->next != NULL) temp = temp->next;
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(top->now, $1, -$4.val, 0, NULL);
							}
						}
					}
				| ID ASSIGN MINUS floating
					{
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver > 2) print_error_msg("wrong type");
						else {
							if (global == NULL) {
								global = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(global, $1, 0, -$4.dval, NULL);
								top->now = global;
								head = top;
							}
							else {
								symbol_table * temp = top->now;
								while (temp ->next != NULL) temp = temp->next;
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(top->now, $1, 0, -$4.dval, NULL);
							}
						}
					}
				| ID ASSIGN SCARLAR_BOOLEAN
					{
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver != 4) print_error_msg("wrong type");
						else {
							if (global == NULL) {
								global = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(global, $1, $3.val, 0, NULL);
								top->now = global;
								head = top;
							}
							else {
								symbol_table * temp = top->now;
								while (temp ->next != NULL) temp = temp->next;
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(top->now, $1, $3.val, 0, NULL);
							}
						}
					}
				| ID ASSIGN sentence
					{
						if (check_symbol_table($1) != NULL) print_error_msg("redeclared");
						else if (const_type_deliver != 3) print_error_msg("wrong type");
						else {
							if (global == NULL) {
							global = insert($1, "constant", level, const_type_deliver, 0, NULL);
							add_value_to_const(global, $1, 0, 0, $3.text);
							top->now = global;
							head = top;
							}
							else {
								symbol_table * temp = top->now;
								while (temp ->next != NULL) temp = temp->next;
								temp->next = insert($1, "constant", level, const_type_deliver, 0, NULL);
								add_value_to_const(top->now, $1, 0, 0, $3.text);
							}
						}
					}
				;
				
type : INT
	 | FLOAT
	 | DOUBLE
	 | STRING
	 | BOOL
     ; 
//}					
//{----------variables declaration----------------------------------
var_decl	: type identifier_list SEMICOLON 	
				{
					
					variable_list * v_list = variables;
					symbol_table * s_list = top->now;
					if (s_list) while (s_list->next) s_list = s_list->next;
					while (v_list) {
						if (v_list->type != 5) {
							if (v_list->type == -1) {
								v_list = v_list->next;
								continue;
							}
							else if (check_assign_type($1, v_list->type) == 0) {
								print_ini_error_msg(v_list->name);;
							}
							v_list = v_list->next;
							continue;
						}
						symbol_table * check = check_symbol_table(v_list->name);
						if (check != NULL) print_redeclared_msg(v_list->name);
						else {
							if (level == 0) {
								fprintf(output,".field public static %s ", v_list->name);
								fprintf_type($1);
								fprintf(output,"\n");								
							}
							if (s_list == NULL) {
								if (v_list->array_dimension != 0) top->now = insert(v_list->name, "variable", level, $1, v_list->array_dimension, v_list->array);
								else {
									top->now = insert(v_list->name, "variable", level, $1, 0, NULL);
									if (v_list->init != 0) {
										if (level != 0) {
											if (top->now->type == 0) {
												fprintf(output,"\tldc %d\n",v_list->val);
												fprintf(output,"\tistore %d\n",top->now->location);
											}
											else if (top->now->type == 1 || top->now->type == 2) {
												fprintf(output,"\tldc %f\n",v_list->dval);
												fprintf(output,"\tfstore %d\n",top->now->location);
											}
											else if (top->now->type == 4) {
												if (v_list->val == 0) {
													fprintf(output,"\ticonst_0\n");
													fprintf(output,"\tistore %d\n",top->now->location);
												}
												else if (v_list->val == 1) {
													fprintf(output,"\ticonst_1\n");
													fprintf(output,"\tistore %d\n",top->now->location);
												}
											}
										}
										else {
											global_init_num = 1;
											variable_list * gtemp = to_global_init_list_bottom();
											if (gtemp == NULL) global_va_list = add_variable_to_global_init_list(v_list->name,$1, v_list->val, v_list->dval, v_list->st);
											else gtemp->next = add_variable_to_global_init_list(v_list->name,$1, v_list->val, v_list->dval, v_list->st);
										}
									}
								}
								if (level == 0) {
									global = top->now;
									head = top;
								}
								s_list = top->now;
							}
							else {
								if (v_list->array_dimension != 0) s_list->next = insert(v_list->name, "variable", level, $1, v_list->array_dimension, v_list->array);
								else s_list->next = insert(v_list->name, "variable", level, $1, 0, NULL);
								s_list = s_list->next;
								if (v_list->init != 0) {
									if (level != 0) {
										if (s_list->type == 0) {
											fprintf(output,"\tldc %d\n",v_list->val);
											fprintf(output,"\tistore %d\n",s_list->location);
										}
										else if (s_list->type == 1 || s_list->type == 2) {
											fprintf(output,"\tldc %f\n",v_list->dval);
											fprintf(output,"\tfstore %d\n",s_list->location);
										}
										else if (s_list->type == 4) {
											if (v_list->val == 0) {
												fprintf(output,"\ticonst_0\n");
												fprintf(output,"\tistore %d\n",s_list->location);
											}
											else if (v_list->val == 1) {
												fprintf(output,"\ticonst_1\n");
												fprintf(output,"\tistore %d\n",s_list->location);
											}
										}
									}
									else {
										global_init_num = 1;
										variable_list * gtemp = to_global_init_list_bottom();
										if (gtemp == NULL) global_va_list = add_variable_to_global_init_list(v_list->name,$1, v_list->val, v_list->dval, v_list->st);
										else gtemp->next = add_variable_to_global_init_list(v_list->name,$1, v_list->val, v_list->dval, v_list->st);
									}
								}
							}
						}
						v_list = v_list->next;	
					}
					//free_variable_list();
					variables = NULL;
				}
			;	
					
identifier_list	: identifier_list COMMA ID	
					{
						if (variables == NULL) variables = add_variable_to_list($3, 0, 5,0,0,0,0);
						else {
							variable_list * temp = variables;
							while (temp->next) temp = temp->next;
							temp->next = add_variable_to_list($3, 0, 5,0,0,0,0);
						}
					} 
				| identifier_list COMMA array_decl
				| identifier_list COMMA array_decl_assign
				| identifier_list COMMA identifier_assign
				| ID	
					{
						if (variables == NULL) variables = add_variable_to_list($1, 0, 5,0,0,0,0);
						else {
							variable_list * temp = variables;
							while (temp->next) temp = temp->next;
							temp->next = add_variable_to_list($1, 0, 5,0,0,0,0);
						}
					}	
				| array_decl
				| array_decl_assign				
				| identifier_assign
				;	

array_decl	: ID array_decl_brackets 
				{
					if (variables == NULL) variables = add_variable_to_list($1, 1, 5,0,0,0,0);
					else {
						variable_list * temp = variables;
						while (temp->next) temp = temp->next;
						temp->next = add_variable_to_list($1, 1, 5,0,0,0,0);
					}
				}
			;				

array_decl_brackets	: array_decl_brackets OPEN_BRACKET integer CLOSE_BRACKET 
					{
						array_type * temp = to_the_array_bottom();
						if (temp == NULL) array_head = add_dimension($3.val);
						else temp->next = add_dimension($3.val);
					}
				| OPEN_BRACKET integer CLOSE_BRACKET 
					{
						array_type * temp = to_the_array_bottom();
						if (temp == NULL) array_head = add_dimension($2.val);
						else temp->next = add_dimension($2.val);
					}
				;
			
identifier_assign	: ID ASSIGN assign_value
						{
							if (variables == NULL) variables = add_variable_to_list($1, 0, 5,1,$3.val,$3.dval,$3.text);
							else {
								variable_list * temp = variables;
								while (temp->next) temp = temp->next;
								temp->next = add_variable_to_list($1, 0, 5,1,$3.val,$3.dval,$3.text);
							}
						} 						
					;

array_decl_assign	: array_decl ASSIGN OPEN_BRACE check_array_decl_values CLOSE_BRACE 
						{
							array_type * check = array_head;
							int arrdim = array_dim;
							int total_elements = 1;
							for (;arrdim > 0; arrdim--) {
								total_elements *= check->elements;
								check = check->next;
							}
							if (count > total_elements) {
								print_error_msg("too many values to initialize");
							}
							else {
								if (variables == NULL) variables = add_variable_to_list($1, 1, $4,0,0,0,0);
								else {
									variable_list * temp = variables;
									while (temp->next) temp = temp->next;
									temp->next = add_variable_to_list($1, 1, $4,0,0,0,0);
								}
							}
							array_head = NULL;
							array_dim = 0;
							count = 0;
						}
					;

check_array_decl_values	: array_decl_values 
							{
								if ($1 == -1) $$ = -1;
								else $$ = $1;
							}
						| {$$ = 5;}
						;
						
array_decl_values	: array_decl_values COMMA assign_value 
						{
							if ($3.type == -1) $$ = -1;
							else if ($3.type - 6 > $$) $$ = $3.type - 5;
							else if ($3.type > $$) $$ = $3.type;
							count ++;
						}
					| assign_value 
						{
							if ($1.type == -1) $$ = -1;
							else if ($1.type - 6 > $$) $$ = $1.type - 5;
							else if ($1.type > $$) $$ = $1.type;
							count ++;
						}
					;

assign_value	: integer 
					{
						$$.type = 0;
						$$.val = $1.val;
						$$.dval = 0;
						$$.text = NULL;
					}
				| floating
					{
						$$.type = 1;
						$$.val =  0;
						$$.dval = $1.dval;
						$$.text = NULL;
					}
				| SCARLAR_BOOLEAN
					{
						$$.type = 4;
						$$.val = $1.val;
						$$.dval = 0;
						$$.text = NULL;
					}
				| sentence 
					{
						$$.type = 3;
						$$.val = 0;
						$$.dval = 0;
						$$.text = malloc(strlen($1.text) * sizeof(char));
						strcpy($$.text,$1.text);
					}
//}	
//{------------fuctions declaration and definition---------------------------------------	
funct_def	: type ID decl_argument_list 
				{
					if (first_func == 0) {
						first_func = 1;
						if (global_init_num != 0) {
							variable_list * v_list = global_va_list;
							if (!v_list) printf("fuck!\n");
							v_list = global_va_list;
							fprintf(output,".method public static globla_init()V\n");
							fprintf(output,".limit stack 100\n");
							fprintf(output,".limit locals 100\n");
							while (v_list) {								
								if (v_list->type == 0) {
									fprintf(output,"\tldc %d\n",v_list->val);
									}
								else if (v_list->type == 1 || v_list->type == 2) {
									fprintf(output,"\tldc %f\n",v_list->dval);
								}
								else if (v_list->type == 4) {
									if (v_list->val == 0) {
										fprintf(output,"\ticonst_0\n");
									}
									else if (v_list->val == 1) {
										fprintf(output,"\ticonst_1\n");
									}
								}
								fprintf(output,"\tputstatic test/%s ",v_list->name);
								fprintf_type(v_list->type);
								fprintf(output,"\n");
								v_list = v_list->next;
							}
							fprintf(output,"\treturn\n");
							fprintf(output,".end method\n");
							global_init_num++;
						}
					}
					if (strcmp($2,"main") == 0) stack_pointer = 1;
					else stack_pointer = 0;
					return_type = $1;
					if (strcmp($2, "main") == 0) {
						main_func = 1;
						fprintf(output,".method public static main([Ljava/lang/String;)V\n");												
						fprintf(output,".limit stack 100\n");
						fprintf(output,".limit locals 100\n");
						fprintf(output,"\tnew java/util/Scanner\n");
						fprintf(output,"\tdup\n");
						fprintf(output,"\tgetstatic java/lang/System/in Ljava/io/InputStream;\n");
						fprintf(output,"\tinvokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
						fprintf(output,"\tputstatic test/_sc Ljava/util/Scanner;\n");
						if (global_init_num != 0) fprintf(output,"\tinvokestatic test/globla_init()V\n");
					}
					else fprintf(output,".method public static %s(",$2);
					symbol_table * t = check_symbol_table($2);
					if (t != NULL) {
						if (t->func_def_bit == 1) {
							add_attributes_to_symbol_table(NULL);
							print_error_msg("name of this function was defined already");
						}
						else {
							if (strcmp(t->kind, "function") != 0) print_error_msg("name of this function was declared and not a function");							
							if (check_func_attribute(t) == 0) {
								print_error_msg("parameters of definition and declaration are not match");
								add_attributes_to_symbol_table(NULL);								
							}
							else if (t->type != $1) {
								print_error_msg("declaration and definition have different return typr");
								add_attributes_to_symbol_table(NULL);
							}
							else {
								t->func_def_bit = 1;
								add_attributes_to_symbol_table(t);
							}
						}
					}
					else {
						if (global == NULL) {
							global = insert($2, "function", level, $1, 0, NULL);
							global->func_def_bit = 1;													
							top->now = global;
							add_parameters_to_entry(top->now, $2);
							head = top;
							add_attributes_to_symbol_table(global);
						}
						else {													
							symbol_table * temp = top->now;
							while (temp->next != NULL) temp = temp->next;
							temp->next = insert($2, "function", level, $1, 0, NULL);
							temp->next->func_def_bit = 1;
							add_parameters_to_entry(temp->next, $2);													
							add_attributes_to_symbol_table(temp->next);
						}
					}
					if (strcmp($2, "main") != 0) {
						fprintf(output,")");
						fprintf_type($1);
						fprintf(output,"\n");
						fprintf(output,".limit stack 100\n");
						fprintf(output,".limit locals 100\n");
					}
					parameters = NULL;					
				} func_compound 
					{
						if (main_func == 1) {
							main_func = 0;
						}
						fprintf(output,".end method\n");
					}
			| VOID ID decl_argument_list 
				{
					if (first_func == 0) {
						first_func = 1;
						if (global_init_num != 0) {
							variable_list * v_list = global_va_list;
							fprintf(output,".method public static globla_init()V\n");
							fprintf(output,".limit stack 100\n");
							fprintf(output,".limit locals 100\n");
							while (v_list) {
								if (v_list->type == 0) {
									fprintf(output,"\tldc %d\n",v_list->val);
									}
								else if (v_list->type == 1 || v_list->type == 2) {
									fprintf(output,"\tldc %f\n",v_list->dval);
								}
								else if (v_list->type == 4) {
									if (v_list->val == 0) {
										fprintf(output,"\ticonst_0\n");
									}
									else if (v_list->val == 1) {
										fprintf(output,"\ticonst_1\n");
									}
								}
								fprintf(output,"\tputstatic test/%s ",v_list->name);
								fprintf_type(v_list->type);
								fprintf(output,"\n");								
								v_list = v_list->next;
							}
							fprintf(output,"\treturn\n");
							fprintf(output,".end method\n");
							global_init_num++;
						}
					}				
					if (strcmp($2,"main") == 0) stack_pointer = 1;
					else stack_pointer = 0;
					return_type = 5;
					if (strcmp($2, "main") == 0) {
						fprintf(output,".method public static main([Ljava/lang/String;)V\n");						
						fprintf(output,".limit stack 100\n");
						fprintf(output,".limit locals 100\n");					
						fprintf(output,"\tnew java/util/Scanner\n");
						fprintf(output,"\tdup\n");
						fprintf(output,"\tgetstatic java/lang/System/in Ljava/io/InputStream;\n");
						fprintf(output,"\tinvokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
						fprintf(output,"\tputstatic test/_sc Ljava/util/Scanner;\n");					
						if (global_init_num != 0) fprintf(output,"\tinvokestatic test/globla_init()V\n");					
					}
					else fprintf(output,".method public static %s(",$2);
					
					symbol_table * t = check_symbol_table($2);
					if (t != NULL) {
						if (t->func_def_bit == 1) {
							add_attributes_to_symbol_table(NULL);
							print_error_msg("name of this function was defined already");
						}
						else {
							if (strcmp(t->kind, "function") != 0) print_error_msg("name of this function was declared and not a function");							
							if (check_func_attribute(t) == 0) {
								add_attributes_to_symbol_table(NULL);
								print_error_msg("parameters of definition and declaration are not match");								
							}
							else if (t->type != 5) {
								add_attributes_to_symbol_table(NULL);
								print_error_msg("declaration and definition have different return typr");
							}
							else {
								t->func_def_bit = 1;
								add_attributes_to_symbol_table(t);
							}
						}
					}
					else {
						if (global == NULL) {
							global = insert($2, "function", level, $1, 0, NULL);
							global->func_def_bit = 1;													
							top->now = global;
							add_parameters_to_entry(top->now, $2);
							head = top;
							add_attributes_to_symbol_table(global);
						}
						else {													
							symbol_table * temp = top->now;
							while (temp->next != NULL) temp = temp->next;
							temp->next = insert($2, "function", level, $1, 0, NULL);
							temp->next->func_def_bit = 1;
							add_parameters_to_entry(temp->next, $2);													
							add_attributes_to_symbol_table(temp->next);
						}
					}
					if (strcmp($2, "main") != 0) {
						fprintf(output,")V\n");
						fprintf(output,".limit stack 100\n");
						fprintf(output,".limit locals 100\n");
					}
					parameters = NULL;
				} func_compound 
					{
						fprintf(output,"\treturn\n");
						fprintf(output,".end method\n");
					}
			;

func_compound	: OPEN_BRACE statements 
					{
						if (return_last == 0) if (return_type != 5) print_error_msg("miss return value"); 
					} CLOSE_BRACE {print_symbol_table(top->now);pop();}
				| OPEN_BRACE {if (return_type != 5) print_error_msg("miss return value");}CLOSE_BRACE {print_symbol_table(top->now);pop();}
				;
			
funct_decl	: type ID decl_argument_list SEMICOLON 
				{
					symbol_table * t = check_symbol_table($2);
					if (t != NULL) {
						print_error_msg("redeclared");
					}
					else {
						if (global == NULL) {
							global = insert($2, "function", level, $1, 0, NULL);
							global->func_def_bit = 0;													
							top->now = global;
							add_parameters_to_entry(top->now, $2);
							head = top;
						}
						else {													
							symbol_table * temp = top->now;
							while (temp->next != NULL) temp = temp->next;
							temp->next = insert($2, "function", level, $1, 0, NULL);
							temp->next->func_def_bit = 0;
							add_parameters_to_entry(temp->next, $2);													
						}
					}
					parameters = NULL;
				}
			| VOID ID decl_argument_list SEMICOLON	
				{
					symbol_table * t = check_symbol_table($2);
					if (t != NULL) {
						print_error_msg("redeclared");
					}
					else {
						if (global == NULL) {
							global = insert($2, "function", level, $1, 0, NULL);
							global->func_def_bit = 0;													
							top->now = global;
							add_parameters_to_entry(top->now, $2);
							head = top;
						}
						else {													
							symbol_table * temp = top->now;
							while (temp->next != NULL) temp = temp->next;
							temp->next = insert($2, "function", level, $1, 0, NULL);
							temp->next->func_def_bit = 0;
							add_parameters_to_entry(temp->next, $2);													
						}
					}
					parameters = NULL;
				}
			;		

		
decl_argument_list	: OPEN_PARENTHESIS CLOSE_PARENTHESIS 
					| OPEN_PARENTHESIS decl_arguments CLOSE_PARENTHESIS	
					;

decl_arguments	: decl_arguments COMMA decl_argument 
				| decl_argument 
				;
					
decl_argument	: CONST type func_augment 	
					{
						if (parameters == NULL) {
							parameters = add_parameters($2 + 6, $3, array_dim);
							parameters->next = NULL;
						}
						else {
							symbol_table_attributes * temp;
							temp = parameters;
							while(temp->next) temp = temp->next;
							temp->next = add_parameters($2 + 6, $3, array_dim);
							temp = temp->next;
							temp->next = NULL;
						}
					}
				| type func_augment 
					{						
						if (parameters == NULL) {
							parameters = add_parameters($1, $2, array_dim);
							parameters->next = NULL;
						}
						else {
							symbol_table_attributes * temp;
							temp = parameters;
							while(temp->next) temp = temp->next;
							temp->next = add_parameters($1, $2, array_dim);
							temp = temp->next;
							temp->next = NULL;
						}
					}
				;

func_augment	: ID {$$ = $1;}
				| ID func_augment_brackets {$$ = $1;}
				;

func_augment_brackets	: func_augment_brackets OPEN_BRACKET integer CLOSE_BRACKET 
							{
								array_type * temp = to_the_array_bottom();
								if (temp == NULL) array_head = add_dimension($3.val);
								else temp->next = add_dimension($3.val);
							}						
						| OPEN_BRACKET integer CLOSE_BRACKET 
							{
								array_type * temp = to_the_array_bottom();
								if (temp == NULL) array_head = add_dimension($2.val);
								else temp->next = add_dimension($2.val);
							}
						;
//}
//{-----------function definition---------------------------												
statements	: statements statement 
			| statement 
			;

statement	: /*call function*/ call_funct SEMICOLON {return_last = 0;}
			| /*assignment*/ 	assignment SEMICOLON {return_last = 0;}
			| /*print*/			PRINT {fprintf(output,"\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n"); } print_augment SEMICOLON 
									{
										if ($3 != -1 && $3 != 5) {
											if ($3 == 4) {
												fprintf(output,"\tifeq boolfalse%d\n",print_bool_num);
												fprintf(output,"\tldc \"true\"\n");
												fprintf(output,"\tgoto booltrue_%d\n",print_bool_num);
												fprintf(output,"boolfalse%d:\n",print_bool_num);
												fprintf(output,"ldc \"false\"\n");
												fprintf(output,"booltrue_%d:\n",print_bool_num);
												print_bool_num++;
											}
											fprintf(output,"\tinvokevirtual java/io/PrintStream/print(");
											if ($3 == 4) fprintf_type(3);
											else fprintf_type($3);
											fprintf(output,")V\n");
										}
										return_last = 0;
									}
			| /*read*/			READ identifier SEMICOLON 
									{
										symbol_table * temp = check_symbol_table($2.text);
										if (temp!=NULL) {													
											fprintf(output,"\tgetstatic test/_sc Ljava/util/Scanner;\n");
											fprintf(output,"\tinvokevirtual java/util/Scanner/next");
											if (temp->type == 0) fprintf(output,"Int()I\n");
											else if (temp->type == 1) fprintf(output,"Float()F\n");
											else if (temp->type == 2) fprintf(output,"Double()D\n");
											else if (temp->type == 4) fprintf(output,"Boolean()Z\n");											
											if (temp->level == 0) {
												fprintf(output,"\tputstatic test/%s ",$2.text);
												fprintf_type(temp->type);
												fprintf(output,"\n");
											}
											else {
												if (temp->type == 0) fprintf(output,"\tistore %d\n",temp->location);
												else if (temp->type == 1) fprintf(output,"\tfstore %d\n",temp->location);
												else if (temp->type == 2) fprintf(output,"\tfstore %d\n",temp->location);
												else if (temp->type == 3) fprintf(output,"\tistore %d\n",temp->location);
											}
										}
										return_last = 0;
									}
			| /*if*/			CONDITION_IF OPEN_PARENTHESIS if_control CLOSE_PARENTHESIS 
									{
										fprintf(output,"\tifeq Lelse_%d\n",condition_num);										
										condition_num++;
									}
								compound else_part
			| /*while*/			WHILE 
									{
										int t = loop_num;
										loop_num++;
										loop_stack_push(t);
										fprintf(output,"LloopBegin_%d:\n",t);										
									} 
								OPEN_PARENTHESIS while_augments CLOSE_PARENTHESIS {loop++;} compound 
									{
										loop--; 
										return_last = 0;
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LloopBegin_%d\n",t);
										fprintf(output,"LloopExit_%d:\n",t);
										loop_stack_push(t);
									}
			| /*do while*/		DO 
									{
										int t = loop_num;
										loop_num++;
										loop_stack_push(t);
										fprintf(output,"LloopBegin_%d:\n",t);
										loop++;
									} 
								compound {loop--;} WHILE OPEN_PARENTHESIS while_augments CLOSE_PARENTHESIS SEMICOLON 
									{
										return_last = 0;
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LloopBegin_%d\n",t);
										fprintf(output,"LloopExit_%d:\n",t);
										loop_stack_push(t);									
									}
			| /*for*/			FOR OPEN_PARENTHESIS check_for_inits SEMICOLON 
									{
										loop_stack_push(loop_num);
										fprintf(output,"LloopBegin_%d:\n",loop_num);
										loop_num++;
									}
								for_control SEMICOLON 
									{
										int t = loop_stack_pop();
										fprintf(output,"LforSta_%d:\n",t);
										loop_stack_push(t);
									}
								check_for_statements 
									{
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LloopBegin_%d\n",t);
										loop_stack_push(t);
									}
								CLOSE_PARENTHESIS 
									{
										loop++;
										int t = loop_stack_pop();
										fprintf(output,"LforCompound_%d:\n",t);
										loop_stack_push(t);
									} 
								compound 
									{
										loop--;
										return_last = 0;
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LforSta_%d\n",t);
										fprintf(output,"LloopExit_%d:\n",t);
									}
			| /*return*/		RETURN {return_stm = 1;}return_value SEMICOLON 
									{
										return_last = 1;
										return_stm = 0;
										if (main_func == 1) fprintf(output,"\treturn\n");
										else if ($3 == 0) fprintf(output,"\tireturn\n");
										else if ($3 == 1) fprintf(output,"\tfreturn\n");
										else if ($3 == 2) fprintf(output,"\tdreturn\n");
										else if ($3 == 4) fprintf(output,"\tzreturn\n");
									}
			| /*break*/			BREAK SEMICOLON 
									{
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LloopExit_%d\n",t);
										loop_stack_push(t);
										return_last = 0;
										if (loop == 0) print_error_msg("break should be in a loop");
									}
			| /*continue*/		CONTINUE SEMICOLON 
									{
										int t = loop_stack_pop();
										fprintf(output,"\tgoto LloopBegin_%d\n",t);
										loop_stack_push(t);
										return_last = 0;
										if (loop == 0) print_error_msg("continue should be in a loop");
									}
			| /*declaration*/	var_decl {return_last = 0;}
			| /*const decl*/		const_decl {return_last = 0;}
			;

call_funct	: ID OPEN_PARENTHESIS call_func_augments CLOSE_PARENTHESIS 
				{
					$$ = check_call_funct_type($1);
					call_func_variables = NULL;
				}
			| ID OPEN_PARENTHESIS CLOSE_PARENTHESIS
				{
					$$ = check_call_funct_type($1);
					call_func_variables = NULL;
				}
			;
			
call_func_augments	: call_func_augments COMMA call_func_element
					| call_func_element
					;		

call_func_element	: boolexpressions 
						{
							add_to_call_func_pa($1,0);
						}					
					| sentence 
						{
							add_to_call_func_pa(3,0);
						}
					;
assignment	: identifier ASSIGN sentence
				{
					if ($1.type != -1 ) {
						if ($1.type > 5) print_error_msg("constant variable can't be assigned");
						else if ($1.type != 3) {
							print_error_msg("variable is not a string type");
						}
						else if ($1.type > 5) print_error_msg("constant can't be assigned");						
					}
				}
			| identifier ASSIGN boolexpressions 
				{
					if ($1.type != -1 && $3 != -1) {
						if ($1.type > 5) print_error_msg("constant variable can't be assigned");
						else if (check_assign_type($1.type, $3) == 0) {
							print_error_msg("not right type");
						}
						else if ($1.type > 5) print_error_msg("constant can't be assigned");
						else {
							symbol_table * temp = check_symbol_table($1.text);
							if (temp->level == 0) {
								fprintf(output,"\tputstatic test/%s ",$1.text);
								fprintf_type(temp->type);
								fprintf(output,"\n");
							}
							else {
								int loc = temp->location;
								if (temp->type == 0) fprintf(output,"\tistore %d\n",loc);
								else if (temp->type == 1) fprintf(output,"\tfstore %d\n",loc);
								else if (temp->type == 2) fprintf(output,"\tdstore %d\n",loc);
								else if (temp->type == 4) fprintf(output,"\tistore %d\n",loc);
							}
						} 
					}
					
				}		
			;

if_control	: boolexpressions 
				{
					if ($1 != 4) print_error_msg("control statement should be boolean type");
					else {
						con_stack_push(condition_num);
					}
				}
			;

else_part	: CONDITION_ELSE 
					{
						int t = con_stack_pop();
						fprintf(output,"\tgoto Lexit_%d\n",t);
						fprintf(output,"Lelse_%d:\n",t);										
						con_stack_push(t);
					}
				compound 
					{
						int t = con_stack_pop();
						fprintf(output,"Lexit_%d:\n",t);
						return_last = 0;
					}
			|	{
					int t = con_stack_pop();					
					fprintf(output,"Lelse_%d:\n",t);
					return_last = 0;
				} 
			;
			
print_augment	: sentence {$$ = 3; fprintf(output,"\tldc \"%s\"\n",$1.text);}
				| boolexpressions {$$ = $1;}
				;

return_value	: boolexpressions 
					{
						if ($1 != -1) check_return_type($1);
						$$ = $1;
					}
				| sentence
					{						
						if (return_type == 5) print_error_msg("function is void type");
						else if (return_type != 3) print_error_msg("should not return string");
						else {
							if (main_func != 1) fprintf(output,"\tldc \"%s\"\n",$1.text);
							$$ = 3;
						}
					}
				;


check_for_inits : for_inits
				|
				;
				
for_inits	: for_inits COMMA for_init
			| for_init
			;
			
for_init	: assignment
			| expressions
			;

for_control	: boolexpressions 
				{
					if ($1 != 4) print_error_msg("control statement should be boolean type");
					else {
						int t = loop_stack_pop();
						fprintf(output,"\tifeq LloopExit_%d\n",t);
						fprintf(output,"\tgoto LforCompound_%d\n",t);
						loop_stack_push(t);
					}
				}
			| {print_error_msg("for statement lacks of control statement");}
			;
			
check_for_statements	: for_statements
						|
						;
			
for_statements	: for_statements COMMA for_statement
				| for_statement
				;

for_statement	: assignment
				| expressions
				;
				
while_augments	: boolexpressions 
					{
						if ($1 != 4) print_error_msg("control statement should be boolean type");
						else {
							int t = loop_stack_pop();
							fprintf(output,"\tifeq LloopExit_%d\n",t);
							loop_stack_push(t);							
						}
					}
				| {print_error_msg("control statement should not be empty");}
				;

boolexpressions	: boolexpressions logicaloperand con_boolexpression
					{
						if ($1 != -1 && $3 != -1) {
							if ($1 == 3 || $3 == 3) {
								print_error_msg("string can not compare");
								$$ = -1;
							}
							else if ($1 != 4 || $3 != 4) {
								print_error_msg("not boolean type to do logical arithmetic");
								$$ = -1;
							}
							else {
								
								if ($2 == 5) {
									fprintf(output,"\tiand\n");
								}
								else if ($2 == 6) {
									fprintf(output,"\tior\n");
								}
								fprintf(output,"\tifne Ltrue_%d\n",compare_num);
								fprintf(output,"\ticonst_0\n");
								fprintf(output,"\tgoto Lfalse_%d\n",compare_num);
								fprintf(output,"Ltrue_%d:\n",compare_num);
								fprintf(output,"\ticonst_1\n");
								fprintf(output,"Lfalse_%d:\n",compare_num);
								compare_num++;
								$$ = 4;
							}
						}
						else $$ = -1;
					}
				| con_boolexpression {$$ = $1;}
				;

con_boolexpression	:  con_boolexpression con_operand boolexpression
						{
							if ($1 != -1 && $3 != -1) {
								if ($1 == 3 || $3 == 3) {
									print_error_msg("string can not compare");
									$$ = -1;
								}
								else if (check_exprs_con_exprs_type($1,$3) == 0) {
									print_error_msg("not right type to compare");
									$$ = -1;
								}
								else {
									if ($1 == $3) {
										if ($1 == 0) fprintf(output,"\tisub\n");
										else if ($1 == 2 || $1 == 1) {
											fprintf(output,"\tfcmpg\n");
											//fprintf(output,"\tf2i\n");
										}
									}
									else if ($1 > $3) {
										fprintf(output,"\ti2f\n");
										fprintf(output,"\tfcmpg\n");
										//fprintf(output,"\tf2i\n");
									}
									else {
										fprintf(output,"\tswap\n");
										fprintf(output,"\ti2f\n");
										fprintf(output,"\tfcmpg\n");
										//fprintf(output,"\tf2i\n");
									}
									if ($2 == 0) fprintf(output,"\tifeq ");
									else if ($2 == 1) fprintf(output,"\tifne ");
									else if ($2 == 2) fprintf(output,"\tifle ");
									else if ($2 == 3) fprintf(output,"\tifge ");
									else if ($2 == 4) fprintf(output,"\tifgt ");
									else if ($2 == 5) fprintf(output,"\tiflt ");
									fprintf(output,"Ltrue_%d\n",compare_num);
									fprintf(output,"\ticonst_0\n");
									fprintf(output,"\tgoto Lfalse_%d\n",compare_num);
									fprintf(output,"Ltrue_%d:\n",compare_num);
									fprintf(output,"\ticonst_1\n");
									fprintf(output,"Lfalse_%d:\n",compare_num);
									compare_num++;
									$$ = 4;
								}
							}
							else $$ = -1;
						}
					| boolexpression {$$ = $1;}
					;
				
				
boolexpression	:SCARLAR_BOOLEAN 
					{
						if ($1.val == 0) fprintf(output,"\tldc 0\n");
						else if ($1.val == 1) fprintf(output,"\tldc 1\n");						
						$$ = 4;
					}
				| NOT boolexpression %prec AND 
					{
						fprintf(output,"\tixor");
						$$ = $2;
					}
				| expressions {$$ = $1;}
				;
				
expressions	: expressions operand_PLUS_MINUS expressions_multi_divide 
				{
					if ($1 == -1 || $3 == -1) $$ = -1;
					else if (check_exprs_type($1, $3) == 0) {
						print_error_msg("type not match");
						$$ = -1;
					}
					else {
						if ($1 == $3) {
							$$ = $1;
							calculating($1,$2);
						}
						else if ( $1 > $3 ) {
							fprintf(output,"\ti2f\n");
							calculating($1,$2);
							$$ = $1;
						}
						else {
							fprintf(output,"\tswap\n");
							fprintf(output,"\ti2f\n");
							calculating($3,$2);
							$$ = $3;
						}
					}
				}
			| expressions_multi_divide {$$ = $1;}
			;

expressions_multi_divide : expressions_multi_divide operand_MULTI_DIV_MOD expression
							{
								if ($1 == -1 || $3 == -1) $$ = -1;
								else if (check_exprs_type($1, $3) == 0) {
									print_error_msg("type not match");
									$$ = -1;
								}
								else {
									if ($1 == $3) {
										$$ = $1;
										calculating($1,$2);
									}
									else if ( $1 > $3 ) {
										fprintf(output,"\ti2f\n");
										calculating($1,$2);
										$$ = $1;
									}
									else {
										fprintf(output,"\tswap\n");
										fprintf(output,"\ti2f\n");
										calculating($3,$2);
										$$ = $3;
									}
								}
							}
						 | expression {$$ = $1;}	
						 ;
						
			
expression	: num {$$ = $1;}
			| MINUS expression %prec MULTI 
				{
					$$ = $2;
					if ($2 == 0) fprintf(output,"\tineg\n");
					else {
						if ($2 == 0) fprintf(output,"\tineg\n");
						else if ($2 == 1 || $2 == 2) fprintf(output,"\tfneg\n");
					}
				}
			| call_funct {$$ = $1;}
			;
				
num	: integer 
		{
			$$ = 0;
			if (return_stm != 1 || main_func != 1) fprintf(output,"\tldc %d\n",$1.val);
		} 
	| floating 
		{
			$$ = 1;
			fprintf(output,"\tldc %f\n",$1.dval);
		}
	| identifier   
		{
			$$ = $1.type;
			symbol_table * s = check_symbol_table($1.text);
			if (s != NULL) {
				if (strcmp(s->kind,"constant") == 0) {
					if (s->type == 0) fprintf(output,"\tldc %d\n",s->attribute->const_integer);
					else if (s->type == 1 || s->type == 2) fprintf(output,"\tldc %f\n",s->attribute->const_floating);
					else if (s->type == 3) fprintf(output,"\tldc \"%s\"\n",s->attribute->const_string);
					else if (s->type == 4) {
						if (s->attribute->const_integer == 1) fprintf(output,"\ticonst_1\n");
						else fprintf(output,"\ticonst_0\n");
					}
				}
				else {
					if (s->level == 0) {
						fprintf(output,"\tgetstatic test/%s ",$1.text);
						fprintf_type(s->type);
						fprintf(output,"\n");
					}
					else {
						if (s->type == 0) fprintf(output,"\tiload %d\n",s->location);
						else if (s->type == 1) fprintf(output,"\tfload %d\n",s->location);
						else if (s->type == 2) fprintf(output,"\tdload %d\n",s->location);
						else if (s->type == 4) fprintf(output,"\tiload %d\n",s->location);
					}
				}
			}
		}
	;

identifier	: ID {
					$$.text = malloc(strlen($1) * sizeof(char));
					strcpy($$.text, $1);
					int temp = get_ID_type($1); 
					$$.type = temp;
				}
			| ID array_brackets
				{
					if ($2 == -1) {
						print_array_index_error_msg($1);
						$$.type = -1;
					}
					else {						
						int arr_dim = get_array_dimension($1);
						$$.type = get_ID_type($1);
						if (id_array_dim != arr_dim) {
							print_error_msg("this element is not a scalar type");
							$$.type = -1;
						}
						else strcpy($$.text, $1);
					}
					id_array_dim = 0;
				}
			;

array_brackets	: array_brackets OPEN_BRACKET expressions CLOSE_BRACKET
					{
						if ($3 != 0 ) $$ = -1;
						id_array_dim++;
					}
				| OPEN_BRACKET expressions CLOSE_BRACKET 
					{
						if ($2 != 0 ) $$ = -1;
						id_array_dim++;
					}
				;	
	
con_operand	: LESSOREQUAL {$$ = 2;}
			| LARGEOREQUAL {$$ = 3;}
			| LARGE {$$ = 4;}
			| LESS {$$ = 5;}
			| EQUAL {$$ = 0;}
			| NOTEQUAL {$$ = 1;}
			;

operand_PLUS_MINUS	: PLUS {$$ = 0;}
					| MINUS {$$ = 1;}
					;

operand_MULTI_DIV_MOD	: MULTI {$$ = 2;}
						| DIVIDE {$$ = 3;}
						| MOD {$$ = 4;}
						;
					
/*
	PLUS   0
	MINUS  1
	MULTI  2
	DIVIDE 3
	MOD    4
	AND    5
	OR     6
	EQUAL 		 0
	NOTEQUAL 	 1
	LESSOREQUAL  2
	LARGEOREQUAL 3
	LARGE 		 4
	LESS 		 5

	
*/		
		
logicaloperand	: AND {$$ = 5;}
				| OR {$$ = 6;}
				;		
//}	
%%

int yyerror( char *msg )
{
  fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
  fprintf( stderr, "|--------------------------------------------------------------------------\n" );
  exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}
