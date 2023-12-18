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
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      msgs += [check(qs, tenv, useDef) | qs <- ifQuestions + elseQuestions];
      msgs += check(guard, tenv, useDef);
      if (typeOf(guard, tenv, useDef) != tbool()) {
        msgs += { error("Guard expression must be boolean", q.src) };
      }
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      msgs += [check(qs, tenv, useDef) | qs <- ifQuestions];
      msgs += check(guard, tenv, useDef);
      if (typeOf(guard, tenv, useDef) != tbool()) {
        msgs += { error("Guard expression must be boolean", q.src) };
      }
    }
  }
  return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch (e) {
    case ref(AId x): {
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
      return msgs;
    }
    case neg(AExpr expr): {
      msgs += check(expr, tenv, useDef);
      if (typeOf(expr, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'-\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case mul(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'*\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case div(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'/\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case add(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'+\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case sub(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'-\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case and(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tbool() || typeOf(right, tenv, useDef) != tbool()) {
        msgs += { error("Cannot use \'&&\' operator on non-boolean", e.src) };
      }
      return msgs;
    }
    case or(AExpr left, AExpr right):{
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != tbool() || typeOf(right, tenv, useDef) != tbool()) {
        msgs += { error("Cannot use \'||\' operator on non-boolean", e.src) };
      }
      return msgs;
    }
    case eq(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != typeOf(right, tenv, useDef)) {
        msgs += { error("Lhs and Rhs of \'==\' must be of the same type", e.src) };
      }
      return msgs;
    }
    case neq(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef) != typeOf(right, tenv, useDef)) {
        msgs += { error("Lhs and Rhs of \'!=\' must be of the same type", e.src) };
      }
      return msgs;
    }
    case lt(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef)!= tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'\<\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case leq(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef)!= tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'\<=\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case gt(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef)!= tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'\>\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case geq(AExpr left, AExpr right): {
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if (typeOf(left, tenv, useDef)!= tint() || typeOf(right, tenv, useDef) != tint()) {
        msgs += { error("Cannot use \'\>=\' operator on non-integer", e.src) };
      }
      return msgs;
    }
    case not(AExpr expr): {
      msgs += check(expr, tenv, useDef);
      if (typeOf(expr, tenv, useDef) != tbool()) {
        msgs += { error("Cannot use \'!\' operator on non-boolean", e.src) };
      }
      return msgs;
    }
  }
  
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case integer(_): return tint();
    case boolean(_): return tbool();
    case string(_): return tstr();
    case mul(_, _): return tint();
    case div(_, _): return tint();
    case add(_, _): return tint();
    case sub(_, _): return tint();
    case and(_, _): return tbool();
    case or(_, _): return tbool();
    case eq(_, _): return tbool();
    case neq(_, _): return tbool();
    case lt(_, _): return tbool();
    case leq(_, _): return tbool();
    case gt(_, _): return tbool();
    case geq(_, _): return tbool();
    case not(_): return tbool();
    case neg(_): return tint();
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
