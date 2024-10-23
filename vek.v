id:{};
none:val(neg\M)1;
string:{|x|string_ (x;'sysparam'eff"w")};stringn:{|x|stringn_ (x;'sysparam'eff"w")};tostr:{|x| if"Cc"is x`(),x`"s"is x`str x`string x};
out:{|x| 'stdout' eff tostr x;};
oun:{|x| if "0:u"~xtype x`self\M x`'stdout' eff tostr@x,"\n";};
err:{|x| 'stderr' eff tostr x;};
ern:{|x| if "0:u"~xtype x`self\M x`'stderr' eff tostr@x,"\n";};

// records: rempty, rexc, cexc MUST be first and in this order
mrec0:{|d| k:(not kk like ".*")#kk:!d; (k;d@k,();p&if'.r'in kk`not k in d'.r'`1b;p:if'.p'in kk`not k in d'.p'`#@k#1b;if'.c'in kk`d'.c'`();if'.t'in kk`d'.t'`'v';if'.f'in kk`d'.f'`0#@''!();if'.s'in kk`d'.s'`0#@''!();
    if'.n'in kk`d'.n'`'';if sn`d'.sn'`'';if'.ser'in kk`d'.ser'`(::;{|r f|'0'!r})sn;if'.deser'in kk`d'.deser'`(::;{|r v f| r!v})sn:'.sn'in kk;if'.scnt'in kk`d'.scnt'`{|r f| if (::)~f:('rec'!r)10`f`16 INT f(r;f)})};
rempty:'rec'def mrec0!['.sn':'emptpy']; // idx 0 has a special meaning for recs
rexc:'rec'def mrec0!['.n':'exc';'.sn':'exc';e:"";msg:"";data:();st:();'.c':{|rx d| d,![st:if 1b~d.st`2_val T("stack")`()]};'.ser':{|r f| v:'0'!r;v(3):r.ststr;v};'.f':![str:{|x|("Exception: ",x.e;"Details: ",x.msg;"Data: ",string x.data),x.ststr};
    ststr:{|x|,\F (rev..#x.st){|x y|if"s"is y`,fmt" {x}: effect {y}"`"C"is y`,(if #y`fmt" {x}: barrier '{y}'"`fmt" {x}: internal")`{r:fmt" {x}: {y.4}";if#y.4`r:r,":";(r,y.5;(y.3+#r)#@" ","^")}}\M x.st};show:{|r|oun r.str}]];
cexc:'rec'def mrec0!['.n':'cexc';'.sn':'cexc';data:();'.r':'data';'.c':{|rx d| v:,v iff ("C"is v)|_"V"is v:d.data; ,{|a x| a,if (last rx) is x`x.data`rexc is x`x`"Cc" is x`rexc!![e:(),x]`"!" is x`rexc!x`rexc!![e:"user";data:x]}\F[()] v}; // can't ref mkexc
    '.f':![str:{|x|,\F x.data@\M[10b]'str'};show:{|x|x.data@\M[10b]'show'}]];
mkexc:{|x| if rexc is x`x`cexc is x`x`"Cc" is x`rexc!![e:(),x]`"!" is x`rexc!x`rexc!![e:"user";data:x]};
exc:{|x| 'exc' eff mkexc x};
exc_handler:{|f e| abort(if"@"is f`f e`"_"is f`e`f)};
mrec:{|d| d:mrec0 d; exc![e:"assigns";msg:","ov str g 1]iff #(g:10 INT (!e;val e:val T("env");d))1; exc![e:"globals";msg:","ov str (_i)#g 0]iff _all i:g.0 in !e; e:g.0#e; e(i:''$str..#d):d; (5 INT (e;0#''))i}; // add globals control

// gen apps
app1:{|v i f| v(i):(f\M;f)(_"V" is i) v i; v};
app2:{|v i f a| v(i):if (:)~f`a`(f\M;f)(_"V" is i)(v i;a); v};
app3:{|v i f a1 a2| v(i):(f\M;f)(_"V" is i)(v i;a1;a2); v};
dapp1:{|v i f| v(i..):f\DM[1b] v . i; v};
dapp2:{|v i f a| v(i..):if (:)~f`a`f\DM[1b](v . i;a); v};
dapp3:{|v i f a1 a2| v(i..):f\DM[1b](v . i;a1;a2); v};

'\Try' set {|tf f| seff('exc';exc_handler tf;f)};
'\Err' set {|tf f| seff('err';exc_handler tf;f)};
'\ETry' set {|tf f| seff('exc';{|e|abort e};seff('err';{|e| exc ![e;st:1b]};f))};
'\R' set {|s f x y| x f\M[01b] y};
'\L' set {|s f x y| x f\M[10b] y};
'\Mi' set {|p f| {|p f a| f\M[p]. (,..max #:\M a),a}(p;f)list@};
'\I' set {|p f| f};
'\Br' set {|tf f| seff('break';{|l r| abort(if ("_"is l)|l~*r`r.1`brkat . r)}tf;f)}; brk:{|x| 'break' eff ('';x)}; brkat:{|x y| 'break' eff (x;y)};
'\Lock' set {|p f| exc "locked" iff locked p; seff('?lock';{|v1 v2| if v1~v2`1b`'?lock' eff v2}p;f)}; locked:{|v| 0b^'?lock' eff v};
inter:{|x y| (x in y)#x}; except:{|x y| (not x in y)#x}; union:dist,;
ncnt:{|x| if"V"is x`+\F_^ x`#x}; avg:{|x| (sum if"lefb"is x`x`"l"$x)/ncnt x}; ncnts:{|x| if"V"is x`sums _null x`#x}; avgs:{|x| (sums if"lefb"is x`x`"l"$x)/ncnts x};
rrand:{|x y z| exc "domain" iff z<y; y+x?z-y};
rotn:{|n x| T(#x;n)#x}; rot:{|x| T(#x;1)#x};
til:..:; key:!:; and:&; or:|; cnt:#:; null:^:; isnt:_is@;
msum:{|n x| x-(-n)_(n#,x.0-x.0),x:sums x}; mcnt:{|n x| msum n`_^x}; mavg:{|n x| (msum n`x)/(mcnt n`x)}; mmin:{|n x| &\Pr[*x]\Do[n-1]x}; mmax:{|n x| |\Pr[*x]\Do[n-1]x}; mdev:{|n x|sqrt mavg(n;x*x)-m*m:mavg(n;x:"f"$x)};
show:{|x| out stringn_ (x;'sysparam'eff"w");}; dbg:{|x| show x; x};
xparse:{|x|if"r"is*r:1 INT (x;val'.pref')`exc *r`r}; parse:*xparse@; enc:{|x y z| if"r"is r:3 INT (x;y;z)`exc r`r}; eval:{|e| (if"Cc"is e`enc . xparse@e,,e:(),e`enc((";";e);0;"eval"))()};
raze:,\F;
next:{|x| if #x`T(-1+#x;1)#@x,,x 0N`x};
prev:{|x| {x:T(#x;-1)#x;x(0):x 0N} iff #x;x};
xprev:{|x y| y:T(#y;-x)#y;y(..x):y 0N;y};
diff:"b"$not~\Pr@;
deltas:-\Pr;
//flip:{|x| exc"length"iff _1=#l:dist#:\M (i:"V"is\M x)#x;(@[x;where _i;l#]. (id;)@)\M..l:*l};
mask:{|m s| 0 INT (s;"\"'([{<" in m)};
xesr:{|m s p f| i:0,"i"$,\F flip @[s;where mask(m;s);:;"\000"] ss p; ,\F@[i _s;1+2*..#@i div 2;if"@"is f`f`(:)(;f)]};
esr:xesr "\"'{([";
ssr:{|s p f| i:0,"i"$,\F flip s ss p; ,\F@[i _s;1+2*..#@i div 2;if"@"is f`f`(:)(;f)]};
esp:{|x y| T(x;0;1b;1b) vo y}; ess:{|x y| @[x;where 0 INT (x;111110b);:;"\000"] ss y};
usym:{|x|''$(if"il"is x`".x",\R str"l"$time.z+..x`".x",str"l"$time.z)};
sysenv:{|c|'env' eff tostr c};getenv:{|x|('#m''#env')x};setenv:{|n v| if"s"is n`send('#m''#env';(n;v))`exc"type"};

// rng:r['.n':'range';x:0;y:0;st:1;'.f':![str:{|x| if x.st==1`fmt"{x.x}..{x.y}"`fmt"{x.x}..{x.y}({x.z})"}]];
path:r[p:,"."; '.n':'path'; '.f':![stat:{|p| 'dir,link,len,mt,at,ct'!'file' eff ('stat';(),p.p)};len:{|p| (p.stat).len};dir:{|p| (p.stat).dir};rdir:{|p|'file' eff ('readdir';(),p.p)};
    file:{|p| (0^1+last where v="/")_v:p.p}; ext:{|p| (cnt@v^1+last where "."=v)_v:p.file}; get:{|p| if p.ext~,"v"`val'file'eff ('read';p.p;0l;(p.stat).len;"c")`exc"notimpl"};
    read:{|p t| 'file'eff ('read';p.p;0l;(p.stat).len;t$0)};cd:{|a c| v:a.p; a[p:v,"/",if"0"is c`"/"ov c`"S"is c`"/"ov str c`tostr c]};cwd:{|pp| pp[p:'file' eff ('cwd';"")]}]];

// get:{|x| if xtype@x like "r:path*"`{}`val x};
time:r['.n':'time';'.f':!['z':{|| 'time' eff "z"};'t':{|| 't'$'time' eff "z"};'d':{|| 'd'$'time' eff "z"};'Z':{|| 'time' eff "Z"};'T':{|| 't'$'time' eff "Z"};'D':{|| 'd'$'time' eff "Z"}]]!();
atomic:r['.n':'atomic';'.f':!['new':{|x i| 6 INT "l"$i};'add':{|x a i| 6 INT (a;0x03;"l"$i;0)};'set':{|x a i| 6 INT (a;0x00;"l"$i;0)};'get':{|x a| 6 INT (a;0x01;0l;0)};'swap':{|x a i| 6 INT (a;0x04;"l"$i;0)};'cmpx':{|x a i j| 6 INT (a;0x02;"l"$i;"l"$j)}]]!();
// bmap:r['.n':'bmap';b:0#0x0;mn:0Nl;'.f':![]];

{A:![n:"0123456789";a:"c"$97+..26;A:"c"$65+..26;pi:3.141592653589793238462643383279;T:"0BXHILEFTDZCS";os:'sysparam'eff"o";arch:'sysparam'eff"a";family:'sysparam'eff"f";sysparams:'restart,rlimit,rvalue,rfn,wh'!"rlRFw"]; A.aA:A.a,A.A; A.t:_A.T; A.aAn:A.aA,A.n}; // must be before P, {} - required
nargs:{|f| if"@"is f`1^"I"$A.n inter\W t:(t?",")#t:xtype f`1};

P:5 INT ![pemsg:{|t p| l:(ll:sums"\n"=t)p; @[ref ll;where t in "\n\r";:;0N]; ''ov ((ll=l)#t;((0|p-ll?l)#" "),"^")};
    ptry:{|s e| x:if cexc is e`last e.data`e; exc e iff _x.e~"pmatch"; x:![e:"pmatch";msg:''ov (x.msg;pemsg s`x.data);data:0]; exc if cexc is e`cexc[data:(-1_e.data),x]`x};
    pexc:{|t m| e:![e:"pmatch";msg:if"C" is m`m`"bad subexpression";data:if"a"is t`t`*t.2.0]; exc if"C"is m`e`cexc[data:(m;e)]};
    praze:{|t| ,\F t.1 @\M 0..(last@t.3^next t.2)-t.2};
    pflt:{|t| 0=sums (t.0 in '(,[,{')-t.0 in '},],)'};
    pspl:{|t c| i:where (t.0=c)&pflt t; t T(0,1+i;i,#t.0)};
    pe:{|p e| e:xparse\Try[pexc p] e; (e.0;e.1+p)};
    pcut:{|t c| ret t T(,0;,#t.0) iff null i:*where (t(1;;0)=c)&pflt t; t T(0,i+1;i,#t.0)};
    pac:{|t e ac| if 1b~*e`ac`1b~*ac`e`(('if';e.0;ac.0;0b);(t.2.0;e.1;ac.1;t.2.0))};
    plst:{|t| ret(0b;0;1b;0)iff 0=#t.0; pexc(t;"extra ..")iff 1<#i:where (,"..")~\R (t:pspl(t;';'))1; i:0W^*i; (w;c-w:_i=0W),{|ac j| ret ac iff j=i; x:t(;j); e:ptopf(x;if j<i`('1';j)`('1';(-;(#:;'1');c-j));x.2.0); pac(x;e;ac)}\F[(1b;0)] rev..c:#t.0};
    plstt:{|t ty| p:0^t.2.0; r:plst t; (('if';(&;(is;ty;'1');((=;>=)r.0;(#:;'1');r.1));r.2;0b);(p;p;r.3;p))};
    prec:{|t| ret(1b;0)iff 0=#t.0; t:pspl(t;';'); {|ac j| pexc(x;"name is expected")iff (_"s"is n:parse\Try[pexc t] x.1.0)||_'name,:'~2#(x:t(;j))0; e:ptopf(2_x;list('1';list n);x.2.0); pac(x;e;ac)}\F[(1b;0)] rev..#t.0};
    ppat:{|t| p:t.2.0; ret((~;parse\Try[pexc t] t.1.1;'1');p)iff (2=c:#t.0)&'@,name'~2#t.0; ret(1b;p)iff (c=1)&(t10:t.1.0)~,"_";
        {x:pe t.2.1`praze 1_t; ret if"is"~t10`((is;x.0;'1');(p;x.1;p))`(((in;~)"~"=*t10;'1';x.0);(p;p;x.1))}iff t10 in (,"~";"in";"is");
        ret((~;parse\Try[pexc t] t.1.0;'1');p)iff (1=c)&(t00:t.0.0) in'str,sym,num'; ret plstt(1_-1_t;"V")iff (')'=last t.0)&t00='('; ret plstt(2_-1_t;"0")iff (')'=last t.0)&(,"0";,"(")~2#t.1;
        pexc(t;"bad pattern")iff _t00='name'; n:parse\Try[pexc t]t.1.0; ret((";";(":";n;'1');1b);p)iff c=1;
        pexc(t;"name is expected")iff _"s"is n; ret plstt(2_-1_t;*t10)iff (')'=last t.0)&(t.0.1='(')&(*@t10 in A.T)&1=#t10; {t:2_-1_t; r:prec t; ret(('if';(is;n;'1');r.0;0b);(p;p;r.1;p))}iff (']'=last t.0)&(t.0.1='[');
        pexc(t;"bad pattern")};
    por:{|t| e:ppat*:t:pcut(t;"|"); ret e iff 1=#t.0; g:por last t; (('if';e.0;1b;g.0);(i;e.1;i:t.2.0.0;g.1))};
    ptop:{|t|{e:ptop 2_t; ret((";";(":";parse\Try[pexc t] t.1.0;'1');e.0);(t.2.0;t.2.0;e.1))}iff'name,:'~2#t.0; e:por*:t:pcut(t;"&"); ret e iff 1=#t.0; x:xparse\Try[pexc lt] praze lt:last t; (('if';e.0;x.0;0b);(i;e.1;t.2.1.0+x.1;i:t.2.0.0))};
    ptopf:{|t a p| e:ptop t; ret(psub(a;*e);e.1)iff 3>pcnt*:e; ((("f";,'1';e.0);a);((t.2.0;t.3.0;e.1);p))};
    psub:{|a e| if"0"is e`{if (1=#e)|"f"~*e`e`a self\R e}`'1'~e`a`e};
    pcnt:{|e| if"0"is e`{if (1=#e)|"f"~*e`0`sum self\M e}`'1'~e};
    pp:{|s| ptop\Try[ptry s] 'u'!val lex s};
    ppe:{|x| ex:none; res:,('if';0); e0:(); ppe:{|p e| e:pp\Try[pexc p] e; (e.0;e.1+p)}; {|i x p| pexc(p;"too many =>")iff 2<#*v:esp("=>";x); e:pe p+last v 1`last v 0;
        {ex:e;ret} iff _@i&1=#v.0; {@[ref e0;id;,;,e];ret} iff 1=#v.0; pa:ppe p`v.0.0; @[ref res;id;,;(if#e0`(";",e0(;0),,pa 0;p,e0(;1),pa 1)`pa;e)]; e0:()}\Mi. esp(";";x);
        (ex;flip (if 1=#res`((";";0);('1';0))`res),if 2>#e0`e0`,(";",e0(;0);0,e0(;1)))};
    extrp:{|p|'if,iff,e'except\W dist{|p| if"0"is p`{if (~)~p0:p.0`self p.1`":"~p0`*p.1`"f"~p0`self p.2`p0 in (in;is)`''$()`raze self\M:p}`"s"is p`p`''$()} p};
    pmatch:{|s| e1:(e1.0,none;e1.1,0) iff 2%\W #*e1:last e:ppe\Try[ptry s] s; f:(("f";,'1';e1 0);(0;-1+#s;e1 1)); psubret if"_"is e.0`f`((f.0;e.0.0);(f.1;e.0.1))};
    pmatcha2:{|s| e:pp s; ee:(("f";,'1';('iff';('exc';"mismatch");(_:;e.0)));(0;-1+#s;(0;0;(0;e.1)))); if #v:extrp e.0`((";";("l";v);ee.0);(0;0;ee.1))`ee};
    pmatcha:{|s| pmatcha2 if #*ess(s;";")`"(",s,")"`s};
    pmatchf:{|s| a:0#''; res:,(";";0); {|i s p| ret @[ref a;id;,;''$n]iff (_"."in n:l.value.0)&,@'name'~(l:lex s).cat; e:pmatcha2\Try[pexc p] s; @[ref a;id;,;n:''$"a",str i+1];
        @[ref res;id;,;,((e.0;n);(p+e.1;p))]}\Mi\Try[ptry s] . esp(";";s); res:if 1=#res`(();0)`flip res; (("f";a;'0'!res.0);(0;0|-1+#s;res.1))};
    pmatchr:{|s| f:last e:ppe\Try[ptry s] s; tm:if"_"is e.0`(365D;0)`(e.0.0;e.0.1); f:(f.0,none;(f.1,0))iff #@f.0 % 2; psubret (('recv';time.z;tm.0;("f";,'1';f.0));(0;0;tm.1;(0;0|-1+#s;f.1)))};
    pchret:{|e p r| if"0"is e`(if ("f";,'1')~2#e`{v:self(e 2;p 2;r);((e 0;e 1;v 0);(p 0;p 1;v 1))}`(seff;list('ret'))~2#e`{r(::):1b;(3_e;3_p)}`
        'ret'~*e`{r(::):1b;((eff;list('ret');if 2=#e`e 1`1_e);(p 0;p 0;if 2=#e`p 1`1_p))}`1<#e`{v:self(;;r)\M(e;p);('0'!v(;0);v(;1))}`(e;p))`'ret'~e`{r(::):1b;((eff;list('ret');());p)}`(e;p)};
    psubret:{|e| r:0b; v:pchret e 0`e 1`ref r; if r`((seff;list('ret');{|x|abort x}),if"f"~*v 0`,v 0`v 0;0 0 0,if"f"~*v 0`,v 1`v 1)`e};
    mkf:{|s| x:xparse s; (("f";'x,y,z'#\W 3-{|x| if (1<#x)&"0"is x`(if"f"~x.0`3`min self\M x)`"s"is x`'z,y,x'?x`3} x.0;x.0);(0;#s;x.1))};
];

// IPC
// \t {|n| {|i| {|i| sleep 1000+*1?10000; '#p' send i}\X i}\M ..n; {|i| ret 'end' iff i=0; recv[x => x]; self i-1} n } 500000 -- 2 mil are handled well (35 secs), 75000(1 sec)
// \t {|| {|a| '#p' send a}\X 1; recv[_ => 0b]}\Do[150000]() // per second, release
req:r['.n':'req';msg:();id:0Nz;ch:0b;'.c':{|rx d| d.id:time.z iff ^d.id; d.ch:val d.ch iff"s"is d.ch; exc"type"iff _"#"is d.ch; d};'.f':![repl:{|r v| 'channel' eff (r.ch;('repl';r.id;v))};
    exc:{|r e| r.repl mkexc e};ack:{|r| 'channel' eff (r.ch;('repl';r.id;'ack'))}]];
recvt:{|tm| exc"type"iff _"izt"is tm; tm:"z"$if"i"is tm`"t"$tm`tm; if tm>1000D`tm`time.z+tm}; recvc:{|c| exc"type"iff _"#"is c:if"s"is c`(if c in'#p,#m,#s'`val c`'#m'c)`c; c};
recv1:{|ix tm m| if 1=s:*r:'channel' eff (ix;m;"i"$(0|tm-time.z)div 1000_000)`none`2=s`exc"closed"`3=s`none`(if"_"is H.run r.1`r.1`self(ix;tm;none))};
recvi:{|ix tm f m| ret none iff"_"is m:recv1(ix;tm;m); if"_"is r:f m`self(ix;tm;f;m)`r};
recv:{|ix tm f| recvi("l"$ix;recvt tm;f;none)};
rwait:{|h c| c:recvc c; ix:time.z; {|| (if (cexc is v)|rexc is v`exc v`ret v) iff _"_"is v:recv(ix;10000;h); exc"closed"iff _val c; self()}()};
ssend:{|c m| 'channel' eff (c:recvc c;r:req[msg:m;ch:'#s']); rwait {|id m| if (('repl';id)~2#m)&&"0"is m`last m`none} r.id`c};
send:{|c m| 'channel' eff (recvc c;m)};
sleep:{|t| recv time.z`t`{||none}}; exit:{|x| exc"type" iff _"i"is x; send '#m'`('exit';x)};
flush:{|x| c:0; {||0b^recv(0;0;{|m| c:c+1;{oun"----> msg";show m}iff 1b~x;1b})}\Wh 1b; c}; peek:{|x| x:0W iff _"il"is x; recv(time.z;0;{|m| {oun"----> msg";show m}iff 0<=x:x-1; none});};
V:{|| ![
    main:{|c| p["main.v"].get; main c};globals:{|e v| 10 INT (!e;val e;v)};args:{|| 'env' eff 0};voml:{|s| if rexc is r:11 INT s`exc r`r};be:(upper;id)b;le:(id;upper)b:1=*"i" ov 0x0 vo 1;
    tzinfo:{|d| exc"format" iff _("x"$"TZif")~4#d:p[d].read"x"; w:(1 1 8 5 6 1;1 1 12 9 6 1); c:16 ov\R (6 4)#20_d; d:(if v2:0<d 4`88+sum c*w 0`44)_d; r:raze ({|v| @[;1;"i"$] @[(0;(#v)-c 3)_v;0;
        {|x|"z"$1000000000*946684800l-\W ov((val"V").be("il"v2);x)}]};{|x| ("z"$1000000000l*ov((val"V").be("i");raze 4#\R d);"b"$d(;4);("i"$d:(c 4;6)#x)(;5))};,"c"$;,:;,"b"$;,"b"$;,"c"$)
        @\M (0,sums (c*w v2)3 4 5 2 1 0)_d; r(4):''$(s?\L "\000")#\M s:r.4 _\L r.5; 'tm,shift,dst,tz,std,utc'!(,r 0),(r 2 3 4 7 8)@\L r 1};
    sys:{|x|'' vo 'sys' eff (*x;1_x:T(" ";0;1b) vo x)};scnt:{|x|16 INT x};ser:{|x|17 INT (x;0x00)};xser:{|x y|17 INT (x;if"x"is y`y`+\F ('async,req,repl,ide'!0x01020008)y)};deser:{|x|18 INT x};xdeser:{|x|19 INT x};user:{||''$*'sysparam'eff"u"};
    pget:{|p|'sysparam'eff A.sysparams p};pset:{|p v|'sysparam'eff (A.sysparams p;v)};ip:{|x|if x~"localhost"`2130706433l`'net' eff (0x01;if":"in x`x`x,":8000")};
    listen:{|n p f|'#m' ('listen';n;p;f)};host:{|x|'net' eff (0x00;if"il"is x`x`256 ov "I"$"." vo x)};
]}();
C:r['.n':'connect';ch:"0";pid:0;h:"localhost";n:"";pwd:"";p:-1;d:"";'.c':{|r d| exc"bad port"iff 1>p:d.p; d.d:"vek ",V.host 2130706433l iff 0=#d.d; d.n:str V.user()iff 0=#d.n; d};'.p':'ch,pwd,pid';'.r':'h,n,p,d';
    '.f':![open:{|r| ret r iff val r.ch; ip:V.ip r.h; r.ch:c:'net' eff (0x03;ip;r.p;r.n;r.pwd;r.d;0x04); r.pid:pid:!c; {|v| 1b^recv(time.z;1D;{|m| ret none iff _'connect'~*m; if _pid=m 1`1b`'err'~m 2`exc m 3`0x0~m 2`exc "access"`0b})}\Wh 1b;r};
    pmsg:{|r m| if _('connect';r.pid)~2#m`none`'err'~m 2`exc m 3`'stop'~m 2`exc"closed"`1b};chs:{|r| if"C"is v:{|| 0b^recv(r.pid;0;r.pmsg)}\Wh 1b; if val r.ch`1b`exc"closed"}; // flush all msgs
    idx:{|r v| r.chs; send r.ch`('msg';V.xser (mid:time.z;v)`'req'); p:r.pid; v:(); {||1b^recv(p;1D;{|m| if 1b~r.pmsg m`mid<>*v:*V.xdeser\Try[{|e|r.ch send 'stop';exc "bad msg"}]m 3`none})}\Wh 1b;v 1}]];

'\X' set {|p f| p:(if "!"is p`p`()!()),val T("benv"); exc "dangling globals: ","," ov str g iff #g:(V.globals p`f)1; {|f p a| 'spawn' eff (f,a;p;0b;0)}(,f;p)list@};
'\XX' set {|p f| p:if"!"is p`p,![]`![]; p.e:(if'e'in!p`p.e`![]),val T("benv"); exc "dangling globals: ","," ov str g iff #g:(V.globals p.e`f)1; {|f p a| 'spawn' eff (,,@f,a),p}(f;(![ch:0b;qlen:0],p)'e,ch,qlen')list@};
'\Xr' set {|p f| {|p f a| {|f a| send '#p'`('result';f\ETry[id] . a)}(f)\X[p] a; recv(0W;{|e| if'result'~*e`e.1`none})}(p;f)list@};
'\P' set {|p f l| {|f a| send '#p'`('result';f\ETry[id] a)}(f)\X[p]\M (),l; 'v'!{|| if (cexc is r)|rexc is r:recv(0W;{|e| if'result'~*e`e.1`none})`exc r`r}\M ..#l};
'\PO' set {|p f l| {|f i a| send '#p'`('result';i;f\ETry[id] a)}(f)\X[p]\Mi (),l; rs:(#l)#id; {|| if (cexc is r)|rexc is r:recv(0W;{|e| if'result'~*e`rs(e.1):e.2`none})`exc r`r}\Do[#l]0;'v'!rs};
'\TO' set {|tf f| tf {|t i| sleep t; send '#p'`('timeout';i)}\X i:time.z; seff('?timeout';{|i m| if i~m`exc"timeout"`'?timeout' eff m}i;f)};

prefs:{|p v| '.pref'set (val'.pref'),(,p)!,v}; prefg:{|p| (val'.pref')p};

fnf:'a,x,l,c,g,s,i,t,p,n,ga'; // must be at len-2 position
'' set id; // marks the end of the static part


// writable, pref must be first - referenced by idx for parse
'.pref'set !['\t':{|x| m:0;n:1;if":"=*x`{exc"iter not int"iff null "I"$n:1_(m:x?" ")#x;x:m _x};r:xparse fmt"}!time.t-last ({||!x!;}\\Do[!n!]();time.t)"; (r.0;0|r.1+m-16)}; '\?':P.pmatch; '\:':P.pmatcha; '\recv':P.pmatchr; '[]':P.pmatchf;
    '\g':{|s| exc"invalid name"iff _all'name'=*e:lex s; (("g";''$e'value');0)}; '\l':{|s| .[prefg('\g')s;0 0;:;"l"]}; '\L':{|s| .[prefg('\g')s;0 0;:;"L"]}; '\f':P.mkf; '\\':{|s| (('exit';0^"I"$s);0)};
    '\own':{|s| x:xparse s; exc"own:fmt"iff _"s"is*x.0; ((:;(":";x 0;::);x 0);(0;(0;x 1;0);x 1))};'voml':{|s| (V.voml s;0)}];
H:{|| tm:{|m| if ('timeout'~*m)&&"0"is m`{'?timeout'eff last m;1}`none}; sig:{|m| if'sig'~*m`'sig' eff last m`none};
    add:{|r v| r.h(v 0):v 1}; run:{|r v| w:none; v; {|a h| w:h v iff"_"is w}\F[0] val r.h; w};
    r['.n':'defh';h:![timeout:tm;signal:sig];'.f':![run];'.s':![add]]!![]}();
params:r[debug:0b;tz:();'.s':![settz:{|r z| d:V.tzinfo (("/usr/share/zoneinfo/",;id)"/"=*z)z; d:d('tm,shift')@\M 1 0+d.tm bin time.z; r.tz:d,if"/"=*z`''`''$z}]]!![];