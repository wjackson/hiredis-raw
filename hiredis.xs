#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include "ppport.h"
#include <xs_object_magic.h>
#include "hiredis.h"
#include "async.h"

MODULE = Hiredis::Raw	PACKAGE = Hiredis::Raw   PREFIX = redis
PROTOTYPES: DISABLE

void
redisVersion()
    PPCODE:
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(HIREDIS_MAJOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_MINOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_PATCH)));

MODULE = Hiredis::Raw  PACKAGE = Hiredis::Async  PREFIX = redisAsync
PROTOTYPES: DISABLE

void
redisAsyncConnect(SV *self, const char *host="localhost", int port=6379)
    PREINIT:
        redisAsyncContext *ac;
    CODE:
        ac = redisAsyncConnect(host, port);
        if (ac->err) {
            croak("Failed to create async connection: %s", ac->errstr);
        }
        xs_object_magic_attach_struct(aTHX_ SvRV(self), ac);
