# ALL CAPS BASIC

ALL CAPS BASIC (tentative name, since it no longer requires the source code to be in all caps) is a compiler written in [Awk](https://en.wikipedia.org/wiki/AWK). It compiles a statically typed, garbage-collected Basic-like programming language to native code through [modern C](https://en.wikipedia.org/wiki/C99). It is intended to be a kind of working model compiler each piece of which is transparent. For this reason all data formats used by the compiler are text-based.

**Warning!** This is **very much** a work in progress and incomplete. Please do **not** submit it to Hacker News, Reddit, etc.

The source code is compiled in three phases. Because Awk does not support data structures other than (non-nestable) dictionaries no parse tree is built.

| Phase | Component | Input | Output |
|-------|-----------|-------|--------|
| Lexical analysis | [lexer.awk](./lexer.awk) | ACB source code | Token file |
| Parsing | [parser.awk](./parser.awk) | Token file | Intermediate representation (IR) file |
| Type checking and code generation | [codegen.awk](./codegen.awk) | IR file | C source code |

Run

```shell
./run.sh -v test/test00.bas
```

in this repository to see the output at every stage.

This project was initially inspired by [BaCon](http://basic-converter.org/), Niklaus Wirth's [Oberon-0 \[pdf\]](http://www.ethoberon.ethz.ch/WirthPubl/CBEAll.pdf) and the Awk compiler for [Mercat](http://cowlark.com/mercat/).

The syntax is largely taken from the manuals for Visual Basic 6 and [Gambas](http://gambas.sourceforge.net/). The syntax and the semantics may differ from those two languages, however, both intentionally and not (the developer has hardly used them).

## Sample code

```basic
sub repeat(s as string, n) as string
    let result = ""
    for i = 1 to n
        let result = result & s
    end
    return result
end

sub main()
    let s = "Ha"
    print repeat(s, 3)
end
```

## Language grammar

The parser is hand-written, so this may not be accurate. It does not account for comments; those can be thought of as removed at a separate, line-based parsing stage.

Below `?` means zero or one occurrence, `*` means zero or more occurrences and `/.../` means a regular expression.


```
file = (sub | sub_declaration)*
sub = "SUB", sub_header, statement_list, "end"
sub_declaration = "DECLARE", sub_header
sub_header = "SUB", ident_maybe_type, "(", (ident_maybe_type, ",")*, ")", ("AS", ident)?
ident = /[a-zA-Z0-9][a-zA-Z0-9_]*/
ident_maybe_type = ideat, ("AS", ident)?
statement_list = nl, ((statement, nl)*, statement)?
statement = assignment | "BREAK" | conditional | "CONTINUE" | declaration | expression | for_loop | return | subcall | while_loop
assignment = "LET", ident, "=", expression
conditional = "IF", expression, statement_list, "END"
declaration = "DIM", ident, "AS", ident
for_loop = "FOR", ident, "=", expression, "TO", expression, statement_list, "END"
return = "RETURN", expression
subcall = ident, "(", expression, (expression, ",")*, ")"
while_loop = "WHILE", expression, statement_list, "END"
expression = ("(", expression_core, ")") | expression_core
expression_core = ident | (unary_operator, expression) | ((ident | expression), binary_operator, (ident | expression))
binary_operator = "OR" | "AND" | "=" | "<>" | "<" | ">" | "<=" | ">=" | "+" | "-" | "*" | "/" | "%" | "&"
unary_operator = "NOT"
nl = nl_atom, nl_atom*
nl_atom = \n | ":"
```

## IR opcodes

### Legend

| Symbol | Meaning |
|--------|---------|
| `byref?` | Either the text "BYREF" or nothing |
| `func` | Function identifier |
| `op[N]` | Either variable identifier or literal |
| `label` | Label identifier |
| `n` | Integer literal |
| `res` | Variable identifier |
| `type` | Type identifier |
| `var` | Variable identifier |

### List

```
ARG var type byref?
DECLARE
DIM var type
ENDSUB
INCR var n
JT/JF label ident
JMP label
LABEL label
PRINT op1 op2 ... opN
RETTYPE type
RETURN var
SET res op1
SET+ res op1 op2
SET- res op1 op2
SET/ res op1 op2
SET* res op1 op2
SET% res op1 op2
SET= res op1 op2
SET< res op1 op2
SET> res op1 op2
SET<> res op1 op2
SET<= res op1 op2
SET>= res op1 op2
SETAND res op1 op2
SETOR res op1 op2
SETXOR res op1 op2
SETAND_NUM res op1 op2
SETOR_NUM res op1 op2
SETXOR_NUM res op1 op2
SETFUNC res func op1 op2 op3 ... opN
SUB func
```