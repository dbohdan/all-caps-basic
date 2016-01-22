declare sub double2float(x as double) as float
declare sub float2double(x as float) as double

# String functions.
declare sub cstring2string(s as cstring) as string
declare sub string2cstring(s as string) as cstring
declare sub trim(s as string, chars as string) as string
declare sub mid(s as string, start as int32, length as int32) as string
declare sub concat(s1 as string, s2 as string) as string
declare sub length(s as string) as int32
