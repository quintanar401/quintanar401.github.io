id:{};
none:val(neg\M)1;
mkexc:{|x| if rexc is x`x`cexc is x`x`"Cc" is x`rexc!![e:x]`"!" is x`rexc!x`rexc!![e:"user";data:x]};
exc:{|x| 'exc' eff mkexc x};
tostr:{|x| if "C" is x`x`string x};
out:{|x| 'stdout' eff tostr x;};
oun:{|x| if "0:u"~xtype x`oun\M x`'stdout' eff tostr@x,"\n";};
err:{|x| 'stderr' eff tostr x;};
ern:{|x| if "0:u"~xtype x`oun\M x`'stderr' eff tostr@x,"\n";};
exc_handler:{|f e| abort(if"@"is f`f e`f)};
'\Try' set {|tf f| seff('exc';exc_handler tf;f)};
'\Err' set {|tf f| seff('err';exc_handler tf;f)};
'\ETry' set {|tf f| seff('exc';{|e|abort e};seff('err';{|e| exc ![e;st:1b]};f))};
'\R' set {|s f x y| x f\M[01b] y};
'\L' set {|s f x y| x f\M[10b] y};
'\Mi' set {|p f| {|p f a| f\M[p]. (,..max #:\M a),a}(p;f)list@};
'\I' set {|p f| f};
'\Br' set {|tf f| seff('break';{|l r| abort(if ("_"is l)|l~*r`r.1`brkat . r)}tf;f)}; brk:{|x| 'break' eff ('';x)}; brkat:{|x y| 'break' eff (x;y)};
inter:{|x y| (x in y)#x}; except:{|x y| (not x in y)#x}; union:dist,;
ncnt:{|x| if"V"is x`+\F_null x`#x}; avg:{|x| (sum if"lefb"is x`x`"l"$x)/ncnt x}; ncnts:{|x| if"V"is x`sums _null x`#x}; avgs:{|x| (sums if"lefb"is x`x`"l"$x)/ncnts x};
rrand:{|x y z| exc "domain" iff z<y; y+x?z-y};
rotn:{|n x| T(#x;n)#x}; rot:{|x| T(#x;1)#x};
til:..:; key:!:; and:&; or:|; cnt:#:; null:^:; isnt:_is@;
msum:{|n x| x-(-n)_(n#,x.0-x.0),x:sums x}; mcnt:{|n x| msum n`_^x}; mavg:{|n x| (msum n`x)/(mcnt n`x)}; mmin:{|n x| &\Pr[*x]\Do[n-1]x}; mmax:{|n x| |\Pr[*x]\Do[n-1]x}; mdev:{|n x|sqrt mavg(n;x*x)-m*m:mavg(n;x:"f"$x)};
show:{|x| out stringn x;}; dbg:{|x| show x; x};
xparse:{|x|if"r"is*r:1 INT x`exc r.0`r}; parse:*xparse@; enc:{|x y z| if"r"is r:3 INT (x;y;z)`exc r`r}; eval:{|e| (if"Cc"is e`enc . xparse@e,,e:(),e`enc((";";e);0;"eval"))()};
raze:,\F;
next:{|x| T(-1+#x;1)#@x,,x 0N};
prev:{|x| x:T(#x;-1)#x;x(0):x 0N;x};
xprev:{|x y| y:T(#y;-x)#y;y(..x):y 0N;y};
diff:"b"$not~\Pr@;
deltas:-\Pr;
flip:{|x| exc"length"iff _1=#l:dist#:\M (i:"V"is\M x)#x;(@[x;where _i;l#]. (id;)@)\M..l:*l};
mask:{|m s| 0 INT (s;"\"'([{<" in m)};
xesr:{|m s p f| i:0,"i"$,\F flip @[s;where mask(m;s);:;"\000"] ss p; ,\F@[i _s;1+2*..#@i div 2;if"@"is f`f`(:)(;f)]};
esr:xesr "\"'{([";
ssr:{|s p f| i:0,"i"$,\F flip s ss p; ,\F@[i _s;1+2*..#@i div 2;if"@"is f`f`(:)(;f)]};
esp:{|x y| T(x;0;1b;1b) vo y}; ess:{|x y| @[x;where 0 INT (x;111110b);:;"\000"] ss y};
usym:{|x|''$(if"il"is x`".x",\R str"l"$time.z+..x`".x",str"l"$time.z)};
// gen apps
app1:{|v i f| v(i):f\M v i; v};
app2:{|v i f a| v(i):if (:)~f`a`(f\M;f)(_"V" is i)(v i;a); v};
app3:{|v i f a1 a2| v(i):(f\M;f)(_"V" is i)(v i;a1;a2); v};
dapp1:{|v i f| v(i..):f\DM[1b] v . i; v};
dapp2:{|v i f a| v(i..):if (:)~f`a`f\DM[1b](v . i;a); v};
dapp3:{|v i f a1 a2| v(i..):f\DM[1b](v . i;a1;a2); v};

// records: rempty, rexc, cexc MUST be first and in this order
mrec:{|d| k:(not kk like ".*")#kk:!d; (k;d@k,();p&if'.r'in kk`not k in d'.r'`1b;p:if'.p'in kk`not k in d'.p'`#@k#1b;if'.c'in kk`d'.c'`();if'.t'in kk`d'.t'`'v';if'.f'in kk`d'.f'`0#@''!();if'.s'in kk`d'.s'`0#@''!();if'.n'in kk`d'.n'`'')};
rempty:'rec' def mrec ![]; // idx 0 has a special meaning for recs
rexc:r['.n':'exc';e:"";msg:"";data:();st:();'.c':{|rx d| d,![st:if 1b~d.st`2_val T("stack")`()]};'.f':![str:{|x|("Exception: ",x.e;"Details: ",x.msg;"Data: ",string x.data),
    raze (rev..#x.st){|x y|if"s"is y`,fmt" {x}: effect"`"C"is y`,fmt" {x}: internal"`{r:fmt" {x}: {y.4}";if#y.4`r:r,":";(r,y.5;(y.3+#r)#@" ","^")}}\M x.st};show:{|r|oun r.str}]];
cexc:r['.n':'cexc';data:();'.r':'data';'.c':{|rx d| v:,v iff ("C"is v)|_"V"is v:d.data; ,{|a x| a,if cexc is x:mkexc x`x.data`x}\F[()] v};'.f':![str:{|x|raze x.data@\L'str'};show:{|x|x.data@\L'show'}]];
// rng:r['.n':'range';x:0;y:0;st:1;'.f':![str:{|x| if x.st==1`fmt"{x.x}..{x.y}"`fmt"{x.x}..{x.y}({x.z})"}]];
path:r[p:,"."; '.n':'path'; '.f':![stat:{|p| 'dir,link,len,mt,at,ct'!'file' eff ('stat';(),p.p)};len:{|p| (p.stat).len};dir:{|p| (p.stat).dir};rdir:{|p|'file' eff ('readdir';(),p.p)};
    file:{|p| (0^1+last where v="/")_v:p.p}; ext:{|p| (cnt@v^1+last where "."=v)_v:p.file}; get:{|p| if p.ext~,"v"`val'file'eff ('read';p.p;0l;(p.stat).len;"c")`exc"notimpl"};
    read:{|p t| 'file'eff ('read';p.p;0l;(p.stat).len;t$0)}]];

// get:{|x| if xtype@x like "r:path*"`{}`val x};

time:r['.n':'time';'.f':!['z':{|| 'time' eff "z"};'t':{|| 't'$'time' eff "z"};'d':{|| 'd'$'time' eff "z"};'Z':{|| 'time' eff "Z"};'T':{|| 't'$'time' eff "Z"};'D':{|| 'd'$'time' eff "Z"}]]!();
H:{|| tm:{|m| if ('timeout'~*m)&&"0"is m`{'?timeout'eff last m;1}`none}; sig:{|m| if'sig'~*m`'sig' eff last m`none};
    add:{|r v| r.h(v 0):v 1}; run:{|r v| w:none; v; {|a h| w:h v iff"_"is w}\F[0] val r.h; w};
    r['.n':'defh';h:![timeout:tm;signal:sig];'.f':![run];'.s':![add]]!![]}();

A:![n:"0123456789";a:"c"$97+..26;A:"c"$65+..26;pi:3.141592653589793238462643383279;T:"0BXHILEFTDZCS"]; A.aA:A.a,A.A; A.t:_A.T; A.aAn:A.aA,A.n; // must be before P
P:![
    pemsg:{|t p| l:(ll:sums"\n"=t)p; @[ref ll;where t in "\n\r";:;0N]; ''ov ((ll=l)#t;((0|p-ll?l)#" "),"^")};
    ptry:{|s e| x:if cexc is e`last e.data`e; exc e iff _x.e~"pmatch"; x:![e:"pmatch";msg:''ov (x.msg;P.pemsg s`x.data);data:0]; exc if cexc is e`cexc[data:(-1_e.data),x]`x};
    pexc:{|t m| e:![e:"pmatch";msg:if"C" is m`m`"bad subexpression";data:if"a"is t`t`*t.2.0]; exc if"C"is m`e`cexc[data:(m;e)]};
    praze:{|t| ,\F t.1 @\M 0..(last@t.3^next t.2)-t.2};
    pflt:{|t| 0=sums (t.0 in '(,[,{')-t.0 in '},],)'};
    pspl:{|t c| i:where (t.0=c)&P.pflt t; t T(0,1+i;i,#t.0)};
    spl:{|f i s x| P.pexc(i;"bad ",xx.0)iff ("!"=*x)&(1+#*w:esp(xx.0;s:i _s))<>#xx:" "vo 1_x; pt[e:xx 0].adn (w.0 {|s i r| f(s;r).mv i}\M\Try[P.ptry s] w 1`''$(*:;id)("!"=*x)1_xx)};
    expr:pe:{|p s| e:xparse\Try[P.pexc p] s; pt[e:e.0;p:e.1+p;dp:p]};
    pcut:{|t c| ret t T(,0;,#t.0) iff null i:*where (t(1;;0)=c)&P.pflt t; t T(0,i+1;i,#t.0)};
    pac:{|t e ac| if 1b~*e`ac`1b~*ac`e`(('if';e.0;ac.0;0b);(t.2.0;e.1;ac.1;t.2.0))};
    plst:{|t| ret(0b;0;1b;0)iff 0=#t.0; P.pexc(t;"extra ..")iff 1<#i:where (,"..")~\R (t:P.pspl(t;';'))1; i:0W^*i; (w;c-w:_i=0W),{|ac j| ret ac iff j=i; x:t(;j); e:P.ptopf(x;if j<i`('e';j)`('e';(-;(#:;'e');c-j));x.2.0); P.pac(x;e;ac)}\F[(1b;0)] rev..c:#t.0};
    plstt:{|t ty| p:0^t.2.0; r:P.plst t; (('if';(&;(is;ty;'e');((=;>=)r.0;(#:;'e');r.1));r.2;0b);(p;p;r.3;p))};
    prec:{|t| ret(1b;0)iff 0=#t.0; t:P.pspl(t;';'); {|ac j| P.pexc(x;"name is expected")iff (_"s"is n:parse\Try[P.pexc t] x.1.0)||_'name,:'~2#(x:t(;j))0; e:P.ptopf(2_x;list('e';list n);x.2.0); P.pac(x;e;ac)}\F[(1b;0)] rev..#t.0};
    ppat:{|t| p:t.2.0; ret((~;parse\Try[P.pexc t] t.1.1;'e');p)iff (2=c:#t.0)&'@,name'~2#t.0; ret(1b;p)iff (c=1)&(t10:t.1.0)~,"_";
        {x:xparse\Try[P.pexc t] P.praze 1_t; ret if"is"~t10`((is;x.0;'e');(p;x.1;p))`(((in;~)"~"=*t10;'e';x.0);(p;p;x.1))}iff t10 in (,"~";"in";"is");
        ret((~;parse\Try[P.pexc t] t.1.0;'e');p)iff (1=c)&(t00:t.0.0) in'str,sym,num'; ret P.plstt(1_-1_t;"V")iff (')'=last t.0)&t00='('; ret P.plstt(2_-1_t;"0")iff (')'=last t.0)&(,"0";,"(")~2#t.1;
        P.pexc(t;"bad pattern")iff _t00='name'; n:parse\Try[P.pexc t]t.1.0; ret((";";(":";n;'e');1b);p)iff c=1;
        P.pexc(t;"name is expected")iff _"s"is n; ret P.plstt(2_-1_t;*t10)iff (')'=last t.0)&(t.0.1='(')&(*@t10 in A.T)&1=#t10; {t:2_-1_t; r:P.prec t; ret(('if';(is;n;'e');r.0;0b);(p;p;r.1;p))}iff (']'=last t.0)&(t.0.1='[');
        P.pexc(t;"bad pattern")};
    por:{|t| e:P.ppat*:t:P.pcut(t;"|"); ret e iff 1=#t.0; g:P.por last t; (('if';e.0;1b;g.0);(i;e.1;i:t.2.0.0;g.1))};
    ptop:{|t|{e:P.ptop 2_t; ret((";";(":";parse\Try[P.pexc t] t.1.0;'e');e.0);(t.2.0;t.2.0;e.1))}iff'name,:'~2#t.0; e:P.por*:t:P.pcut(t;"&"); ret e iff 1=#t.0; x:xparse\Try[P.pexc lt] P.praze lt:last t; (('if';e.0;x.0;0b);(i;e.1;t.2.1.0+x.1;i:t.2.0.0))};
    ptopf:{|t a p| e:P.ptop t; ret(P.psub(a;*e);e.1)iff 3>P.pcnt*:e; ((("f";,'e';e.0);a);((t.2.0;t.3.0;e.1);p))};
    psub:{|a e| if"0"is e`{if (1=#e)|"f"~*e`e`a self\R e}`'e'~e`a`e};
    pcnt:{|e| if"0"is e`{if (1=#e)|"f"~*e`0`sum self\M e}`'e'~e};
    pp:{|s| P.ptop\Try[P.ptry s] 'u'!val lex s};
    ppe:{|x| ex:none; res:,('if';0); e0:(); pe:{|p e| e:xparse\Try[P.pexc p] e; (e.0;e.1+p)}; ppe:{|p e| e:P.pp\Try[P.pexc p] e; (e.0;e.1+p)}; {|i x p| P.pexc(p;"too many =>")iff 2<#*v:esp("=>";x); e:pe p+last v 1`last v 0;
        {ex:e;ret} iff _@i&1=#v.0; {@[ref e0;id;,;,e];ret} iff 1=#v.0; pa:ppe p`v.0.0; @[ref res;id;,;(if#e0`(";",e0(;0),,pa 0;p,e0(;1),pa 1)`pa;e)]; e0:()}\Mi. esp(";";x);
        (ex;flip (if 1=#res`((";";0);('e';0))`res),if 2>#e0`e0`,(";",e0(;0);0,e0(;1)))};
    extrp:{|p|'if,iff,e'except\W dist{|p| if"0"is p`{if (~)~p0:p.0`self p.1`":"~p0`*p.1`"f"~p0`self p.2`p0 in (in;is)`''$()`raze self\M:p}`"s"is p`p`''$()} p};
    pmatch:{|s| e1:(e1.0,none;e1.1,0) iff 2%\W #*e1:last e:P.ppe\Try[P.ptry s] s; f:(("f";,'e';e1 0);(0;-1+#s;e1 1)); if"_"is e.0`f`((f.0;e.0.0);(f.1;e.0.1))};
    pmatcha:{|s| e:P.pp s; ee:(("f";,'e';('iff';('exc';"mismatch");(_:;e.0)));(0;-1+#s;(0;0;(0;e.1)))); if #v:P.extrp e.0`((";";("l";v);ee.0);(0;0;ee.1))`ee};
    pmatchf:{|s| a:0#''; res:,(";";0); {|i s p| ret @[ref a;id;,;''$n]iff (_"."in n:l.value.0)&,@'name'~(l:lex s).cat; e:P.pmatcha\Try[P.pexc p] s; @[ref a;id;,;n:''$"a",str i+1];
        @[ref res;id;,;,((e.0;n);(p+e.1;p))]}\Mi\Try[P.ptry s] . esp(";";s); res:if 1=#res`(();0)`flip res; (("f";a;'0'!res.0);(0;0|-1+#s;res.1))};
    pumsg:{|x| @[ref msgs;id;,;list x]; 1b};
    pmatchr:{|s| f:last e:P.ppe\Try[P.ptry s] s; tm:if"_"is e.0`(-1;0)`(e.0.0;e.0.1); f:(f.0,none;(f.1,0))iff #@f.0 % 2; (('recv';tm.0;("f";,'e';f.0));(0;tm.1;(0;-1+#s;f.1)))};
    mkf:{|s| x:xparse s; (("f";'x,y,z'#\W 3-{|x| if (1<#x)&"0"is x`(if"f"~x.0`3`min self\M x)`"s"is x`'z,y,x'?x`3} x.0;x.0);(0;#s;x.1))};
];

pref:!['\t':{|x| m:0;n:1;if":"=*x`{exc"iter not int"iff null "I"$n:1_(m:x?" ")#x;x:m _x};r:xparse fmt"}!time.t-last ({||!x!;}\\Do[!n!]();time.t)"; (r.0;0|r.1+m-16)}; '\?':P.pmatch; '\:':P.pmatcha; '[]':P.pmatchr;
    '\g':{|s| exc"invalid name"iff _all'name'=*e:lex s; (("g";''$e'value');0)}; '\l':{|s| .[pref('\g')s;0 0;:;"l"]}; '\L':{|s| .[pref('\g')s;0 0;:;"L"]}; '\f':P.mkf; '\\':{|s| (('exit';0^"I"$s);0)}];

// IPC
// \t {|n| {|i| {|i| sleep 1000+*1?10000; '#p' send i}\X i}\M ..n; {|i| ret 'end' iff i=0; recv[x => x]; self i-1} n } 500000 -- bottleneck(10 sec) - input queue, 75000(1 sec)
// \t {|| {|a| '#p' send a}\X 1; recv[_ => 0b]}\Do[150000]() // per second, release
msgs:();
recv0:{|| {|x| if 0=*r:'channel' eff 0`(if"_"is H.run r.1`P.pumsg r.1`1b)`0b}\Wh[id]1b};
recvt:{|tm| exc"type"iff _"izt"is tm; "i"$if"z"is tm`("l"$tm)div 1000_000`tm};
recvi:{|tm f i| st:time.z; r:if i=#m:msgs`(if 1=s:*r:'channel' eff tm`ret none`2=s`exc"closed"`3=s`ret none`(if"_"is H.run r.1`{m:m,list r.1;r.1}`ret recvi(0|tm+"i"$(st-time.z)div 1000_000;f;i)))`{msgs:(i=..#m)_m;m i}; ret res iff _"_"is res:f r; msgs:m; recvi(0|tm+"i"$(st-time.z)div 1000_000;f;i+1)};
recv:{|tm f| recv0(); recvi(recvt tm;f;0)};
recvn:{|tm f n| };
peek:{|f| recv0(); {|a m| (_"_"is f m)||a}\F[0b] msgs};
rsend:{|c m| exc"type"iff _"#"is c:if"s"is c`val c`c; 'channel' eff (c;r:req[msg:m;ch:'#s']); r};
rwait:{|h c| exc"type"iff _"#"is c:if"s"is c`val c`c; {|| (if (cexc is v)|rexc is v`exc v`ret v) iff _"_"is v:recv(1000;h); exc"closed"iff _val c; self()}()};
ssend:{|c m| r:rsend c`m; rwait {|id m| if (('repl';id)~2#m)&&"0"is m`last m`none} r.id`c};
ask:{|c m| h:{|m| if ('repl'~*m)&&"0"is m`last m`none}; if "_"is r:dbg recv(0;h)`{ssend c`m;rwait h`c}`'ack'~r 2`rwait(h;c)`r}; // 3 cases: repl, ask -> repl, request -> ask repl
send:{|c m| exc"type"iff _"#"is c:if"s"is c`val c`c; 'channel' eff (c;m)};
req:r['.n':'req';msg:();id:0Nz;ch:0b;'.c':{|rx d| d.id:time.z iff ^d.id; d.ch:val d.ch iff"s"is d.ch; exc"type"iff _"#"is d.ch; d};'.f':![repl:{|r v| 'channel' eff (r.ch;('repl';r.id;v))};
    exc:{|r e| r.repl mkexc e};ack:{|r| 'channel' eff (r.ch;('repl';r.id;'ack'))}]];
sleep:{|t| recv t`{||none}}; exit:{|x| exc"type" iff _"i"is x; send '#m'`('exit';x)};
// flush:{|x| i:0; {|| recv(0;{|m| show m iff 1b~x; i:i+1; 1b})}\Wh[isnt "_"]0; i};
flush:{|x| recv(0;{|m| none}); m:msgs; msgs:(); show\M m iff 1b~x; #m};
// '\X' set {|p f a| 'spawn' eff (val T("xenv");(f;a))};
'\X' set {|p f| {|f a| 'spawn' eff (val T("xenv");,@f,a)}(f)list@};
'\TO' set {|tf f| tf {|t i| sleep t; send '#p'`('timeout';i)}\X i:time.z; seff('?timeout';{|i m| if i~m`exc"timeout"`'?timeout' eff m}i;f)};

V:![
    main:{|c| val p["main.v"].read "c"; main c};
];

fnf:'a,x,l,c,g,s,i,t,p,n';
// at:"0bxhileftdzcs"
