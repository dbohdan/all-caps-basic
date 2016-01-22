#ifndef __CPRELUDE_H_INCLUDED
#define __CPRELUDE_H_INCLUDED

#define not(x) (!x)
#define TRUE true
#define FALSE false

float double2float(double x);
double float2double(float x);
sds cstring2string(char* s);
char* string2cstring(sds s);
sds trim(sds s, sds chars);
sds mid(sds s, int32_t start, int32_t length);
sds concat(sds s1, sds s2);
int32_t length(sds s);

#endif
