sub abs(n) as int32
    if n > 0
        return n
    else
        return 0 - n
    end
end

sub main()
    dim a as string
    let a = abs(5)
end
