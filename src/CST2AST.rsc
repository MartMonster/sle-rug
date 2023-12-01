module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

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
    case (Expr)`<Int n>`: return integer(toInt("<n>"), src=n.src);
    case (Expr)`<Str s>`: return string("<s>", src=s.src);
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b.src);
    case (Expr)`<Expr e1> + <Expr e2>`: return add(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> - <Expr e2>`: return sub(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> * <Expr e2>`: return mul(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> / <Expr e2>`: return div(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> || <Expr e2>`: return or(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> && <Expr e2>`: return and(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> == <Expr e2>`: return eq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> != <Expr e2>`: return neq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \< <Expr e2>`: return lt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \> <Expr e2>`: return gt(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \<= <Expr e2>`: return leq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`<Expr e1> \>= <Expr e2>`: return geq(cst2ast(e1), cst2ast(e2), src=e.src);
    case (Expr)`- <Expr e>`: return neg(cst2ast(e), src=e.src);
    case (Expr)`! <Expr e>`: return not(cst2ast(e), src=e.src);

    
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  return typeName("<t>", src=t.src);
}