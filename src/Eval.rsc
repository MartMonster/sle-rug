module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

Value defaultReturnValue(AType t) {
  Value val = vbool(false);
  switch (t.name) {
    case "boolean": val = vbool(false);
    case "integer": val = vint(0);
    case "string": val = vstr("");
  }
  return val;
}

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  visit (f) {
    case question(_, AId id, AType t, _): venv[id.name] = defaultReturnValue(t);
    case question(_, AId id, AType t): venv[id.name] = defaultReturnValue(t);
  }
  return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  visit (f) {
    case question(str q, AId id, _, _): {
      if (q == inp.question) {
        venv[id.name] = inp.\value;
      }
    }
    case question(str q, AId id, _): {
      if (q == inp.question) {
        venv[id.name] = inp.\value;
      }
    }
  }
  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  return (); 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}