module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

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

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  list[HTMLElement] elems = [text(f.name)];
  for (AQuestion q <- f.questions) {
    elems += questionToHtml(q, 0);
  }
  return html([body([h1(elems)])]);
}

tuple[HTMLElement, int] questionToHtml(AQuestion q, int ifCount) {
  switch (q) {
    case question(str question, AId id, AType t, AExpr assignvalue): return <div([h2([text(question)]), label([text(id.name)]), inputTypeOfzoIGuess(t, id)]), ifCount>; // TODO: dit is geen input
    case question(str question, AId id, AType t): return <div([h2([text(question)]), label([text(id.name)]), inputTypeOfzoIGuess(t, id)]), ifCount>;
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      ifCount += 1;
      int ifCountOld = ifCount;
      list[HTMLElement] ifElems = [];
      for (AQuestion q <- ifQuestions) {
        tuple[HTMLElement, int] t = questionToHtml(q, ifCount);
        ifCount = t<1>;
        ifElems += t<0>;
      }
      list[HTMLElement] elseElems = [];
      for (AQuestion q <- elseQuestions) {
        tuple[HTMLElement, int] t = questionToHtml(q, ifCount);
        ifCount = t<1>;
        elseElems += t<0>;
      }
      return <div([div([h3([text("if<ifCountOld>")]), ifElems], id="if<ifCountOld>"), div([h3([text("else<ifCountOld>")]), elseElems], id="else<ifCountOld>")]), ifCount>;
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      ifCount += 1;
      int ifCountOld = ifCount;
      list[HTMLElement] ifElems = [];
      for (AQuestion q <- ifQuestions) {
        ifElems += questionToHtml(q, ifCount);
      }
      return <div([h3([text("if<ifCountOld>")]), ifElems], id="if<ifCountOld>"), ifCount>;
    }
  }
  return (<unknownElement([]), ifCount>);
}

HTMLElement inputTypeOfzoIGuess(AType t, AId id) {
  switch (t.name) {
    case "boolean": return input(id=id.name, \type="checkbox");
    case "string": return input(id=id.name, \type="text");
    case "integer": return input(id=id.name, \type="number");
  }
  return unknownElement([]);
}

str form2js(AForm f) {
  return "";
}
