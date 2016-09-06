This is cpcfs from https://github.com/derikz/cpcfs ,
commit c37e4bd8adaba240bfeef836ef157d1fdd236851 .

I patched it to be able to compile without errors (but still it throws a lot of
warnings):

* tools.c: added

    ~~~
    #if UNIX
    #include <errno.h>
    #endif
    ~~~

* cpcfs.h: changed

        #define STAMP    __DATE__ ## " " ## __TIME__

    by

        #define STAMP    __DATE__ " " __TIME__

*Jorge Giner*
