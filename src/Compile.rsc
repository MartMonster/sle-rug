module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import String;

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
  list[HTMLElement] elems = [h1([text(f.name)])];
  for (AQuestion q <- f.questions) {
    elems += questionToHtml(q, 0)<0>;
  }
  jsFileName = split("/", "<f.src[extension="js"].top>")[-1];
  return html([script([], src=substring(jsFileName, 0, size(jsFileName)-1)), body(elems)]);
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

str form2js(AForm f) {
  jsString = "function update() {\n";
  int ifCount = 0;
  visit (f) {
    case question(str question, AId id, AType t, AExpr assignvalue): {
      jsString += "document.getElementById(\"<id.name>\").innerHTML = <assignvalue>; ";
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      ifCount += 1;
      jsString += "if (<guard>) {\n";
      jsString += "document.getElementById(\"if<ifCount>\").style.display = \"block\";\n";
      jsString += "document.getElementById(\"else<ifCount>\").style.display = \"none\";\n";
      jsString += "} else {\n";
      jsString += "document.getElementById(\"if<ifCount>\").style.display = \"none\";\n";
      jsString += "document.getElementById(\"else<ifCount>\").style.display = \"block\";\n";
      jsString += "}\n";
    }
    case ifstm(AExpr guard, list[AQuestion] ifQuestions): {
      ifCount += 1;
      jsString += "if (<guard>) {\n";
      jsString += "document.getElementById(\"if<ifCount>\").style.display = \"block\";\n";
      jsString += "} else {\n";
      jsString += "document.getElementById(\"if<ifCount>\").style.display = \"none\";\n";
      jsString += "}\n";
    }
  }
  return jsString + "}";
}
