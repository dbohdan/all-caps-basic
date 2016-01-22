sub main()
    let s1 = "foo"
    let s2 = "foo"
    let s3 = "bar"
    if s1 eq s2
        print s1, "equals", s2
    end
    if s2 ne s3
        print s2, "doesn't equal", s3
    end
    if s3 eq s3
        print s3, "equals", s3
    end
end
