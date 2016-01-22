sub bval(x as int32, y as int32) as int32
    let x = 5
    let y = 7
end

sub bref1(byref x as int32, y as int32) as int32
    let x = 5
    let y = 7
end

sub bref2(x as int32, byref y as int32) as int32
    let x = 5
    let y = 7
    let devnull = bval(x, y)
    let devnull = bref1(x, y)
    return y
end

sub bref3(byref x as int32, byref y as int32) as int32
    let devnull = bref1(x, y)
    let devnull = bref2(x, y)
end

sub main()
    dim a as int32
    dim b as int32
    let a = 1
    let b = 2
    print a, b
    let bitbucket = bval(a, b)
    print a, b
    let bitbucket = bref1(a, b)
    print a, b
    let bitbucket = bref2(a, b)
    print a, b
    if bitbucket <> 7
        print "wrong"
    end
    let bitbucket = bval(a, b)
    print a, b

    print "-----"

    let a = 0
    let b = 0
    print a, b
    let bitbucket = bref3(a, b)
    print a, b
end
