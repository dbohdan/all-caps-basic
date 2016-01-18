SUB fib(n)
    LET a = 1
    LET b = 1
    FOR i = 1 TO n - 1
        LET b = a + b
        LET a = b - a
    END
    RETURN a
END

SUB main()
    PRINT fib(10)
END
