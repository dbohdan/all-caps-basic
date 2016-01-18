SUB main()
    LET i = 1
    PRINT i
    WHILE i < 50000
        LET i = i * 2
        IF i >= 128 AND i <= 1024
            CONTINUE
        ELSEIF i = 32
            PRINT 42
        ELSEIF i = 64
            PRINT 74
        ELSE
            PRINT i
        END
    END
END
