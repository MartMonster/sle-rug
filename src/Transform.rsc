module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] newList = [];
  for (AQuestion q <- f.questions) {
    newList += flatten(q, boolean(true));
  }
  return form("<f.name>", newList, src=f.src); 
}

list[AQuestion] flatten(AQuestion q, AExpr newGuard) {
  switch (q) {
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      list[AQuestion] newQuestions = [];
      for (AQuestion q1 <- ifQuestions) {
        newQuestions += flatten(q1, and(newGuard, guard));
      }
      for (AQuestion q2 <- elseQuestions) {
        newQuestions += flatten(q2, and(newGuard, not(guard)));
      }
      return newQuestions;
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      list[AQuestion] newQuestions = [];
      for (AQuestion q1 <- ifQuestions) {
        newQuestions += flatten(q1, and(newGuard, guard));
      }
      return newQuestions;
    }
    default: return [ifstm(newGuard, [q])];
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */

start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  loc def;
  for (tuple[loc, loc] t <- useDef) {
    if (t<0> == useOrDef || t<1> == useOrDef) {
      def = t<1>;
      break;
    }
  }

  set[loc] locations = {def};
  for (tuple[loc, loc] t <- useDef) {
    if (t<1> == def) {
      locations += t<0>;
    }
  }

  return visit(f) {
    case Id name => {
      if(name.src in locations) parse(#Id, newName);
      else name;
    }
  };
}