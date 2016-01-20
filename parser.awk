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

function expect_token(t, v,   current_value) {
    if (type[current] == t) {
        if (v != "" && value[current] != v) {
            printf "Error: expected token '%s' but got '%s' on line %d\n",
                    v, value[current], source[current]
            exit 1
        }
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
    return (t == "STRING" || t == "INTEGER" || t == "FLOAT" || t == "BOOLEAN")
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
    while (current < count) {
        if (type[current] == "DECLARE") {
            expect_token("DECLARE")
            emit("DECLARE")
            parse_sub_declaration()
            emit("ENDSUB")
        } else if (type[current] == "SUB") {
            parse_sub()
        } else {   
            printf "Error: expected a subroutine at line %d but got %s\n",
                    source[current], type[current]
            exit 1
        }
    }
}

function parse_sub_declaration(    ident, data_type, list_end) {
    expect_token("SUB")
    ident = expect_token("IDENT")
    expect_token("(")
    emit("SUB " ident)

    list_end = curr_token_type() == ")"
    while (!list_end) {
        ident = expect_token("IDENT")
        data_type = ""
        if (curr_token_type() == "AS") {
            expect_token("AS")
            data_type = expect_token("IDENT")
        }
        if (curr_token_type() == ")") {
            list_end = 1
        } else {
            expect_token(",")
        }
        emit("ARG " ident " " data_type)
    }
    expect_token(")")
    if (curr_token_type() == "AS") {
        expect_token("AS")
        data_type = expect_token("IDENT")
        emit("RETTYPE " data_type)
    }
}

function parse_sub() {
    parse_sub_declaration()
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    emit("ENDSUB")
}

function parse_assignment(    ident, temp) {
    expect_token("LET")
    ident = expect_token("IDENT")
    expect_token("NUM_COMP", "=")
    temp = parse_expression()
    skip_newline()
    emit("SET " ident " " temp)
}

function parse_return(    temp) {
    expect_token("RETURN")
    temp = parse_expression()
    skip_newline()
    emit("RETURN " temp)
}

function parse_for_loop(    ident, start, end, temp, current_loop_start) {
    expect_token("FOR")
    ident = expect_token("IDENT")
    expect_token("NUM_COMP", "=")
    start = parse_expression()
    expect_token("TO")
    end = parse_expression()
    skip_newline()

    current_loop_start = make_label()
    temp = make_temp_var()

    # Globals.
    current_loop_end[loop_count] = make_label()
    current_loop_after[loop_count] = make_label()
    loop_count++

    emit("SET " ident " " start)
    emit("SET> " temp " " ident " " end)
    emit("JT " current_loop_after[loop_count - 1] " " temp)
    emit("LABEL " current_loop_start)
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    skip_newline()
    emit("LABEL " current_loop_end[loop_count - 1])
    emit("SET< " temp " " ident " " end)
    emit("INCR " ident)
    emit("JT " current_loop_start " " temp)
    emit("LABEL " current_loop_after[loop_count - 1])
    loop_count--
}

function parse_while_loop(    condition, current_loop_start) {
    current_loop_start = make_label()
    temp = make_temp_var()

    # Globals.
    current_loop_end[loop_count] = make_label()
    current_loop_after[loop_count] = make_label()
    loop_count++

    expect_token("WHILE")
    emit("LABEL " current_loop_start)

    condition = parse_expression()
    skip_newline()
    emit("JF " current_loop_after[loop_count - 1] " " condition)
    while (curr_token_type() != "END") {
        parse_statement()
    }
    expect_token("END")
    emit("LABEL " current_loop_end[loop_count - 1])
    emit("JMP " current_loop_start " " temp)
    emit("LABEL " current_loop_after[loop_count - 1])
    loop_count--
}

function parse_conditional(    condition, after_label, next_label) {
    expect_token("IF")
    after_label = make_label()
    next_label = make_label()
    condition = parse_expression()
    skip_newline()
    emit("JF " next_label " " condition)
    while (curr_token_type() != "END") {
        while (!(curr_token_type() == "ELSEIF" \
                || curr_token_type() == "ELSE" \
                || curr_token_type() == "END")) {
            parse_statement()
        }
        emit("JMP " after_label)
        emit("LABEL " next_label)
        next_label = make_label()
        if (curr_token_type() == "ELSEIF") {
            expect_token("ELSEIF")
            condition = parse_expression()
            skip_newline()
            emit("JF " next_label " " condition)
        } else if (curr_token_type() == "ELSE") {
            expect_token("ELSE")
        }
    }
    emit("LABEL " next_label)
    emit("LABEL " after_label)
    expect_token("END")
}

function parse_declaration(    ident, data_type) {
    expect_token("DIM")
    ident = expect_token("IDENT")
    expect_token("AS")
    data_type = expect_token("IDENT")
    skip_newline()
    emit("DIM " ident " " data_type)
}

function parse_statement(    ctt) {
    ctt = curr_token_type()
    if (ctt == "BREAK") {
        emit("JMP " current_loop_after[loop_count - 1])
        current++
        skip_newline()
    } else if (ctt == "CONTINUE") {
        emit("JMP " current_loop_end[loop_count - 1])
        current++
        skip_newline()
    } else if (ctt == "DIM") {
        parse_declaration()
    } else if (ctt == "FOR") {
        parse_for_loop()
    } else if (ctt == "IF") {
        parse_conditional()
    } else if (ctt == "LET") {
        parse_assignment()
    } else if (ctt == "PRINT") {
        parse_print()
    } else if (ctt == "RETURN") {
        parse_return()
    } else if (ctt == "WHILE") {
        parse_while_loop()
    } else if (ctt == "IDENT") {
        parse_function_call()
    } else {
        printf "Error: expected a statement but got '%s' on line %d\n",
                ctt, source[current]
        exit 1
    }
}

function parse_print(   temp, s) {
    expect_token("PRINT")
    s = ""
    while (1) {
        #printf "..** %s %s %s.\n", curr_token_type(), temp, value[current]
        temp = parse_expression()
        #printf "..** %s %s %s.\n", curr_token_type(), temp, value[current]
        s = s " " temp
        if (curr_token_type() == "NEWLINE") {
            break
        }
        expect_token(",")
    }
    skip_newline()
    emit("PRINT" s)
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
    argc = -1 # The argument count of the current function.

    while (!end) {
        ctt = type[current]
        ctv = value[current]
        current++
        if (ctt == "IDENT" || is_literal_type(ctt)) {
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
            if (argc == -1) {
                # If we are not in a function.
                current--
                break
            }
            argc++
            for (; (op_stack[size - 1] != "(") && (size > 0); size--) {
                emit_operator(op_stack[size - 1])
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
            if (match(op_stack[size - 1], /[a-zA-Z][a-zA-Z0-9_]*/) \
                        && !is_operator(op_stack[size - 1])) {
                temp = make_temp_var()
                printf "SETFUNC %s %s ", temp, op_stack[size - 1]
                for (i = queue_size - argc; i < queue_size; i++) {
                    printf "%s ", arg_queue[i]
                }
                printf "\n"
                queue_size -= argc
                arg_queue[queue_size] = temp
                argc = -1
                queue_size++

                size--
            }
        } else if (ctt == "BOOL_OP" || ctt == "NUM_OP" || ctt == "NUM_COMP" \
                    || ctt == "STR_OP" || ctt == "STR_COMP") {
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
    return arg_queue[queue_size - 1]
}


BEGIN {
    type[0] = ""
    value[0] = ""
    source[0] = ""
    count = 0
    temp_var_count = 0
    label_count = 0
    loop_count = 0
    current_loop_end[0] = ""
    current_loop_after[0] = ""

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

    set_up_op_tables()
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
