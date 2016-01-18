#!/usr/bin/awk -f
# Parser. Takes a steam of tokens and transforms it into the intermediate
# representation format.

function emit(s) {
    printf "%s\n", s
}

function skip_newline() {
    if (type[current] == "NEWLINE") {
        emit("-- Line " source[current])
        current++
    }
}

function expect_token(t,    current_value) {
    if (type[current] == t) {
        current_value = value[current]
        current++
    } else {
        printf "Error: expected token '%s' but got '%s' on line %d\n",
                t, type[current], source[current]
        exit 1
    }
    skip_newline()
    return current_value
}

function curr_token_type() {
    return type[current]
}

function is_literal_type(t) {
    return (t == "STRING" || t == "INTEGER" || t == "FLOAT")
}

function make_temp_var() {
    temp_var_count++
    return "temp" temp_var_count
}

function make_label() {
    label_count++
    return "label" label_count
}

function parse_module() {
    while (type[current] == "SUB") {
        parse_sub()
    }
}

function parse_sub(    ident, list_end) {
    expect_token("SUB")
    ident = expect_token("IDENT")
    expect_token("(")
    emit("SUB " ident)

    list_end = curr_token_type() == ")"
    while (!list_end) {
        ident = expect_token("IDENT")
        if (curr_token_type() == ")") {
            list_end = 1
        } else {
            expect_token(",")
        }
        emit("ARG " ident)
    }
    expect_token(")")
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    emit("ENDSUB")
}

function parse_assignment(    ident, temp) {
    expect_token("LET")
    ident = expect_token("IDENT")
    expect_token("=")
    temp = parse_expression()
    emit("SET " ident " " temp)
}

function parse_return(    temp) {
    expect_token("RETURN")
    temp = parse_expression()
    emit("RETURN " temp)
}

function parse_for_loop(    ident, start, end, temp,
        label_loop_start, label_loop_end) {
    expect_token("FOR")
    ident = expect_token("IDENT")
    expect_token("=")
    start = parse_expression()
    expect_token("TO")
    end = parse_expression()

    label_loop_start = make_label()
    label_loop_end = make_label()
    temp = make_temp_var()

    emit("SET " ident " " start)
    emit("SET> " temp " " ident " " end)
    emit("JNZ " label_loop_end " " temp)
    emit("LABEL " label_loop_start)
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    emit("SET< " temp " " ident " " end)
    emit("INCR " ident)
    emit("JNZ " label_loop_start " " temp)
    emit("LABEL " label_loop_end)
}

function parse_conditional(    temp, label) {
    expect_token("IF")
    label = make_label()
    temp = parse_expression()
    emit("JZ " label " " temp)
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    emit("LABEL " label)
}

function parse_statement(    ctt) {
    ctt = curr_token_type()
    if (ctt == "FOR") {
        parse_for_loop()
    } else if (ctt == "IF") {
        parse_conditional()
    } else if (ctt == "LET") {
        parse_assignment()
    } else if (ctt == "PRINT") {
        parse_print()
    } else if (ctt == "RETURN") {
        parse_return()
    } else if (ctt == "IDENT") {
        parse_function_call()
    } else {
        printf "Error: expected a statement but got '%s'\n", ctt
        exit 1
    }
}

function parse_print(   temp) {
    expect_token("PRINT")
    temp = parse_expression()
    emit("PRINT " temp)
}

# Used in parse_expression.
function emit_operator(op,    temp) {
    temp = make_temp_var()
    emit("SET" op " " temp " " \
            arg_queue[queue_size - 2] " " arg_queue[queue_size - 1])
    queue_size -= 2
    arg_queue[queue_size] = temp
    queue_size++
    return temp
}

# A version of the shunting-yard algorithm.
# https://en.wikipedia.org/wiki/Shunting-yard_algorithm
function parse_expression(    ctt, ctv, argc, op_stack, size, temp, end) {
    # Globals
    arg_queue[0] = ""
    queue_size = 0
    # Locals
    op_stack[0] = ""
    size = 0 # Stack size.
    end = 0
    argc = 0 # The argument count of the current function.

    while (!end) {
        ctt = type[current]
        ctv = value[current]
        current++
        if (ctt == "IDENT" || ctt == "NOT" || is_literal_type(ctt)) {
            if (ctt == "IDENT" && type[current] == "(") {
                op_stack[size] = ctv
                argc = type[current + 1] == ")" ? 0 : 1
                size++
            } else {
                arg_queue[queue_size] = ctv
                queue_size++
            }
        } else if (ctt == "(") {
            op_stack[size] = "("
            size++
        } else if (ctt == ",") {
            for (; (op_stack[size - 1] != "(") && (size > 0); size--) {
                emit_operator(op_stack[size - 1])
                argc++
            }
            if (op_stack[size - 1] == "(") {
            } else {
                printf "Error: mismatched parenthesis on line %d\n",
                        source[current]
                exit 1
            }
        } else if (ctt == ")") {
            for (; (op_stack[size - 1] != "(") && (size > 0); size--) {
                emit_operator(op_stack[size - 1])
            }
            if (op_stack[size - 1] == "(") {
                size--
            } else {
                printf "Error: mismatched parenthesis on line %d\n",
                        source[current]
                exit 1
            }
            if (match(op_stack[size - 1], /[a-z][a-zA-Z0-9_]*/)) {
                temp = make_temp_var()
                printf "SETFUNC %s %s ", temp, op_stack[size - 1]
                for (i = queue_size - argc; i < queue_size; i++) {
                    printf "%s ", arg_queue[i]
                }
                printf "\n"
                queue_size -= argc
                arg_queue[queue_size] = temp
                queue_size++

                size--
            }
        } else if (ctt == "NUM_OP" || ctt == "STR_OP") {
            if ((size > 0) &&
                    (precedence[op_stack[size - 1]] >= precedence[ctv])) {
                size--
                emit_operator(op_stack[size])
            }
            op_stack[size] = ctv
            size++
        } else {
            current--
            end = 1
        }
    }
    size--
    for (; size >= 0; size--) {
        if (op_stack[size] == "(") {
            printf "Error: mismatched parenthesis on line %d\n",
                    source[current]
            exit 1
        }
        emit_operator(op_stack[size])
    }
    skip_newline()
    return arg_queue[queue_size - 1]
}


BEGIN {
    type[0] = ""
    value[0] = ""
    source[0] = ""
    count = 0
    temp_var_count = 0
    label_count = 0

    # Operator precedence.
    precedence["OR"] = 1
    precedence["AND"] = 2
    precedence["="] = 3
    precedence["<>"] = 3
    precedence["<"] = 4
    precedence[">"] = 4
    precedence["<="] = 4
    precedence[">="] = 4
    precedence["+"] = 5
    precedence["-"] = 5
    precedence["*"] = 6
    precedence["/"] = 6
    precedence["%"] = 6
    precedence["NOT"] = 7

    precedence["&"] = 1 # String concatenation.
}

1 {
    if ($0 != "") {
        source[count] = $1
        type[count] = $2
        value[count] = substr($0, length($1) + 1 + length($2) + 2)
        count++
    }
}

END {
    current = 0
    parse_module()
}
