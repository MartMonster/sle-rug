module Transform

import Syntax;
import Resolve;
import AST;

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
    switch (q) {
      case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
        for (AQuestion q1 <- ifQuestions) {
          switch (q1) {
            case ifstm(AExpr guard1, list[AQuestion] ifQuestions1, list[AQuestion] elseQuestions1): {
              newList += ifstm(guard && guard1, ifQuestions1, elseQuestions1); // dit maar dan dus recursive en voor alles. succes.
            }
          }
        }
      }
      case ifstm(AExpr guard, list[AQuestion] ifQuestions): ;
      default: newList += q;
    }
  }
  return form("<f.name>", newList, src=f.src); 
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
} 
 
 
 

