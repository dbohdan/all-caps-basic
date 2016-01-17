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
        printf "Error: expected a number but got '%s' on line %d\n", \
                number, line
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
        printf "Error: expected a string but got '%s' on line %d\n", \
                string, line
        exit 1
    }

    return string
}
