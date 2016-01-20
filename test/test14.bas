sub repeat(s as string, n) as string
    let result = ""
    for i = 1 to n
        let result = result & s
    end
    return result
end

sub main()
    let s = "Ha"
    print repeat(s, 3)
end
