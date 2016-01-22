sub abs(n) as int32: return n end
sub f(a, b) as int32: return 0 end
sub g(c) as int32: return 0: end
sub h() as int32: return 0 end

SUB main(a, b, c)
    PRINT 1 * 2 + 3 * 4 + abs(5 + 6 * 7)
    PRINT f(a + 5, b) + g(c) + h()
END
