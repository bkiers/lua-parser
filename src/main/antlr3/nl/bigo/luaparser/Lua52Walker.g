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
tree grammar Lua52Walker;

options {
 tokenVocab=Lua52;
 ASTLabelType=CommonTree;
}

@header {
  package nl.bigo.luaparser;
}

walk
 : chunk
 ;

chunk
 : ^(CHUNK stat* ret_stat?)
 ;

stat
 : assignment
 | var[true]
 | do_block
 | while_stat
 | repeat_stat
 | local
 | if_stat
 | for_stat
 | label
 | goto_stat
 | Break
 ;

do_block
 : ^(Do chunk)
 ;

while_stat
 : ^(While expr do_block)
 ;

repeat_stat
 : ^(Repeat chunk expr)
 ;

assignment
 : ^(ASSIGNMENT ^(VAR_LIST e1=expr_list) ^(EXPR_LIST e2=expr_list))
   {
     System.out.println("> from Lua52Walker.assignment");
     System.out.println(">   VAR_LIST=" + $e1.start.getText());
     System.out.println(">   EXPR_LIST=" + $e2.start.getText());
   }
 ;

local
 : ^(LOCAL_ASSIGNMENT ^(NAME_LIST a=name_list) ^(EXPR_LIST b=expr_list))
 ;

goto_stat
 : ^(Goto Name)
 ;

if_stat
 : ^(If (^(CONDITION expr chunk))+)
 ;

for_stat
 : ^(For Name expr expr expr? do_block)
 | ^(FOR_IN ^(NAME_LIST name_list) ^(EXPR_LIST expr_list) do_block)
 ;

function_literal
 : ^(FUNCTION ^(PARAM_LIST name_list? DotDotDot?) chunk)
 ;

ret_stat
 : ^(Return expr_list?)
 ;

expr
 : ^(Or a=expr b=expr)
 | ^(And a=expr b=expr)
 | ^(LT a=expr b=expr)
 | ^(GT a=expr b=expr)
 | ^(LTEq a=expr b=expr)
 | ^(GTEq a=expr b=expr)
 | ^(NEq a=expr b=expr)
 | ^(Eq a=expr b=expr)
 | ^(BitOr a=expr b=expr)
 | ^(Tilde a=expr b=expr) // bitwise exclusive OR
 | ^(BitAnd a=expr b=expr)
 | ^(BitRShift a=expr b=expr)
 | ^(BitLShift a=expr b=expr)
 | ^(DotDot a=expr b=expr)
 | ^(Add a=expr b=expr)
 | ^(Minus a=expr b=expr)
 | ^(Mult a=expr b=expr)
 | ^(Div a=expr b=expr)
 | ^(FloorDiv a=expr b=expr)
 | ^(Mod a=expr b=expr)
 | ^(Pow a=expr b=expr)
 | ^(UNARY_MINUS a=expr)
 | ^(Length a=expr)
 | ^(Not a=expr)
 | ^(BIT_NOT a=expr)
 | Name
 | DotDotDot
 | Number
 | String
 | Nil
 | True
 | False
 | var[false]
 | assignment_var
 | function_literal
 | table_constructor
 ;

var[boolean noReturn]
 : ^(VAR expr tail+)
 ;

assignment_var
 : ^(ASSIGNMENT_VAR expr tail+)
 ;

tail
 : ^(INDEX expr)
 | ^(CALL expr_list?)
 | ^(COL_CALL expr_list?)
 ;

table_constructor
 : ^(TABLE field*)
 ;

field
 : ^(FIELD a=expr b=expr?)
 ;

label
 : ^(LABEL Name)
 ;

expr_list
 : expr+
 ;

name_list
 : Name+
 ;