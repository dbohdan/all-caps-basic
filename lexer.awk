# Lexical analyzer. Takes source code from the standard input and transforms it
# into a stream of token in the standard output.

function char() {
    return substr(content, offset + 1, 1)
}

function is_whitespace(s) {
    return match(s, /[ \t\n]+/);
}

function emit_token(token_type, token_value) {
    type[count] = token_type
    value[count] = token_value
    source[count] = line
    count++
}

# Below, function arguments after the four spaces in the function declaration
# are used to create local variables. They are not expected to be used when
# calling the function.
function read_exact(keyword,    actual, success) {
    actual = substr(content, offset + 1, length(keyword))
    success = 0

    if (toupper(actual) == keyword) {
        emit_token(keyword, "")
        offset += length(keyword)
        success = 1
    }

    return success
}

function read_identifier() {
    emit_token("IDENT", _read_identifier())
}

function read_number(    float, number) {
    number = _read_number()
    if (match(number, /\./)) {
        emit_token("FLOAT", number)
    } else {
        emit_token("INTEGER", number)
    }
}

function read_string() {
    emit_token("STRING", "\"" _read_string() "\"")
}

BEGIN {
    content = ""
    count = 0 # Token counter.
    line = 0 # Source code line counter.
    type[0] = "" # Token type.
    value[0] = "" # Token value.
    source[0] = "" # The source code line the token came from.

    literal_count = 0
    literal[literal_count++] = "AS"
    literal[literal_count++] = "BREAK"
    literal[literal_count++] = "CONTINUE"
    literal[literal_count++] = "DECLARE"
    literal[literal_count++] = "DIM"
    literal[literal_count++] = "ELSEIF"
    literal[literal_count++] = "ELSE"
    literal[literal_count++] = "END"
    literal[literal_count++] = "FOR"
    literal[literal_count++] = "IF"
    literal[literal_count++] = "LET"
    literal[literal_count++] = "PRINT"
    literal[literal_count++] = "RETURN"
    literal[literal_count++] = "SUB"
    literal[literal_count++] = "TO"
    literal[literal_count++] = "WHILE"
    literal[literal_count++] = ")"
    literal[literal_count++] = "("
    literal[literal_count++] = ","

    set_up_op_tables()
}

1 {
    content = content "\n" $0
}

END {
    content = content "\n"
    offset = 0
    len = length(content)
    while (offset < len) {
        matched = 0

        if (read_exact("REM") || read_exact("#")) {
            # Do not put the comment start token in the output stream.
            count--
            while (char() != "\n") {
                offset++
            }
            offset++
            continue
        }

        for (i = 0; i < literal_count; i++) {
            if (read_exact(literal[i])) {
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        for (i = 0; i < bool_op_count; i++) {
            if (read_exact(bool_op[i])) {
                value[count - 1] = type[count - 1]
                type[count - 1] = "BOOL_OP"
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        for (i = 0; i < num_op_count; i++) {
            if (read_exact(num_op[i])) {
                value[count - 1] = type[count - 1]
                type[count - 1] = "NUM_OP"
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        for (i = 0; i < num_comp_count; i++) {
            if (read_exact(num_comp[i])) {
                value[count - 1] = type[count - 1]
                type[count - 1] = "NUM_COMP"
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        for (i = 0; i < str_op_count; i++) {
            if (read_exact(str_op[i])) {
                value[count - 1] = type[count - 1]
                type[count - 1] = "STR_OP"
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        for (i = 0; i < str_comp_count; i++) {
            if (read_exact(str_comp[i])) {
                value[count - 1] = type[count - 1]
                type[count - 1] = "STR_COMP"
                matched = 1
                break
            }
        }
        if (matched) {
            continue
        }

        if (read_exact("TRUE")) {
            value[count - 1] = "TRUE"
            type[count - 1] = "BOOLEAN"
            continue
        }
        if (read_exact("FALSE")) {
            value[count - 1] = "FALSE"
            type[count - 1] = "BOOLEAN"
            continue
        }

        c = char()
        if (match(c, /[a-zA-Z]/)) {
            read_identifier()
        } else if (match(c, /[0-9]/)) {
            read_number()
        } else if (c == "\"") {
            read_string()
        } else if (c == "\\") {
            escape_newline = 1
            offset++
        } else if ((c == "\n") || (c == ":")) {
            # Ignore repeated newlines.
            if (!escape_newline && !(type[count - 1] == "NEWLINE")) {
                emit_token("NEWLINE", "")
            }
            escape_newline = 0
            line++
            offset++
        } else {
            if (escape_newline) {
                printf "Error: expected a newline after '\\' at line %d\n", \
                        line
                exit 1
            }
            offset++
        }
    }
    for (i = 1; i < count; i++) {
        printf "%s %s %s\n", source[i], type[i], value[i]
        if (type[i] == "NEWLINE") {
            printf "\n"
        }
    }
}
