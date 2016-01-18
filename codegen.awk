#!/usr/bin/awk -f
# Code generator. Translates the intermediate representation into C code.

function char() {
    return substr($0, offset, 1)
}

# Add a line of C code to the current subroutine.
function emit(s) {
    sub_line[sub_line_count] = s
    sub_line_count++
}

# Emit all the C code for the current subroutine to the standard output.
function emit_sub(    i) {
    for (i = 0; i < sub_line_count; i++) {
        printf "%s\n", sub_line[i]
    }
}

# Reset the required variables at the start of a new subroutine.
function start_sub(    key) {
    arg_count = 0
    sub_line_count = 0
    for (key in data_type) {
        delete data_type[key]
    }
}

# Map operator op to its C equivalent.
function op2c(op) {
    if (match(op, /([\+\/*%\-<>])/)) {
        return op
    } else if (op == "=") {
        return "=="
    } else if (op == "=") {
        return "=="
    } else if (op == "<>") {
        return "!="
    } else if (op == "<=") {
        return "<="
    } else if (op == ">=") {
        return ">="
    } else if (op == "OR") {
        return "||"
    } else if (op == "AND") {
        return "&&"
    } else if (op == "XOR") {
        return "^"
    }
}

BEGIN {
    data_type["foo"] = "bar"
    line = 0 # Original source code file line.
    arg_count = 0
    arg[0] = ""
    sub_name = ""
    printf "#include <stdint.h>\n#include <stdio.h>\n#define not(x) (!x)\n"
    sub_line_count = 0
    sub_line[0] = ""
}

/^-- Line/ {
    line = $3
}

/^ARG/ {
    offset = 5
    ident = _read_identifier()
    data_type[ident] = "int32_t"
    arg[arg_count] = ident
    arg_count++
}


/^ENDSUB/ {
    emit("}\n")
    printf "int %s(", sub_name
    for (i = 0; i < arg_count; i++) {
        printf "%s", arg[i]
        if (i != arg_count - 1) {
            printf ", "
        }
    }
    printf ")\n{\n"
    for (key in data_type) {
        is_argument = 0
        for (i = 0; i < arg_count; i++) {
            if (arg[i] == key) {
                is_argument = 1
                break
            }
        }
        if (!is_argument) {
            printf "%s %s;\n", data_type[key], key
        }
    }
    emit_sub()
}

/^INCR/ {
    emit($2 "++;")
}

/^JN?Z/ {
    not = substr($0, 2, 1) == "N" ? "" : "!"
    emit("if (" not $3 ") { goto " $2 "; }")
}

/^JMP/ {
    emit("goto " $2 ";")
}

/^LABEL/ {
    emit($2 ": ;")
}

/^PRINT/ {
    emit("printf(\"%d\\n\", " $2 ");")
}

/^RETURN/ {
    emit("return " $2 ";")
}

/^SET/ {
    op_type = substr($1, 4, 100)
    target_var = $2
    data_type[target_var] = "int32_t"
    offset = length($1) + length($2) + 3
    if (op_type == "FUNC") {
        s = target_var " = " $3 "("
        for (i = 4; i <= NF; i++) {
            s = s $i
            if (i < NF) {
                s = s ", "
            }
        }
        s = s ");"
        emit(s)
    } else {
        emit(target_var " = " $3 " " op2c(op_type) " " $4 ";")
    }
}

/^SUB/ {
    sub_name = $2
    start_sub()
}
