module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Stuff* questions "}";

syntax Stuff = Question | If;

syntax If = "if" "(" Expr ")" "{" Stuff* questions "}" Else?;

syntax Else = "else" "{" Stuff* stuff "}";

// TODO: question, computed question, block, if-then-else, if-then
syntax Question = Str question Id id ":" Type type AssignValue?;

syntax AssignValue = "=" Expr;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr = 
  left Expr "||" Expr
  > left Expr "&&" Expr
  > left Expr "==" Expr
  | left Expr "!=" Expr
  > left Expr "\<" Expr
  | left Expr "\>" Expr
  | left Expr "\<=" Expr
  | left Expr "=\>" Expr
  > left Expr "+" Expr
  | left Expr "-" Expr
  > left Expr "*" Expr
  | left Expr "/" Expr 
  > right "!" Expr
  | right "-" Expr
  > "(" Expr ")"
  | Int
  | Bool
  | Str
  | Id \ "true" \ "false"
  ;
  
syntax Type = "integer" | "boolean";

lexical Str = [\'\"]![\"]*[\'\"];

lexical Int 
  = [0-9]+;

lexical Bool = "true" | "false";


