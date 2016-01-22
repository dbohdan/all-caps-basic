#!/usr/bin/awk -f
# Code generator. Check that the program is correctly typed and translates the
# intermediate representation into C code.

function char() {
    return substr($0, offset, 1)
}

function read_literal_or_ident(    c, tt) {
    c = char()
    tt = token_type(c)
    if (tt == "STRING") {
        return "\"" _read_string() "\""
    } else if (tt == "FLOAT" || tt == "INTEGER") {
        return _read_number()
    } else {
        return _read_identifier()
    }
}

function literal_data_type(lit,    tt) {
    tt = token_type(lit)
    if (tt == "STRING") {
        return "string"
    } else if (tt == "FLOAT") {
        return "double"
    } else if (tt == "INTEGER") {
        return "int64"
    } else if (tt == "BOOLEAN") {
        return "bool"
    }
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
    return_data_type[sub_name] = default_data_type
    arg_count = 0
    sub_line_count = 0
    for (key in data_type) {
        delete data_type[key]
        delete is_pointer[key]
    }
}

function end_sub() {
    emit("}\n")
    printf type2c(return_data_type[sub_name]) " %s(", sub_name
    for (i = 0; i < arg_count; i++) {
        printf "%s%s %s", type2c(data_type[arg[i]]),
                arg_data_type[sub_name, i, "byref"] ? "*" : "", arg[i]
        if (i != arg_count - 1) {
            printf ", "
        }
    }
    printf ")\n{\n"
    # Print all variable types, except for the function's arguments.
    for (key in data_type) {
        is_argument = 0
        for (i = 0; i < arg_count; i++) {
            if (arg[i] == key) {
                is_argument = 1
                break
            }
        }
        if (!is_argument) {
            printf "%s %s = %s;\n", type2c(data_type[key]), key,
                    default_value[data_type[key]]
        }
    }
}

function type2c(type_name) {
    if (type_name in type2c_table) {
        return type2c_table[type_name]
    } else {
        printf "Error: unknown type '%s' on line %d of file '%s'\n",
                type_name, line, filename
        exit 1
    }
}

function type2format(type_name) {
    if (type_name in printf_format) {
        return printf_format[type_name]
    } else {
        printf "Error: type '%s' on line %d of file '%s' has no print format\n",
                type_name, line, filename
        exit 1
    }
}

function add_var(name, type_name) {
    if (name in data_type) {
        printf "Error: variable %s redeclared on line %d of file %s\n",
                name, line, filename
        exit 1
    } else {
        data_type[name] = type_name
    }
}

function wrap_pointer(ident) {
    return (is_pointer[ident] ? "*" : "") ident
}

# Map the IR instruction SET<operator> to its C equivalent.
function set2c(target, op, arg1, arg2,    temp) {
    target = wrap_pointer(target)
    arg1 = wrap_pointer(arg1)
    arg2 = wrap_pointer(arg2)

    if (op in op2c_table) {
        return target " = " arg1 " " op2c_table[op] " " arg2 ";"
    } else if (op == "&") {
        temp = target " = sdsempty();\n"
        temp = temp target " = sdscat(" target ", " arg1 ");\n"
        temp = temp target " = sdscat(" target ", " arg2 ");"
        return temp
    } else if (op == "EQ" || op == "NE")  {
        return target " = sdscmp(" arg1 ", " arg2 ") " \
                (op == "EQ" ? "==" : "!=")  " 0;"
    } else if (op == "") {
        if (find_data_type(arg1) == "string") {
            return target " = sdsnew(" arg1 ");"
        } else {
            return target " = " arg1 ";"
        }
    }
}

function is_integral_type(t) {
    return match(t, /^u?int/)
}

function is_numerical_type(t) {
    return is_integral_type(t) || t == "float" || t == "double"
}

function match_type(t1, t2) {
    if (t1 == t2) {
        return t1
    } else if ((match(t1, /^int/) && match(t2, /^int/)) \
            || (match(t1, /^uint/) && match(t2, /^uint/))) {
        # FIXME
        return t1
    } else {
        return 0
    }
}

BEGIN {
    return_data_type["not"] = "bool"
    arg_data_type["not", 0, "type"] = "bool"
    arg_data_type["not", 0, "byref"] = 0
    # Variable data type array.
    data_type["foo"] = "bar"
    is_pointer["foo"] = 0
    # Original source code file line.
    line = 0
    filename = ""
    declare_only = 0

    # The number of arguments the current subroutine has.
    arg_count = 0
    # Argument names.
    arg[0] = ""

    # Current subroutine name.
    sub_name = ""
    sub_line_count = 0
    # Lines in the current subroutine.
    sub_line[0] = ""

    default_data_type = "int32"

    printf_format["int8"] = "%d"
    printf_format["int16"] = "%d"
    printf_format["int32"] = "%d"
    printf_format["int64"] = "%d"
    printf_format["uint8"] = "%u"
    printf_format["uint16"] = "%u"
    printf_format["uint32"] = "%u"
    printf_format["uint64"] = "%u"
    printf_format["float"] = "%f"
    printf_format["double"] = "%f"
    printf_format["bool"] = "%u"
    printf_format["string"] = "%s"
    printf_format["cstring"] = "%s"

    op2c_table["+"] = "+"
    op2c_table["-"] = "-"
    op2c_table["/"] = "/"
    op2c_table["*"] = "*"
    op2c_table["%"] = "%"
    op2c_table["="] = "=="
    op2c_table["<"] = "<"
    op2c_table[">"] = ">"
    op2c_table["<>"] = "!="
    op2c_table["<="] = "<="
    op2c_table[">="] = ">="
    op2c_table["OR"] = "||"
    op2c_table["AND"] = "&&"
    op2c_table["XOR"] = "^"
    op2c_table["OR_NUM"] = "|"
    op2c_table["AND_NUM"] = "&"
    op2c_table["XOR_NUM"] = "^"

    type2c_table["int8"] = "int8_t"
    type2c_table["int16"] = "int16_t"
    type2c_table["int32"] = "int32_t"
    type2c_table["int64"] = "int64_t"
    type2c_table["uint8"] = "uint8_t"
    type2c_table["uint16"] = "uint16_t"
    type2c_table["uint32"] = "uint32_t"
    type2c_table["uint64"] = "uint64_t"
    type2c_table["float"] = "float"
    type2c_table["double"] = "double"
    type2c_table["bool"] = "bool"
    type2c_table["string"] = "sds"
    type2c_table["cstring"] = "char*"

    default_value["int8"] = "0"
    default_value["int16"] = "0"
    default_value["int32"] = "0"
    default_value["int64"] = "0"
    default_value["uint8"] = "0"
    default_value["uint16"] = "0"
    default_value["uint32"] = "0"
    default_value["uint64"] = "0"
    default_value["float"] = "0.0"
    default_value["double"] = "0.0"
    default_value["bool"] = "false"
    default_value["string"] = "sdsempty()"
    default_value["cstring"] = "sdsempty()"

    set_up_op_tables()

    printf "#include <stdbool.h>\n#include <stdio.h>\n#include <stdint.h>\n" \
            "\n#include \"gc.h\"\n#include \"sds.h\"\n#include \"cprelude.h\"\n"
}

/^-- Filename/ {
    offset = 13
    filename = _read_string()
}

/^-- Line/ {
    line = $3
}

/^ARG/ {
    ident = $2
    data_type[ident] = $3 == "" ? default_data_type : $3
    is_pointer[ident] = $4 == "BYREF"
    arg_data_type[sub_name, arg_count, "type"] = data_type[ident]
    arg_data_type[sub_name, arg_count, "byref"] = is_pointer[ident]
    arg[arg_count] = ident
    arg_count++
}

/^DECLARE/ {
    declare_only = 1
}

/^DIM/ {
    add_var($2, $3)
}

/^ENDSUB/ {
    if (!declare_only) {
        end_sub()
        emit_sub()
    }
    declare_only = 0
}

/^INCR/ {
    if ($3 == "" || $3 == "1") {
        emit($2 "++;")
    } else {
        emit($2 "+=" $3 ";");
    }
}

/^J(T|F)/ {
    not = substr($0, 2, 1) == "T" ? "" : "!"
    if (find_data_type($3) != "bool") {
        printf "Error: nonboolean expression used for conditional on line" \
                " %d of file '%s'\n", line, filename
        exit 1
    }
    emit("if (" not $3 ") { goto " $2 "; }")
}

/^JMP/ {
    emit("goto " $2 ";")
}

/^LABEL/ {
    emit($2 ": ;")
}

/^PRINT/ {
    print_arg_count = 0
    offset = 7
    while (offset <= length($0)) {
        t = read_literal_or_ident()
        offset++
        print_arg[print_arg_count++] = t
    }

    s = "printf(\""
    for (i = 0; i < print_arg_count; i++) {
        if (token_type(print_arg[i]) == "IDENT") {
            format = type2format(data_type[print_arg[i]])
        } else {
            format = type2format(literal_data_type(print_arg[i]))
        }
        s = s format
        if (i < print_arg_count - 1) {
            s = s " "
        }
    }
    s = s "\\n\", "
    for (i = 0; i < print_arg_count; i++) {
        s = s print_arg[i]
        if (i < print_arg_count - 1) {
            s = s ", "
        }
    }
    s = s ");"
    emit(s)
}

/^RETTYPE/ {
    return_data_type[sub_name] = $2
}

function find_data_type(ident_or_literal) {
    return token_type(ident_or_literal) == "IDENT" ? \
            data_type[ident_or_literal] : literal_data_type(ident_or_literal)
}

/^RETURN/ {
    if (!match_type(return_data_type[sub_name], find_data_type($2))) {
        printf "Error: attempt to return type '%s' when '%s' was expected " \
                "from function '%s' on line %d of file '%s'\n",
                find_data_type($2), return_data_type[sub_name], sub_name,
                line, filename
        exit 1
    }
    emit("return " wrap_pointer($2) ";")
}

/^SET/ {
    op = substr($1, 4, 100)
    offset = length($1) + 2
    target_var = read_literal_or_ident()
    offset++
    if (op == "FUNC") {
        func_name = read_literal_or_ident()
        offset++

        expression_type = return_data_type[func_name]
        if (expression_type == "") {
            printf "Error: undeclared function '%s' used on line %d of " \
                    "file '%s'\n",
                    func_name, line, filename
            exit 1
        }

        s = target_var " = " func_name "("
        i = 0
        while (offset <= length($0)) {
            func_arg = read_literal_or_ident()
            func_arg_type = find_data_type(func_arg)
            if (!match_type(arg_data_type[func_name, i, "type"],
                    func_arg_type)) {
                printf "Error: expected argument number %d to function '%s' " \
                        "to be type '%s' but got type '%s' on line %d of " \
                        "file '%s'\n",
                        i + 1, func_name, arg_data_type[func_name, i, "type"],
                        func_arg_type, line, filename
                exit 1
            }
            offset++
            if (i > 0) {
                s = s ", "
            }
            s = s (arg_data_type[func_name, i, "byref"] ? "&" : "") \
                    wrap_pointer(func_arg)
            i++
        }
        s = s ");"
        emit(s)
    } else {
        arg1 = read_literal_or_ident()
        offset++
        arg2 = read_literal_or_ident()

        if (arg1 != "") {
            arg1_type = find_data_type(arg1)
        }
        if (arg2 != "") {
            arg2_type = find_data_type(arg2)
        }

        matched_type = match_type(arg1_type, arg2_type)

        if (op == "") {
            # Simple assignment.
            expression_type = arg1_type
        } else if (is_bool_op(op)) {
            if (arg1_type == "bool" && arg2_type == "bool") {
                expression_type = "bool"
            } else if (is_integral_type(arg1_type) \
                    && is_integral_type(arg2_type)) {
                expression_type = matched_type
                op = op "_NUM"
            } else {
                printf "Error: expected boolean or numerical arguments to " \
                        "operator '%s' on line %d of file '%s'\n",
                        op, line, filename
                exit 1
            }
        } else if (is_num_op(op) || is_num_comp(op)) {
            if (!is_numerical_type(arg1_type) \
                    || !is_numerical_type(arg2_type)) {
                printf "Error: expected numerical arguments to operator '%s' " \
                        "on line %d of file '%s'\n", op, line, filename
                exit 1
            }
            if (matched_type) {
                expression_type = is_num_comp(op) ? "bool" : matched_type
            } else {
                printf "Internal error: can't determine expression type" \
                        " (op:'%s', arg1:'%s', arg2:'%s') on line %d " \
                        "of file '%s'\n",
                        op, arg1, arg2, line, filename
                exit 99
            }
        } else if (is_str_op(op) || is_str_comp(op)) {
            if (arg1_type != "string" || arg2_type != "string") {
                printf "Error: expected string arguments to operator '%s' " \
                        "on line %d of file '%s'\n", op, line, filename
                exit 1
            }
            expression_type = is_str_comp(op) ? "bool" : "string"
        } else {
            printf "Internal error: can't determine expression type" \
                    " (op:'%s', arg1:'%s', arg2:'%s') on line %d " \
                    "of file '%s'\n",
                    op, arg1, arg2, line, filename
            exit 99
        }
        if (1) {
            printf "//| %s = %s %s %s | %s %s %s -> %s | %s %s\n",
                    target_var, arg1, op, arg2,
                    arg1_type, op, arg2_type, expression_type,
                    is_numerical_type(arg1_type), is_numerical_type(arg1_type)
        }
        emit(set2c(target_var, op, arg1, arg2))
    }

    # Type checking.
    if (target_var in data_type) {
        if (data_type[target_var] != expression_type && 
                # Allow assigning any integer type to any other integer type.
                !(match_type(data_type[target_var], expression_type))) {
            printf "Error: use of type '%s' as '%s' on line %d of file '%s'\n",
                    expression_type, data_type[target_var], line, filename
            exit 1
        }
    } else {
        add_var(target_var, expression_type)
    }
}

/^SUB/ {
    sub_name = $2
    start_sub()
}
