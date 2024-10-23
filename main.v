stdin:{||
    repl\X 0;
    '#m' ('reg';'stdin';val'#s');
    {|| recv[r:is req => {out (),if"Cc"is m:r.msg`m`">"; r.repl 'stdin' eff ref stdin}; ('sync';ch) => ch send 'sync'; m => ern fmt"unexpected stdin msg: {m}"]; self()}()
};
repl:{||
    '#m' ('reg';'repl';val'#s');
    f:{|| ini:0b; '#p' send ('sync';val'#s');
        {|| out stringn if ini`val'#p' ()`recv['sync' => {ini:1b;}; ('repl';_;x) => val x]; self()}()};
    V.pset'restart'`1b; V.pset'rlimit'`0W; V.pset'rfn'`f;
    f()
};
env:{||
    emap:![];
    '#m' ('reg';'env';val'#s');
    {||
        recv[r:is req => ?[m:r.msg;
                is"Ccs" => r.repl if (s:''$c:tostr m)in!emap`emap s`emap(s):'env' eff c;
                ~id => r.repl emap;
                r.exc fmt"env: unsupported request: {r}"
            ];
            (n:is"s";v) => emap(n):v; // setenv is not safe, use emulation
            ern fmt"env: unsupported msg: {r}"
        ];
        self()
    }();
};
mod:{|| '#m' ('reg';'mod';val'#s'); recv[m => {p["modules/mod/mod.v"].get; none}]; start() };
listen:{|rq n p f|
    if "#"is ch:{|p| 'net'eff (0x02;0l;p;0x07)}\ETry p:"i"$p`rq.repl ch`ret rq.exc ch; rq:0;
    ch send 'port' iff p=0;
    acc:{|d ach f|
        (d.ch:ach) send val '#s'; f.open ref d;
        {||
            recv[
                ('msg';m) => if "X"is m:V.xser\ETry(m;'req')`ach send ('msg';m)`ern fmt"connect: bad msg {m}";
                ('connect';_;'msg';m) => {:[m;fl] V.xdeser m; (f'repl,msg,req,ctrl'fl%4) ref d`m};
                ('connect';_;'err';er) => ret f.close er;
                ('connect';_;'stop') => ret f.close"stop";
                'stop' => {ach send 'stop'; ret f.close""};
                'abort' => {ach send 'abort'; ret f.close""};
                m => ern fmt"connect: unsupported message: {m}"
            ];
            self() // no check for ach, we must get err/stop first
        }()
    };
    f:![check:{||oun "check"; 1b};open:{|d|oun fmt"open {val d}"};close:{|e|ern fmt"connect close: {e}"};msg:{|d m| val\ETry[{|e|e.show}] m};
        req:{|d m| v:V.xser((m 0;"unserializable");'repl') iff _"X"is v:V.xser((m 0;val\ETry m 1);'repl'); d.ch send ('msg';v)};
        repl:{|d m| ern fmt"repl {m}"};ctrl:{|d m| ern fmt"ctrl {m}"}],if"!"is f`f`![];
    {||
        recv[1000;
            r:is req => ?[r.msg;
                'stop' => {ch send 'stop';r.repl 1b}
            ];
            ('accept';ip;d;ach) => {v:'ip,uname,pass,desc'!ip,3#("\000" vo d),("";""); if f.check ref v`acc\X(v;ach;f)`ach send 0};
            ('listen';'port';v) => p:v;
            ('listen';'err';er) => ern fmt"listen {n}: error: {er}";
            ('accept';'err';ip;er) => ern fmt"listen {n}: accept error on ip {256 vo ip}: {er}";
            ern fmt"listen {n}: unsupported message: {r}"
        ];
        ret ern fmt"listen {n}: closed" iff _val ch;
        self()
    }()
};

main:{|sch|
    15 INT (V.tzinfo "/etc/localtime")'tm,shift' iff A.family~"unix";
    stdin\X[![repl;stdin:sch]] (); sch:0; env\X(); mod\X[![start:{|| exc "undefined"}]]();
    'pmap' set ![];
    {||recv[
        r:is req => ?[r.msg;
            ('reg';nm:is"s";ch:is"#") => if (val c)&&"#"is c:pmap nm:''$"#",str nm`r.exc "exists"`{pmap(nm):ch; r.repl 1b};
            ('cwd';pp:is"C") => {'file' eff ('cwd';pp); r.repl p[].cwd};
            nm:is"s" & nm like "[@#]*" => r.repl if (val ch)&&"#"is ch:pmap nm`ch`mkexc "unavailable";
            ('listen';n:is"s";p:is"ijh";f) => if (val ch)&&"#"is ch:pmap nm:''$"@",str n`r.exc"exists"`pmap(nm):listen\XX[![ch:1b]](r;nm;p;f);
            // ('listen';n:is"s") => if (val ch)&&"#"is ch:pmap nm:''$"@",str n`r.repl ch`r.exc"unavailable";
            ern fmt"main: unsupported request: {r}"
        ];
        ('exit';i) => 4 INT i;
        'abort' => if val@c && "#"is c:pmap'#repl' `c send ('sig';'break')`4 INT i;
        ern fmt"main: unsupported msg: {r}";
    ]; self()}();
};