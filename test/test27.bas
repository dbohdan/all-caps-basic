sub main()
    let s = "~~~Hello, World!~~~\n\n"
    let trimmed = trim(s, "~\n")
    print trimmed
    let message = mid(s, 0, 0)
    let part = mid(s, 10, 1)
    let message = concat(message, part)
    let part = mid(s,  4, 3)
    let message = concat(message, part)
    let part = mid(s,  8, 1)
    let message = concat(message, part)
    let part = mid(s,  9, 1)
    let message = concat(message, part)
    let part = mid(s, 14, 1)
    let message = concat(message, part)
    let part = mid(s, 11, 1)
    let message = concat(message, part)
    let part = mid(s,  3, 1)
    let message = concat(message, part)
    let part = mid(s, 15, 1)
    let message = concat(message, part)
    print message
    print length(s)
end
