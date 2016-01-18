SUB main()
    FOR i = 1 TO 255
        PRINT 0 - i
        IF i = 3
            BREAK
        END
        FOR j = 1 TO 255
            IF j = 2
                BREAK
            END
            PRINT j
        END
    END
    PRINT 0
    FOR i = 1 TO 2
        FOR j = 1 TO 5
            IF j % 2 = 0
                CONTINUE
            END
            PRINT i * 10 + j
        END
    END
END
