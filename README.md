# lua-parser

A Lua 5.3 parser and AST walker using ANTLR 3.

The grammar can be found in 
[`src/main/antlr3/nl/bigo/luaparser`](https://github.com/bkiers/lua-parser/tree/master/src/main/antlr3/nl/bigo/luaparser).

Seeing the generated parser in action can be done by building
a *fat* JAR of the project and then running it to parse a Lua
file.

# Get started

### 1. clone this repository

```bash
git clone https://github.com/bkiers/lua-parser
cd lua-parser
```

### 2. generate the lexer and parser classes and build a *fat* JAR

```bash
mvn clean install package
```

### 3. parse a Lua file

```bash
java -jar target/lua-parser-0.1.0.jar src/main/lua/test.lua
```

which would print:

```
Parsing `src/main/lua/test.lua`...

'- CHUNK
   '- ASSIGNMENT
      |- VAR_LIST
      |  '- Name='uniqueid_some_event'
      '- EXPR_LIST
         '- FUNCTION
            |- PARAM_LIST
            |  '- Name='e'
            '- CHUNK
               |- If='if'
               |  '- CONDITION
               |     |- VAR
               |     |  |- Name='e'
               |     |  |- INDEX
               |     |  |  '- String='HasString'
               |     |  '- COL_CALL
               |     |     '- String='string1'
               |     '- CHUNK
               '- If='if'
                  '- CONDITION
                     |- VAR
                     |  |- Name='e'
                     |  |- INDEX
                     |  |  '- String='HasString'
                     |  '- COL_CALL
                     |     '- String='string2'
                     '- CHUNK

> from Lua52Walker.assignment
>   VAR_LIST=uniqueid_some_event
>   EXPR_LIST=FUNCTION
```

given that the file `src/main/lua/test.lua` contains:

```lua
function uniqueid_some_event (e)
  if (e:HasString("string1")) then
    -- do something
  end 
  if(e:HasString("string2")) then
    -- do something
  end
end
```
