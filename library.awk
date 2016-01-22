function set_up_op_tables() {
    # bool -> bool or int -> int
    bool_op_count = 0
    bool_op[bool_op_count++] = "AND"
    bool_op[bool_op_count++] = "OR"
    bool_op[bool_op_count++] = "XOR"

    # num -> num
    num_op_count = 0
    num_op[num_op_count++] = "+"
    num_op[num_op_count++] = "-"
    num_op[num_op_count++] = "*"
    num_op[num_op_count++] = "/"
    num_op[num_op_count++] = "%"

    # num -> bool
    num_comp_count = 0
    num_comp[num_comp_count++] = "="
    num_comp[num_comp_count++] = "<>"
    num_comp[num_comp_count++] = "<="
    num_comp[num_comp_count++] = ">="
    num_comp[num_comp_count++] = "<"
    num_comp[num_comp_count++] = ">"

    # str -> str
    str_op_count = 0
    str_op[str_op_count++] = "&"

    # str -> bool
    str_comp_count = 0
    str_comp[str_comp_count++] = "EQ"
    str_comp[str_comp_count++] = "NE"
}

function is_bool_op(op,    i) {
    for (i = 0; i < bool_op_count; i++) {
        if (bool_op[i] == op) {
            return 1
        }
    }
    return 0
}

function is_num_comp(op,    i) {
    for (i = 0; i < num_comp_count; i++) {
        if (num_comp[i] == op) {
            return 1
        }
    }
    return 0
}

function is_num_op(op,    i) {
    for (i = 0; i < num_op_count; i++) {
        if (num_op[i] == op) {
            return 1
        }
    }
    return 0
}

function is_str_comp(op,    i) {
    for (i = 0; i < str_comp_count; i++) {
        if (str_comp[i] == op) {
            return 1
        }
    }
    return 0
}

function is_str_op(op,    i) {
    for (i = 0; i < str_op_count; i++) {
        if (str_op[i] == op) {
            return 1
        }
    }
    return 0
}

function is_operator(op) {
    return is_bool_op(op) || is_num_comp(op) || is_num_op(op) || \
            is_str_comp(op) || is_str_op(op)
}

function token_type(token,    c) {
    c = substr(token, 1, 1)
    if (c == "\"") {
        return "STRING"
    } else if (match(c, /[0-9]/)) {
        if (match(token, /\./)) {
            return "FLOAT"
        } else {
            return "INTEGER"
        }
    } else if (token == "TRUE" || token == "FALSE") {
        return "BOOLEAN"
    } else {
        return "IDENT"
    }
}

# Globals used: offset, char().
function _read_identifier(    ident, c) {
    ident = char()
    offset++
    do {
        ident = ident c
        c = char()
        offset++
    } while (match(c, /[a-zA-Z0-9_]/))
    offset--

    return ident
}

# Globals used: offset, char(), line.
function _read_number(    number, success, float, c) {
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
        printf "Error: expected a number but got '%s' on line %d of " \
                "file '%s'\n",
                number, line, filename
        exit 1
    }

    return number
}

# Globals used: offset, char(), line.
function _read_string(    string, escape, success, c) {
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
        printf "Error: expected a string but got '%s' on line %d of " \
                "file '%s'\n", \
                string, line, filename
        exit 1
    }

    return string
}

function debug_print(v1, v2, v3, v4, v5) {
    print "|" v1 "|" v2 "|" v3 "|" v4 "|" v5 "|"
}
