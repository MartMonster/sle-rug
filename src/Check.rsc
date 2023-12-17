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
    case question(_, _, _, AExpr assignvalue): msgs += check(assignvalue, tenv, useDef)<0>;
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      msgs += [check(qs, tenv, useDef) | qs <- ifQuestions + elseQuestions];
      g = check(guard, tenv, useDef);
      msgs += g<0>;
      if (g<1> != tbool()) {
        msgs += { error("Guard expression must be boolean", q.src) };
      }
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      msgs += [check(qs, tenv, useDef) | qs <- ifQuestions];
      g = check(guard, tenv, useDef);
      msgs += g<0>;
      if (g<1> != tbool()) {
        msgs += { error("Guard expression must be boolean", q.src) };
      }
    }
  }
  return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
tuple[set[Message], Type] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  Type t = tunknown();

  switch (e) {
    case ref(AId x): {
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
      t = typeOf(ref(x), tenv, useDef);
      return <msgs, t>;
    }
    case integer(int i): return <{}, typeOf(integer(i), tenv, useDef)>;
    case boolean(bool b): return <{}, typeOf(boolean(b), tenv, useDef)>;
    case string(str s): return <{}, typeOf(string(s), tenv, useDef)>;
    case neg(AExpr expr): {
      c = check(expr, tenv, useDef);
      msgs += c<0>;
      if (c<1> != tint()) {
        msgs += { error("Cannot use \'-\' operator on non-integer", e.src) };
      }
      return <msgs, c<1>>;
    }
    case mul(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'*\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case div(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'/\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case add(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'+\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case sub(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'-\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case and(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tbool() || r<1> != tbool()) {
        msgs += { error("Cannot use \'&&\' operator on non-boolean", e.src) };
      }
      return <msgs, tint()>;
    }
    case or(AExpr left, AExpr right):{
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tbool() || r<1> != tbool()) {
        msgs += { error("Cannot use \'||\' operator on non-boolean", e.src) };
      }
      return <msgs, tint()>;
    }
    case eq(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != r<1>) {
        msgs += { error("Cannot use \'==\' operator on non-boolean", e.src) };
      }
      return <msgs, l<1>>;
    }
    case neq(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != r<1>) {
        msgs += { error("Cannot use \'!=\' operator on non-boolean", e.src) };
      }
      return <msgs, l<1>>;
    }
    case lt(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'\<\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case leq(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'\<=\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case gt(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'\>\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case geq(AExpr left, AExpr right): {
      l = check(left, tenv, useDef);
      r = check(right, tenv, useDef);
      msgs += l<0>;
      msgs += r<0>;
      if (l<1> != tint() || r<1> != tint()) {
        msgs += { error("Cannot use \'\>=\' operator on non-integer", e.src) };
      }
      return <msgs, tint()>;
    }
    case not(AExpr expr): {
      c = check(expr, tenv, useDef);
      msgs += c<0>;
      if (c<1> != tbool()) {
        msgs += { error("Cannot use \'!\' operator on non-integer", e.src) };
      }
      return <msgs, c<1>>;
    }
  }
  
  return <msgs, t>; 
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
