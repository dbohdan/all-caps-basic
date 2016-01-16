#!/usr/bin/awk -f
function char() {
    return substr(content, offset + 1, 1)
}

function is_whitespace(s) {
    return match(s, /[ \t\n]+/);
}

function add_token(token_type, token_value) {
    type[count] = token_type
    value[count] = token_value
    count++
}

function read_literal(keyword,    actual, success) {
    actual = substr(content, offset + 1, length(keyword))
    success = 0

    if (actual == keyword) {
        add_token(keyword, "")
        offset += length(keyword)
        success = 1
    }

    if (!success) {
        printf "Error: expected keyword '%s' but got '%s' on line %d\n", \
                keyword, actual, line
        exit 1
    }
}

function read_identifier(    ident, success, c) {
    ident = char()
    offset++
    success = 1
    do {
        ident = ident c
        c = char()
        offset++
    } while (match(c, /[a-zA-Z0-9_]/))
    offset--

    if (!success) {
        printf "Error: expected an identifier but got '%s' on line %d\n", \
                ident, line
        exit 1
    }

    add_token("IDENT", ident)
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
        add_token("FLOAT", number)
    } else {
        add_token("INTEGER", number)
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
            } else if (c == "\\") {
                escape = 1
            }
        }
        string = string c
    }

    if (!success) {
        printf "Error: expected a string but got '%s' on line %d\n", string, line
        exit 1
    }

    add_token("STRING", string)
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
            add_token("NUM_OP", c)
            offset++
        } else if (c == "&") {
            add_token("STR_OP", c)
            offset++
        } else if (match(c, /[(),=]/)) {
            read_literal(c)
        } else if (c == "\\") {
            escape_newline = 1
            offset++
        } else if ((c == "\n") || (c == ":")) {
            # Ignore repeated newlines.
            if (!escape_newline && !(type[count - 1] == "NEWLINE")) {
                add_token("NEWLINE", "")
            }
            escape_newline = 0
            line++
            offset++
        } else {
            if (escape_newline) {
                printf "Error: expected a newline after '\\' at line %d\n", line
                exit 1
            }
            offset++
        }
    }
    for (i = 0; i < count; i++) {
        printf "%05d %s %s\n", i, type[i], value[i]
    }
}
