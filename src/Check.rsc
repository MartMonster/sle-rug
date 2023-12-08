module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type typeFromString(str t) {
  switch(t) {
    case "integer": return tint();
    case "boolean": return tbool();
    default: return tunknown();
  }
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenv = {};
  visit(f) {
    case question(str question, AId id, AType t, _): tenv += <id.src, id.name, question, typeFromString(t.name)>;
    case question(str question, AId id, AType t): tenv += <id.src, id.name, question, typeFromString(t.name)>;
  }
  return tenv; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  set[tuple[loc, str, str, Type]] seen = {};
  for (tuple[loc, str, str, Type] t <- tenv) {
    if (t<1> in seen<1>) {
      msgs += {error("Redefined question", t<0>)};
    }

    if (t<2> in seen<2>) {
      msgs += {warning("Redefined question", t<0>)};
    }

    seen += {t};
  }

  for (AQuestion q <- f.questions) {
    msgs += check(q, tenv, useDef);
  }

  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch(q) {
    case question(_, _, _, AExpr assignvalue): msgs += check(assignvalue, tenv, useDef);
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): msgs += [check(qs, tenv, useDef) | qs <- ifQuestions + elseQuestions + guard];
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): msgs += [check(qs, tenv, useDef) | qs <- ifQuestions + guard];
  }

  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

