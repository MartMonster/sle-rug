module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = question(str question, AId id, AType t, AExpr assignvalue)
  | question(str question, AId id, AType t)
  | ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  | ifstm(AExpr guard, list[AQuestion] ifQuestions)
  ;


data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | integer(int integer)
  | string(str string)
  | boolean(bool boolean)
  | neg(AExpr expr)
  | mul(AExpr left, AExpr right)
  | div(AExpr left, AExpr right)
  | add(AExpr left, AExpr right)
  | sub(AExpr left, AExpr right)
  | and(AExpr left, AExpr right)
  | or(AExpr left, AExpr right)
  | eq(AExpr left, AExpr right)
  | neq(AExpr left, AExpr right)
  | lt(AExpr left, AExpr right)
  | leq(AExpr left, AExpr right)
  | gt(AExpr left, AExpr right)
  | geq(AExpr left, AExpr right)
  | not(AExpr expr)
  ;


data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|) = typeName(str name);