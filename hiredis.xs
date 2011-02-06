#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include "ppport.h"
#include <xs_object_magic.h>
#include "hiredis.h"
#include "async.h"

typedef int redisErrorCode;

typedef struct {
    SV *callback;
    char **argv;
    size_t *arglen;
    PerlInterpreter *my_perl;

    unsigned int callback_ok:1;
    unsigned int argv_ok:1;
    unsigned int arglen_ok:1;
} callbackContext;

SV* redisReplyToSV(redisReply *reply){
    SV *result;
    AV *array;
    int i;
    struct redisReply **elements;

    if(reply){
        switch(reply->type){
            case REDIS_REPLY_STATUS:
            case REDIS_REPLY_STRING:
            case REDIS_REPLY_ERROR:
                result = sv_2mortal(newSVpvn(reply->str, reply->len));
                break;

            case REDIS_REPLY_INTEGER:
                result = sv_2mortal(newSViv(reply->integer));
                break;

            case REDIS_REPLY_ARRAY:
                array = newAV();
                for(i = 0; i < reply->elements; i++){
                    elements = reply->element;
                    result = redisReplyToSV(elements[i]);
                    av_push(array, result);
                    result = NULL;
                }
                result = sv_2mortal(newRV_inc((SV *)array));
                break;

            default:
                result = &PL_sv_undef;
                break;
       }
    }
    else {
        result = &PL_sv_undef;
    }

    return result;
}

void redisAsyncHandleCallback(redisAsyncContext *ac, void *_reply, void *_privdata){
    SV *result;
    callbackContext *c;
    redisReply *reply;
    SV *callback;
    PerlInterpreter *my_perl;

    if(_privdata == NULL)
        croak("OH NOES!  Null privdata passed to redisAsyncHandleCallback!");

    reply = _reply;
    c = _privdata;
    my_perl = c->my_perl;
    callback = c->callback;

    if(_reply == NULL) { /* we're shutting down or something */
        if(c->argv_ok){
            Safefree(c->argv);
            c->argv_ok = 0;
        }

        if(c->arglen_ok){
            Safefree(c->arglen);
            c->arglen_ok = 0;
        }

        SvREFCNT_dec(callback);
        c->callback_ok = 0;

        Safefree(c);
        return;
    }

    result = redisReplyToSV(reply);
    dSP;
    PUSHMARK(SP);
    XPUSHs(result); /* result */
    if(reply->type == REDIS_REPLY_ERROR){ /* is success? */
        XPUSHs(&PL_sv_no);
    }
    else {
        XPUSHs(&PL_sv_yes);
    }
    PUTBACK;

    Perl_call_sv(aTHX_ callback, G_DISCARD);

}

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

void
redisAsyncFree(redisAsyncContext *ac)

void
redisAsyncIsAllocated(SV *self)
    PPCODE:
        void *s = xs_object_magic_get_struct(aTHX_ SvRV(self));
        EXTEND(SP, 2);
        if(s == NULL)
            PUSHs(&PL_sv_no);
        else
            PUSHs(&PL_sv_yes);

redisErrorCode
redisAsync_Command(redisAsyncContext *ac, AV *args, SV *callback)
    PREINIT:
        int i;
        STRLEN len;
        char **argv;
        size_t *arglen;
        int argc;
        SV **elt;
        callbackContext *c;
    CODE:
        argc = av_len(args);
        if(argc < 0)
            croak("Must supply command to execute!");
        argc++; /* av_len returns last index, which is one less than the length */

        Newx(argv, argc, char *);
        if(!argv)
            croak("Out of memory while allocating argv!");

        Newx(arglen, argc, size_t);
        if(!arglen){
            Safefree(argv);
            croak("Out of memory while allocating arglen array!");
        }

        Newx(c, 1, callbackContext);
        if(!c){
            Safefree(argv);
            Safefree(arglen);
            croak("Out of memory while allocating callback context!");
        }

        for(i = 0; i < argc; i++){
            argv[i] = NULL;
            elt = av_fetch(args, i, 0);
            if(elt != NULL){
                argv[i] = SvPV(*elt, len);
                arglen[i] = len;
                /* printf("array element %d:%s,\n", len, argv[i]); */
            }
        }

        c->my_perl  = my_perl;
        c->callback = SvREFCNT_inc_simple(callback);
        c->argv     = argv;
        c->arglen   = arglen;
        c->callback_ok = c->argv_ok = c->arglen_ok = 1;

        RETVAL = redisAsyncCommandArgv(ac, &redisAsyncHandleCallback, c, argc, (const char **) argv, arglen);

void
redisAsyncHandleRead(redisAsyncContext *ac)

void
redisAsyncHandleWrite(redisAsyncContext *ac)

void
redisAsyncDisconnect(redisAsyncContext *ac)

void
redisAsyncGetFd(redisAsyncContext *ac)
    PPCODE:
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(ac->c.fd)));
