module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}";

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = Str question Id id ":" Type type "=" Expr exp
  | Str question Id id ":" Type type
  | "if" "(" Expr guard ")" "{" Question* ifQuestions "}" "else" "{" Question* elseQuestions "}"
  | "if" "(" Expr guard ")" "{" Question* ifQuestions "}"
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr =
  Int
  | Bool
  | Str
  | Id \ "true" \ "false"
  | "(" Expr ")"
  > left ("!" Expr
  | "-" Expr)
  > left (left Expr "*" Expr
  | left Expr "/" Expr)
  > left (left Expr "+" Expr
  | left Expr "-" Expr)
  > left (non-assoc Expr "\<" Expr
  | non-assoc Expr "\>" Expr
  | non-assoc Expr "\<=" Expr
  | non-assoc Expr "=\>" Expr
  | non-assoc Expr "==" Expr
  | non-assoc Expr "!=" Expr)
  > non-assoc Expr "&&" Expr
  > non-assoc Expr "||" Expr
  ;
  
syntax Type = "integer" | "boolean";

lexical Str = [\"]![\"]*[\"]|[\']![\']*[\'];

lexical Int 
  = [0-9]+;

lexical Bool = "true" | "false";


