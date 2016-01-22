# Lexical analyzer. Takes source code from the standard input and transforms it
# into a stream of token in the standard output.

function char() {
    return substr(content, offset + 1, 1)
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
function read_exact(keyword,    actual, char_after, success) {
    actual = substr(content, offset + 1, length(keyword))
    chars_after = substr(content, offset + 1 + length(keyword), 2)
    success = 0

    # Require that an alphabetical keyword be followed by whitespace to avoid
    # conflicts with identifiers starting with the same characters as a keyword.
    if (toupper(actual) == keyword \
                && (!match(keyword, /^[A-Z]+$/) \
                        || match(chars_after, /( |\t|\n|\\\n)/))) {
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
    escape_newline = 0
    line = 0 # Source code line counter.
    type[0] = "" # Token type.
    value[0] = "" # Token value.
    source[0] = "" # The source code line the token came from.

    keyword_count = 0
    keyword[keyword_count++] = "AS"
    keyword[keyword_count++] = "BREAK"
    keyword[keyword_count++] = "BYREF"
    keyword[keyword_count++] = "CONTINUE"
    keyword[keyword_count++] = "DECLARE"
    keyword[keyword_count++] = "DIM"
    keyword[keyword_count++] = "ELSEIF"
    keyword[keyword_count++] = "ELSE"
    keyword[keyword_count++] = "END"
    keyword[keyword_count++] = "FOR"
    keyword[keyword_count++] = "IF"
    keyword[keyword_count++] = "LET"
    keyword[keyword_count++] = "PRINT"
    keyword[keyword_count++] = "RETURN"
    keyword[keyword_count++] = "SUB"
    keyword[keyword_count++] = "TO"
    keyword[keyword_count++] = "WHILE"
    keyword[keyword_count++] = ")"
    keyword[keyword_count++] = "("
    keyword[keyword_count++] = ","

    set_up_op_tables()
}

1 {
    if (FNR == 1) {
        # Prepend filename to file contents.
        content = (content == "" ? "0" : content "\n") \
                "FILENAME \"" FILENAME "\""
    }
    content = content "\n" $0
}

END {
    content = content "\n"
    offset = 0
    len = length(content)
    while (offset < len) {
        matched = 0

        if (read_exact("REM") || read_exact("#") || read_exact("'")) {
            # Do not put the comment start token in the output stream.
            count--
            while (char() != "\n") {
                offset++
            }
            offset++
            continue
        }

        if (read_exact("FILENAME")) {
            source[count - 1] = 0
            filename = FILENAME
            line = 0
            continue
        }

        for (i = 0; i < keyword_count; i++) {
            if (read_exact(keyword[i])) {
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
                printf "Error: expected a newline after '\\' at line %d of " \
                        "file '%s'\n", line, filename
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
