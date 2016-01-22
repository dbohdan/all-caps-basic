#include "sds.h"

float double2float(double x) {
    return x;
}

double float2double(float x) {
    return x;
}

/* String functions. */
sds cstring2string(char* s) {
    return sdsnew(s);
}

char* string2cstring(sds s) {
    return s;
}

sds trim(sds s, sds chars) {
    sds result = sdsnew(s);
    sdstrim(result, chars);
    return result;
}

sds mid(sds s, int32_t start, int32_t length) {
    if (length == 0) {
        return sdsempty();
    }
    sds result = sdsnew(s);
    sdsrange(result, start, start + length - 1);
    return result;
}

sds concat(sds s1, sds s2) {
    sds result = sdsempty();
    result = sdscat(result, s1);
    result = sdscat(result, s2);
    return result;
}

int32_t length(sds s) {
    return sdslen(s);
}
