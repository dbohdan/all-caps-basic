sub main()
    let i = 1
    print i
    while i < 50000
        let i = i * 2
        if i >= 128 and i <= 1024
            continue
        elseif i = 32
            print 42
        elseif i = 64
            print 74
        else
            print i
        end
    end
end
