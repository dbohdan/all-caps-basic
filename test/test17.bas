sub f1(a) as int32
    return a
end

sub f2(a, b) as int32
    return b
end

sub f3(a, b, c) as int32
    return c
end

sub f4(a, b, c, d) as int32
    return d
end

sub f5(a, b, c, d, e) as int32
    return e
end

sub main()
    print f1(1)
    print f2(1, 2)
    print f3(1, 2, 3)
    print f4(1, 2, 3, 4)
    print f5(1, 2, 3, 4, 5)
end
