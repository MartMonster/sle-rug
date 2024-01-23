module Compile

import AST;
import Resolve;
import Eval;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import String;
import List;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

VEnv venv;

void compile(AForm f) {
  venv = initialEnv(f);
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  list[HTMLElement] elems = [h1([text(f.name)])];
  int ifCount = 0;
  for (AQuestion q <- f.questions) {
    tuple[HTMLElement, int] t = questionToHtml(q, ifCount);
    elems += t<0>;
    ifCount = t<1>;
  }
  jsFileName = split("/", "<f.src[extension="js"].top>")[-1];
  return html([script([], src=substring(jsFileName, 0, size(jsFileName)-1)), body(elems), script([text("update();\n")])]);
}

tuple[HTMLElement, int] questionToHtml(AQuestion q, int ifCount) {
  switch (q) {
    case question(str question, AId id, AType t, AExpr assignvalue): return <div([h2([text(question)]), label([text("<id.name>")]), p([text("test")], id="<id.name>")]), ifCount>;
    case question(str question, AId id, AType t): return <div([h2([text(question)]), label([text(id.name)]), inputTypeOfzoIGuess(t, id)]), ifCount>;
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      ifCount += 1;
      int ifCountOld = ifCount;
      list[HTMLElement] ifElems = [h3([text("if<ifCountOld>")])];
      for (AQuestion q <- ifQuestions) {
        tuple[HTMLElement, int] t = questionToHtml(q, ifCount);
        ifCount = t<1>;
        ifElems += t<0>;
      }
      list[HTMLElement] elseElems = [h3([text("else<ifCountOld>")])];
      for (AQuestion q <- elseQuestions) {
        tuple[HTMLElement, int] t = questionToHtml(q, ifCount);
        ifCount = t<1>;
        elseElems += t<0>;
      }
      return <div([div(ifElems, id="if<ifCountOld>", style="display: none;"), div(elseElems, id="else<ifCountOld>", style="display: none;")]), ifCount>;
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      ifCount += 1;
      int ifCountOld = ifCount;
      list[HTMLElement] ifElems = [h3([text("if<ifCountOld>")])];
      for (AQuestion q <- ifQuestions) {
        ifElems += questionToHtml(q, ifCount)<0>;
      }
      return <div(ifElems, id="if<ifCountOld>", style="display: none;"), ifCount>;
    }
}
  return (<unknownElement([]), ifCount>);
}

HTMLElement inputTypeOfzoIGuess(AType t, AId id) {
  switch (t.name) {
    case "boolean": return input(id=id.name, \type="checkbox", onchange="update()");
    case "string": return input(id=id.name, \type="text", onchange="update()");
    case "integer": return input(id=id.name, \type="number", onchange="update()");
  }
  return unknownElement([]);
}

tuple[str, int] visitQuestions(list[AQuestion] qs, int ifCount) {
  str result = "";
  for (AQuestion q <- qs) {
    tuple[str, int] t = visitQuestion(q, ifCount);
    result += t<0>;
    ifCount = t<1>;
  }
  return <result, ifCount>;
}

tuple[str, int] visitQuestion(AQuestion q, int ifCount) {
  str result = "";
  switch (q) {
    case question(str question, AId id, AType t, AExpr assignvalue): {
      result += "document.getElementById(\"<id.name>\").innerHTML = <exprToStr(assignvalue)>;\n";
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      ifCount += 1;
      result += "if (<exprToStr(guard)>) {\n";
      result += "document.getElementById(\"if<ifCount>\").style.display = \"block\";\n";
      result += "document.getElementById(\"else<ifCount>\").style.display = \"none\";\n";
      result += "} else {\n";
      result += "document.getElementById(\"if<ifCount>\").style.display = \"none\";\n";
      result += "document.getElementById(\"else<ifCount>\").style.display = \"block\";\n";
      result += "}\n";
      tuple[str, int] ifQuestionsResult = visitQuestions(ifQuestions, ifCount);
      result += ifQuestionsResult<0>;
      ifCount = ifQuestionsResult<1>;
      tuple[str, int] elseQuestionsResult = visitQuestions(elseQuestions, ifCount);
      result += elseQuestionsResult<0>;
      ifCount = elseQuestionsResult<1>;
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      ifCount += 1;
      result += "if (<exprToStr(guard)>) {\n";
      result += "document.getElementById(\"if<ifCount>\").style.display = \"block\";\n";
      result += "} else {\n";
      result += "document.getElementById(\"if<ifCount>\").style.display = \"none\";\n";
      result += "}\n";
      tuple[str, int] ifQuestionsResult = visitQuestions(ifQuestions, ifCount);
      result += ifQuestionsResult<0>;
      ifCount = ifQuestionsResult<1>;
    }
  }
  return <result, ifCount>;
}

str exprToStr(AExpr e) {
  switch (e) {
    case ref(id(str x)): return "getTypeThing(document.getElementById(\"<x>\"))";
    case string(str x): return x;
    case integer(int x): return "<x>";
    case boolean(bool x): return "<x>";
    case neg(AExpr expr): return "-" + exprToStr(expr);
    case mul(AExpr left, AExpr right): return exprToStr(left) + "*" + exprToStr(right);
    case div(AExpr left, AExpr right): return exprToStr(left) + "/" + exprToStr(right);
    case add(AExpr left, AExpr right): return exprToStr(left) + "+" + exprToStr(right);
    case sub(AExpr left, AExpr right): return exprToStr(left) + "-" + exprToStr(right);
    case and(AExpr left, AExpr right): return exprToStr(left) + "&&" + exprToStr(right);
    case or(AExpr left, AExpr right): return exprToStr(left) + "||" + exprToStr(right);
    case eq(AExpr left, AExpr right): return exprToStr(left) + "==" + exprToStr(right);
    case neq(AExpr left, AExpr right): return exprToStr(left) + "!=" + exprToStr(right);
    case lt(AExpr left, AExpr right): return exprToStr(left) + "\<" + exprToStr(right);
    case leq(AExpr left, AExpr right): return exprToStr(left) + "\<=" + exprToStr(right);
    case gt(AExpr left, AExpr right): return exprToStr(left) + "\>" + exprToStr(right);
    case geq(AExpr left, AExpr right): return exprToStr(left) + "\>=" + exprToStr(right);
    case not(AExpr expr): return "!" + exprToStr(expr);
    default: throw "Unsupported expression <e>";
  }
}

str form2js(AForm f) {
  str jsString = "";
  jsString += "function getTypeThing(e) {\n";
  jsString += "switch (e.type) {\n";
  jsString += "case \"checkbox\": return e.checked;\n";
  jsString += "default: return e.value;\n";
  jsString += "}\n";
  jsString += "}\n";
  jsString += "function update() {\n";
  int ifCount = 0;
  jsString += visitQuestions(f.questions, 0)<0>;
  return jsString + "}";
}
