#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include "ppport.h"
#include <xs_object_magic.h>
#include <hiredis.h>

MODULE = Hiredis::Raw	PACKAGE = Hiredis::Raw   PREFIX = redis
PROTOTYPES: DISABLE

void
redisVersion()
    PPCODE:
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(HIREDIS_MAJOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_MINOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_PATCH)));
