/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 by Bart Kiers
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Project      : lua-parser; a Lua 5.2 grammar/parser
 * Developed by : Bart Kiers, bart@big-o.nl
 */
grammar Lua52;

options {
 output=AST;
 ASTLabelType=CommonTree;
}

tokens {
  // literals
  And       = 'and';
  Break     = 'break';
  Do        = 'do';
  Else      = 'else';
  Elseif    = 'elseif';
  End       = 'end';
  False     = 'false';
  For       = 'for';
  Function  = 'function';
  Goto      = 'goto';
  If        = 'if';
  In        = 'in';
  Local     = 'local';
  Nil       = 'nil';
  Not       = 'not';
  Or        = 'or';
  Repeat    = 'repeat';
  Return    = 'return';
  Then      = 'then';
  True      = 'true';
  Until     = 'until';
  While     = 'while';
  Add       = '+';
  Minus     = '-';
  Mult      = '*';
  Div       = '/';
  FloorDiv  = '//';
  Mod       = '%';
  Pow       = '^';
  Length    = '#';
  Eq        = '==';
  NEq       = '~=';
  LTEq      = '<=';
  GTEq      = '>=';
  BitRShift = '>>';
  BitLShift = '<<';
  BitAnd    = '&';
  BitOr     = '|';
  Tilde     = '~';
  LT        = '<';
  GT        = '>';
  Assign    = '=';
  OPar      = '(';
  CPar      = ')';
  OBrace    = '{';
  CBrace    = '}';
  OBrack    = '[';
  CBrack    = ']';
  ColCol    = '::';
  SCol      = ';';
  Col       = ':';
  Comma     = ',';
  DotDotDot = '...';
  DotDot    = '..';
  Dot       = '.';

  // imaginary tokens
  ASSIGNMENT;
  LOCAL_ASSIGNMENT;
  CONDITION;
  UNARY_MINUS;
  BIT_NOT;
  CALL;
  COL_CALL;
  INDEX;
  EXPR_LIST;
  VAR_LIST;
  CHUNK;
  NAME_LIST;
  LABEL;
  TABLE;
  FIELD_LIST;
  FIELD;
  FOR_IN;
  PARAM_LIST;
  FUNCTION;
  ASSIGNMENT_VAR;
  VAR;
}

@parser::header {
  package nl.bigo.luaparser;
}

@lexer::header {
  package nl.bigo.luaparser;
  import java.math.*;
}

@parser::members {

  private boolean addSelf = false;
  
  private CommonTree createPowAST(List tokens) {
    int n = tokens.size();
    
    CommonTree ast = new CommonTree(new CommonToken(Pow, "^"));
    ast.addChild((CommonTree)tokens.get(n - 2));
    ast.addChild((CommonTree)tokens.get(n - 1));
    
    for(int i = n - 3; i >= 0; i--) {
      CommonTree temp = new CommonTree(new CommonToken(Pow, "^"));
      temp.addChild((CommonTree)tokens.get(i));
      temp.addChild(ast);
      ast = temp;
    }
    
    return ast;
  }
  
  private CommonTree namesToVar(List<String> names, String name) {
    names.add(name);
    return namesToVar(names);
  }
  
  private CommonTree namesToVar(List<String> names) {

    if(names.size() == 1) {
      return new CommonTree(new CommonToken(Name, names.get(0)));
    }
    
    CommonTree ast = new CommonTree(new CommonToken(VAR, "VAR"));
    
    ast.addChild(new CommonTree(new CommonToken(Name, names.get(0))));
    
    for(int i = 1; i < names.size(); i++) {
      CommonTree indexNode = new CommonTree(new CommonToken(INDEX, "INDEX"));
      indexNode.addChild(new CommonTree(new CommonToken(Name, names.get(i))));
      ast.addChild(indexNode);
    }
    
    return ast;
  }
  
  @Override
  public void reportError(RecognitionException e) {
    throw new RuntimeException(e); 
  }
}

@lexer::members {

  private boolean ahead(CharSequence chars) {
    for(int i = 0; i < chars.length(); i++) {
      if(input.LA(i + 1) != chars.charAt(i)) {        
        return false;
      }
    }
    return true;
  }

  @Override
  public void reportError(RecognitionException e) {
    throw new RuntimeException(e); 
  }

  private String unescape(String text) {
    StringBuilder b = new StringBuilder();
    String regex = "\\\\([\\\\abfnrtv\"']|\r?\n|\r|\\d{1,3}|x[0-9a-fA-F]{2}|z\\s*)|(?s).";
    java.util.regex.Matcher m = java.util.regex.Pattern.compile(regex).matcher(text);
    while(m.find()) {
      if(m.group(1) != null) {
        // an escaped char
        String matched = m.group(1);
        if(matched.equals("\\")) b.append("\\");
        else if(matched.equals("a")) b.append("\u0007");
        else if(matched.equals("b")) b.append("\u0008");
        else if(matched.equals("f")) b.append("\u000C");
        else if(matched.equals("n")) b.append("\n");
        else if(matched.equals("r")) b.append("\r");
        else if(matched.equals("t")) b.append("\t");
        else if(matched.equals("v")) b.append("\u000B");
        else if(matched.equals("\"")) b.append("\"");
        else if(matched.equals("'")) b.append("'");
        else if(matched.matches("\r?\n|\r")) b.append(matched);
        else if(matched.matches("\\d{1,3}")) b.append((char)Integer.parseInt(matched));
        else if(matched.matches("x[0-9a-fA-F]{2}")) b.append((char)Integer.parseInt(matched.substring(1), 16));
        else if(matched.equals("z\\s*")) { /* do nothing, remove from string */ }
      }
      else {
        // a normal char, append "as is"
        b.append(m.group());
      }
    }
    return b.toString();
  }
}

//////////////////////////////// parser rules //////////////////////////////// 
parse
 : chunk EOF -> chunk
   //(t=. {System.out.printf("\%-15s '\%s'\n", tokenNames[$t.type], $t.text);})* EOF
 ;

chunk
 : stat* ret_stat? -> ^(CHUNK stat* ret_stat?)
 ;

stat
 : (assignment)=> assignment
 | var[false]                         // must be a function call, not an index: check and throw exception
 | do_block 
 | while_stat
 | repeat_stat
 | local
 | goto_stat
 | if_stat
 | for_stat
 | function
 | label
 | Break
 | ';' -> /* remove from AST (empty rewrite rule) */
 ;

do_block
 : Do chunk End -> ^(Do chunk)
 ;

while_stat
 : While expr do_block -> ^(While expr do_block)
 ;

repeat_stat
 : Repeat chunk Until expr -> ^(Repeat chunk expr) 
 ;

assignment
 : var_list '=' expr_list // in every 'var' in 'var_list', the last must be an 'index', not a 'call'
   -> ^(ASSIGNMENT ^(VAR_LIST var_list) ^(EXPR_LIST expr_list))
 ;

local
 : Local ( name_list '=' expr_list -> ^(LOCAL_ASSIGNMENT ^(NAME_LIST name_list) ^(EXPR_LIST expr_list))
         | Function Name func_body -> ^(LOCAL_ASSIGNMENT ^(NAME_LIST Name) ^(EXPR_LIST func_body))
         )
 ;

goto_stat
 : Goto Name -> ^(Goto Name)
 ;

if_stat
 : If expr Then chunk elseif_stat* else_stat? End -> ^(If ^(CONDITION expr chunk) elseif_stat* else_stat?)
 ;

elseif_stat
 : Elseif expr Then chunk -> ^(CONDITION expr chunk)
 ;

else_stat
 : Else chunk -> ^(CONDITION True chunk)
 ;

for_stat
 : For ( Name '=' a=expr ',' b=expr (',' c=expr)? do_block -> ^(For Name $a $b $c? do_block)
       | name_list In expr_list do_block                   -> ^(FOR_IN ^(NAME_LIST name_list) ^(EXPR_LIST expr_list) do_block)
       )
 ;

function
 : Function names ( Col Name {addSelf=true;} func_body {addSelf=false;} 
                    -> ^(ASSIGNMENT ^(VAR_LIST {namesToVar($names.list, $Name.text)}) ^(EXPR_LIST func_body))
                  | func_body
                    -> ^(ASSIGNMENT ^(VAR_LIST {namesToVar($names.list)}) ^(EXPR_LIST func_body))
                  )
 ;

names returns [List<String> list]
@init{$list = new ArrayList<String>();}
 : a=Name {$list.add($a.text);} ('.' b=Name {$list.add($b.text);})*
 ;

function_literal
 : Function func_body -> func_body
 ;

func_body
 : '(' param_list ')' chunk End -> ^(FUNCTION param_list chunk)
 ;

param_list
 : name_list (',' DotDotDot)? -> ^(PARAM_LIST name_list DotDotDot?)
 | DotDotDot?                 -> ^(PARAM_LIST DotDotDot?)
 ;

ret_stat
 : Return expr_list? ';'? -> ^(Return expr_list?)
 ;

/*
3.4.8 – Precedence

Operator precedence in Lua follows the table below, from lower to higher priority:

     or
     and
     <     >     <=    >=    ~=    ==
     |
     ~
     &
     <<    >>
     ..
     +     -
     *     /     //    %
     unary operators (not   #     -     ~)
     ^

https://www.lua.org/manual/5.3/manual.html
*/
expr
 : or_expr
 ;

or_expr
 : and_expr (Or^ and_expr)*
 ;

and_expr
 : rel_expr (And^ rel_expr)*
 ;

rel_expr
 : bit_or_expr ((LT | GT | LTEq | GTEq | NEq | Eq)^ bit_or_expr)?
 ;

bit_or_expr
 : bit_excl_or_expr (BitOr^ bit_excl_or_expr)*
 ;

bit_excl_or_expr
 : bit_and_expr (Tilde^ bit_and_expr)*
 ;

bit_and_expr
 : bit_shift_expr (BitAnd^ bit_shift_expr)*
 ;

bit_shift_expr
 : concat_expr ((BitRShift | BitLShift)^ concat_expr)*
 ;

concat_expr
 : add_expr (DotDot^ add_expr)*
 ;

add_expr
 : mult_expr ((Add | Minus)^ mult_expr)*
 ;

mult_expr
 : unary_expr ((Mult | Div | Mod | FloorDiv)^ unary_expr)*
 ;

unary_expr
 : Minus unary_expr -> ^(UNARY_MINUS unary_expr)
 | Length pow_expr  -> ^(Length pow_expr)
 | Not unary_expr   -> ^(Not unary_expr)
 | Tilde pow_expr   -> ^(BIT_NOT pow_expr)
 | pow_expr
 ;

// right associative
pow_expr
 : (a+=atom -> $a) ((Pow a+=atom)+ -> {createPowAST($a)})?
 ;

atom
 : var[false]
 | function_literal
 | table_constructor
 | DotDotDot 
 | Number
 | String
 | Nil
 | True
 | False
 ;

var[boolean assign]
 : (callee[assign] -> callee) ( (tail)=> (((tail)=> t=tail)+ -> {assign}? ^(ASSIGNMENT_VAR callee tail+)
                                                             ->           ^(VAR callee tail+))
                              )?
 ;

callee[boolean assign]
 : '(' expr ')' -> expr
 | Name
 ;

tail
 : '.' Name                    -> ^(INDEX String[$Name.text])
 | '[' expr ']'                -> ^(INDEX expr)
 | ':' Name '(' expr_list? ')' -> ^(INDEX {new CommonTree(new CommonToken(String, $Name.text))}) ^(COL_CALL expr_list?)
 | ':' Name table_constructor  -> ^(INDEX {new CommonTree(new CommonToken(String, $Name.text))}) ^(COL_CALL table_constructor)
 | ':' Name String             -> ^(INDEX {new CommonTree(new CommonToken(String, $Name.text))}) ^(COL_CALL String)
 | '(' expr_list? ')'          -> ^(CALL expr_list?)
 | table_constructor           -> ^(CALL table_constructor)
 | String                      -> ^(CALL String)
 ;

table_constructor
 : '{' field_list? '}' -> ^(TABLE field_list?)
 ;

field_list
 : field (field_sep field)* field_sep? -> field+
 ;

field
 : '[' expr ']' '=' expr -> ^(FIELD expr expr)
 | Name '=' expr         -> ^(FIELD {new CommonTree(new CommonToken(String, $Name.text))} expr)
 | expr                  -> ^(FIELD expr)
 ;

field_sep
 : ',' 
 | ';'
 ;

label
 : '::' Name '::' -> ^(LABEL Name)
 ;

var_list
 : var[true] (',' var[true])* -> var+
 ;

expr_list
 : expr (',' expr)* -> expr+
 ;

name_list
 : Name (',' Name)* -> {addSelf}? {new CommonTree(new CommonToken(Name, "self"))} Name+
                    ->            Name+
 ;

//////////////////////////////// lexer rules //////////////////////////////// 
Name
 : (Letter | '_') (Letter | '_' | Digit)*
 ;

Number
 : (Digit+ ('.' Digit*)? Exponent? | '.' Digit+ Exponent?)    {setText(new java.math.BigDecimal($text).toPlainString().replaceAll("\\.0*$", ""));}
 | '0' ('x' | 'X') a=HexDigits ('.' b=HexDigits?)? c=BinaryExponent? 
   {
     double num = Long.parseLong($a.text, 16);
     
     if($b != null) {
       double fraction = Long.parseLong($b.text, 16) / Math.pow(16, $b.text.length());
       num += fraction;
     }
     
     if($c != null) {
       int binExp = Integer.valueOf($c.text.contains("+") ? $c.text.substring(2) : $c.text.substring(1));
       for(int i = 0; i < Math.abs(binExp); i++) {
         num = binExp < 0 ? num/2 : num*2;
       }
     }
     
     setText(new BigDecimal(Double.toString(num)).toPlainString().replaceAll("\\.0*$", ""));
   }
 ;

String
 : '"'  (EscapeSequence | ~('\\' | '"'  | '\r' | '\n'))* '"'  {setText(unescape($text.substring(1, $text.length()-1)));}
 | '\'' (EscapeSequence | ~('\\' | '\'' | '\r' | '\n'))* '\'' {setText(unescape($text.substring(1, $text.length()-1)));}
 | LongBracket                                                {setText($text.replaceAll("^\\[=*\\[|]=*]$", ""));}
 ;
 
//////////////////////////////// lexer rules to skip //////////////////////////////// 
Comment
 : '--' ( LongBracket
        | '[' '='* ~('=' | '[') ~('\r' | '\n')* // matches '--[=====...' as a single line comment
        | (~'[' ~('\r' | '\n')*)?
        )
        {skip();}
 ;

Space
 : (' ' | '\t' | '\r' | '\n' | '\u000C')+ {skip();}
 ;

//////////////////////////////// fragment lexer rules //////////////////////////////// 
fragment Letter
 : 'a'..'z' 
 | 'A'..'Z'
 ;

fragment Digit
 : '0'..'9'
 ;

fragment HexDigit
 : Digit
 | 'a'..'f'
 | 'A'..'F'
 ;

fragment HexDigits
 : HexDigit+
 ;

fragment Exponent
 : ('e' | 'E') ('-' | '+')? Digit+
 ;

fragment BinaryExponent
 : ('p' | 'P') ('-' | '+')? Digit+
 ;

fragment EscapeSequence
 : '\\' ( ('a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v' | '\\' | '"' | '\'' | 'z' | LineBreak)
        | Digit (Digit Digit?)?
        | 'x' HexDigit HexDigit
        )
 ;

fragment LineBreak
 : '\r'? '\n'
 | '\r' 
 ;

fragment LongBracket
@init{StringBuilder b = new StringBuilder("]");}
 :
   // match opening bracket and build equal sized closing bracket
   '[' ('=' {b.append("=");})* '[' {b.append("]");}
   
   // keep matching chars until the closing bracket is ahead
   ({!ahead(b)}?=> (~'\\' | EscapeSequence) )*
   
   {
     if(input.LA(1) == EOF) {
       throw new RuntimeException("unfinished long comment or string near '<eof>'");
     }
     
     // let the lexer match the closing bracket
     match(b.toString());
   }
                              
 ; 

//////////////////////////////// a fall through rule throwing an exception //////////////////////////////// 
Any
@after {throw new RuntimeException("unexpected symbol near: '" + $text + "'");}
 : .
 ;
