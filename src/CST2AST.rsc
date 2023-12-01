module CST2AST

import Syntax;
import AST;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("<f.name>", [cst2ast(q) | Question q <- f.questions], src=f.src); 
}

default AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str question2> <Id name> : <Type t> = <Expr exp>`: return question("<question2>", id("<name>"), cst2ast(t), cst2ast(exp), src=q.src);
    case (Question)`<Str question2> <Id name> : <Type t>`: return question("<question2>", id("<name>"), cst2ast(t), src=q.src);
    case (Question)`if ( <Expr guard> ) { <Question* ifQuestions> } else { <Question* elseQuestions> }`: return ifstm(cst2ast(guard), [cst2ast(q) | Question q <- ifQuestions], [cst2ast(q) | Question q <- elseQuestions], src=q.src);
    case (Question)`if ( <Expr guard> ) { <Question* ifQuestions> }`: return ifstm(cst2ast(guard), [cst2ast(q) | Question q <- ifQuestions], src=q.src);
  }
  throw "Unhandled question: <q>";
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  throw "Not yet implemented <t>";
}
