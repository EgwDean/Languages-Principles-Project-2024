%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
extern int line_number;

void yyerror(char *s) {
   fprintf(stderr, "Error at line %d: %s\n", line_number, s);
}

void add_symbol(const char *name, const char *data_type);
const char* find_data_type(const char *name);


// Data structure for a symbol entry
typedef struct {
    char name[256];  // Assuming maximum variable name length of 255 characters
    char data_type[10];   // Data type: INT, DOUBLE, CHAR, BOOLEAN, STRING
} SymbolEntry;

// Maximum number of symbols (adjust as needed)
#define MAX_SYMBOLS 100

// Symbol table
SymbolEntry symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

// Function to add a symbol to the symbol table
void add_symbol(const char *name, const char *data_type) {
    if (symbol_count < MAX_SYMBOLS) {
        strcpy(symbol_table[symbol_count].name, name);
        strcpy(symbol_table[symbol_count].data_type, data_type);
        symbol_count++;
    } else {
        fprintf(stderr, "Error: Symbol table full\n");
        exit(EXIT_FAILURE);
    }
}

// Function to find the data type of a variable in the symbol table
const char* find_data_type(const char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].data_type;
        }
    }
    return "not found";

}



%}

%union {
   char *str;
}


%token PUBLIC_CLASS CLASS_NAME LEFT_BRACE RIGHT_BRACE PUBLIC PRIVATE QMARK VAR
%token INT DOUBLE CHAR BOOLEAN STRING 
%token EQUAL NEW LEFT_BRACKET RIGHT_BRACKET VOID PROTECTED M_PUBLIC M_PRIVATE
%token COMMA RETURN INT_NUM DOUBLE_NUM CHAR_VAR STRING_VAR TRUE FALSE DOT
%token MUL DIV PLUS MINUS DO WHILE AND OR CHECK_EQUAL LESS GREATER NOT_EQUAL FOR SWITCH CASE 
%token DOUBLE_DOT DEFAULT BREAK PRINT IF ELSE ELSE_IF
%token SINGLE_COMMENT MULTILINE_COMMENT


%type <const char*> variable
%type <const char*> expression
%type <const char*> data_type

%%

program: c public_class c
        | program c public_class c
        ;

public_class: PUBLIC_CLASS CLASS_NAME LEFT_BRACE class_block RIGHT_BRACE
                ;

class_block: variable_declarations method_declarations nested_class
		;


nested_class: c public_class c | ;


variable_declarations: variable_declaration | variable_declaration variable_declarations | ;





variable_declaration: c variable_modifier data_type variable extra_variables QMARK c
            | c CLASS_NAME variable EQUAL object_instance QMARK c
            | c variable_modifier data_type variable EQUAL expression extra_assigned_variables QMARK c
            {		   
                          // Add the variable to the symbol table
                          add_symbol($4, $3); 
                          // Perform type checking on the assignment expression
                          char* var_type = find_data_type($4);
                          if (var_type != "not found") {
                              
                                  if (strcmp($6, "INT_NUM") == 0){
                                      if (var_type != "INT") {
                                          fprintf(stderr, "Error: Variable '%s' is not of type INT\n", $4);
                                          // Handle type mismatch
                                      }
				  }
                                     
                                  if (strcmp($6, "DOUBLE_NUM") == 0){
                                      if (var_type != "DOUBLE") {
                                          fprintf(stderr, "Error: Variable '%s' is not of type DOUBLE\n", $4);
                                          // Handle type mismatch
                                      }
                                  }
                                   
				  if (strcmp($6, "CHAR_VAR") == 0){
                                      if (var_type != "CHAR") {
                                          fprintf(stderr, "Error: Variable '%s' is not of type CHAR\n", $4);
                                          // Handle type mismatch
                                      }
                                  }
					
				  if (strcmp($6, "STRING_VAR") == 0){
                                      if (var_type != "STRING") {
                                          fprintf(stderr, "Error: Variable '%s' is not of type STRING\n", $4);
                                          // Handle type mismatch
                                      }
                                  }
                                  else{
                                      fprintf(stderr, "Error: Invalid expression type\n");
                                      // Handle invalid expression type
                                  }

                          } 
			  else {
                              fprintf(stderr, "Error: Variable '%s' not found\n", $4);
                              // Handle variable not found
                          }
             }
            ;








extra_variables: COMMA variable
	         | COMMA variable extra_variables
	         | ;


extra_assigned_variables: COMMA variable EQUAL expression extra_assigned_variables
	                  | ;


method_declarations: c method_declaration c | c method_declaration c method_declarations | ;


method_declaration: method_modifier return_type variable LEFT_BRACKET parameters RIGHT_BRACKET LEFT_BRACE method_block return RIGHT_BRACE;


parameters: data_type variable
	| data_type variable COMMA parameters
	|;


method_block: variable_declarations commands ;


commands: c command c | c command c commands | ;


command: assignment | do_loop | for_loop | switch_case | break | method_call | print | if_else ;


assignment: variable EQUAL expression QMARK ;

member_access: variable DOT variable LEFT_BRACKET arguments RIGHT_BRACKET
		| variable DOT variable ;


method_call: variable LEFT_BRACKET arguments RIGHT_BRACKET ;


arguments: variable | variable COMMA arguments | normal_type | normal_type COMMA arguments ; 


expression: normal_type | member_access | method_call | operations ;


operations: num operator_symbol operations | num | variable operator_symbol operations | variable;


do_loop: DO c LEFT_BRACE commands RIGHT_BRACE c  WHILE LEFT_BRACKET conditions RIGHT_BRACKET QMARK ;


conditions: condition | condition logic_operators conditions ;


condition: variable compare_symbol normal_type 
		| normal_type compare_symbol variable
		| variable compare_symbol VAR
		| normal_type compare_symbol normal_type ;


logic_operators: AND | OR ;


compare_symbol: LESS | GREATER | NOT_EQUAL | CHECK_EQUAL ;


operator_symbol: DIV | MUL | PLUS | MINUS ;


for_loop: FOR LEFT_BRACKET for_assignment QMARK conditions QMARK increment RIGHT_BRACKET c LEFT_BRACE commands RIGHT_BRACE c ;



for_assignment: variable EQUAL num | variable EQUAL variable ;


increment: variable EQUAL variable operator_symbol num 
		| variable EQUAL variable operator_symbol variable ;


switch_case: SWITCH LEFT_BRACKET variable RIGHT_BRACKET c LEFT_BRACE c cases c DEFAULT  commands RIGHT_BRACE
		| SWITCH LEFT_BRACKET variable RIGHT_BRACKET c LEFT_BRACE c cases c RIGHT_BRACE ;


cases: CASE normal_type DOUBLE_DOT commands | CASE normal_type DOUBLE_DOT commands cases ;


if_else: c IF LEFT_BRACKET conditions RIGHT_BRACKET c LEFT_BRACE commands RIGHT_BRACE c else_if c else c ;



else_if: c ELSE_IF LEFT_BRACKET conditions RIGHT_BRACKET c LEFT_BRACE commands RIGHT_BRACE c 
	|c ELSE_IF LEFT_BRACKET conditions RIGHT_BRACKET c LEFT_BRACE commands RIGHT_BRACE c else_if c
	| ;



else: c ELSE c LEFT_BRACE commands RIGHT_BRACE | ;



normal_type: INT_NUM | DOUBLE_NUM | TRUE | FALSE | CHAR_VAR | STRING_VAR ; 


object_instance: NEW CLASS_NAME LEFT_BRACKET RIGHT_BRACKET ; 


return: RETURN num QMARK ;
	|RETURN expression QMARK ; 

break: BREAK QMARK ;


print: PRINT LEFT_BRACKET STRING_VAR print_vars RIGHT_BRACKET QMARK ;


print_vars: COMMA variable | COMMA variable print_vars | ;


variable_modifier: PUBLIC | PRIVATE | ;


return_type: INT | DOUBLE | CHAR | BOOLEAN | STRING | VOID ; 


data_type: INT | DOUBLE | CHAR | BOOLEAN | STRING ;


method_modifier: M_PUBLIC | M_PRIVATE | PROTECTED ;


variable: VAR ;


num: INT_NUM | DOUBLE_NUM ;

c: comment | c comment | ;

comment: SINGLE_COMMENT | MULTILINE_COMMENT ;




%%


int main(int argc, char** argv) { 
    char filename[] = "file.txt";
    if(argc == 2)
    {
	strcpy(filename, argv[1]);
    }
    FILE *file = fopen(filename, "r");
    if (!file) {
        perror(filename);
        return 1;
    }
    yyin = file;
    yyparse();
    fclose(file);
    return 0;
}

