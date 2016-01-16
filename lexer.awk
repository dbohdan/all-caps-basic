#!/usr/bin/awk -f
function char() {
    return substr(content, offset + 1, 1)
}

function is_whitespace(s) {
    return match(s, /[ \t\n]+/);
}

function emit_token(token_type, token_value) {
    type[count] = token_type
    value[count] = token_value
    count++
}

# Below, function arguments after the four spaces in the function declaration
# are used to create local variables. They are not expected to be used when
# calling the function.
function read_literal(keyword,    actual, success) {
    actual = substr(content, offset + 1, length(keyword))
    success = 0

    if (actual == keyword) {
        emit_token(keyword, "")
        offset += length(keyword)
        success = 1
    }

    if (!success) {
        printf "Error: expected keyword '%s' but got '%s' on line %d\n", \
                keyword, actual, line
        exit 1
    }
}

function read_identifier(    ident, c) {
    ident = char()
    offset++
    do {
        ident = ident c
        c = char()
        offset++
    } while (match(c, /[a-zA-Z0-9_]/))
    offset--

    emit_token("IDENT", ident)
}

function read_number(    number, success, float, c) {
    number = char()
    offset++
    success = 1
    float = 0
    do {
        number = number c
        c = char()
        if (c == ".") {
            if (float) {
                success = 0
                break
            } else {
                float = 1
            }
            number = number "."
            offset++
            c = char()
        }
        offset++
    } while (match(c, /[0-9]/))
    offset--

    if (!success) {
        printf "Error: expected a number but got '%s' on line %d\n", \
                number, line
        exit 1
    }

    if (float) {
        emit_token("FLOAT", number)
    } else {
        emit_token("INTEGER", number)
    }
}

function read_string(    string, escape, success, c) {
    string = ""
    # Skip the opening quote.
    offset++
    success = 1
    escape = 0
    while (1) {
        c = char()
        offset++
        if (offset == len) {
            success = 0
            break
        }
        if (escape) {
            escape = 0
        } else {
            if (c == "\"") {
                break
            } else if (c == "\n") {
                c = "\\n"
            } else if (c == "\\") {
                escape = 1
            }
        }
        string = string c
    }

    if (!success) {
        printf "Error: expected a string but got '%s' on line %d\n", \
                string, line
        exit 1
    }

    emit_token("STRING", string)
}


BEGIN {
    content = ""
    count = 0
    line = 0
    # type
    # value
}

1 {
    content = content "\n" $0
}

END {
    content = content "\n"
    offset = 0
    len = length(content)
    while (offset < len) {
        c = char()

        if (c == "E") {
            read_literal("END")
        } else if (c == "F") {
            read_literal("FOR")
        } else if (c == "I") {
            read_literal("IF")
        } else if (c == "L") {
            read_literal("LET")
        } else if (c == "P") {
            read_literal("PRINT")
        } else if (c == "R") {
            read_literal("RETURN")
        } else if (c == "S") {
            read_literal("SUB")
        } else if (match(c, /[a-z]/)) {
            read_identifier()
        } else if (match(c, /[0-9]/)) {
            read_number()
        } else if (c == "\"") {
            read_string()
        } else if (match(c, /[+\-/\*%]/)) {
            emit_token("NUM_OP", c)
            offset++
        } else if (c == "&") {
            emit_token("STR_OP", c)
            offset++
        } else if (match(c, /[(),=]/)) {
            read_literal(c)
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
        printf "%s %s\n", type[i], value[i]
        if (type[i] == "NEWLINE") {
            printf "\n"
        }
    }
}
