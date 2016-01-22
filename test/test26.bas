declare sub strcasecmp(s1 as cstring, s2 as cstring) as int32

sub main()
    let s1 = "Hello!"
    let s2 = "Hello!"
    let cs1 = string2cstring(s1)
    let cs2 = string2cstring(s2)
    print strcasecmp(cs1, cs2)
end
