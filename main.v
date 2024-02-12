stdin:{|c| 
    repl\X 0;
    'stdin' set c;
    '#m' ('reg';'stdin';val'#s');
    {|| recv[is req => {e.ack; out (),if"Cc"is m:e.msg`m`">"; e.repl 'stdin' eff ref stdin}; ern fmt"unexpected stdin msg: {e}"]; self()}()
};
repl:{|| '#m' ('reg';'repl';val'#s'); {|| out stringn {|| val'#p'ask ()}\Try[{|e| (mkexc e).show;}]\Err[{|e| (mkexc ![e;st:1b]).show;}](); self()}()};
main:{|c|
    stdin\X c; c:0;
    'pmap' set ![];
    {||recv[
        r:is req => ?[e.msg;
            ('ch';nm) => r.repl if (val ch)&&"#"is ch:pmap nm`ch`mkexc "unavailable";
            ('reg';nm:is"s";ch:is"#") => if (val c)&&"#"is c:pmap nm:''$"#",str nm`e.exc "exists"`{pmap(nm):ch; r.repl 1b};
            _ => ern fmt"main: unsupported request: {e}"
        ];
        ('exit';i) => 4 INT i;
        'abort' => if val@c && "#"is c:pmap'#repl' `c send ('sig';'break')`4 INT i;
        _ => ern fmt"main: unsupported msg: {e}";
    ]; self()}();
};

pt:r[e:none;p:0;dp:0;'.f':![mkpt:{|r e| ret e iff pt is e; pt[e;p;dp:p:r.dp]};mv:{|r i| r.dp:r.dp+i; r.p:r.p+i; r};pset:{|r i| r.dp:i; r};l:{|r| #r.e};app:{|r e| e:r.mkpt e; pt[e:(r.e;e.e);p:list(r.p;e.p);dp:r.dp]};
  apn:{|r e| e:r.mkpt e; pt[e:list(r.e),'0'!e.e;p:list(r.p),e.p;dp:r.dp]}; blk:{|r e| e:r.mkpt e; if ()~r.p`e.pset r.dp`(";"=*x)&"0"is x:r.e`r.add e`pt[e:(";";r.e;e.e);p:list(p;r.p;e.p);dp:p:r.dp]};
  add:{|r e| e:r.mkpt e; if "_"is r.e`e`pt[e:(if "a"is r.p`,r.e`r.e),,e.e;p:r.p,list(e.p);dp:r.dp]}; cnd:{|r e1 e2| (r.add e1).add e2}; fn:{|r a mx| pt[e:("f";(),a;r.e);p:(p;mx;r.p);dp:p:r.dp]}; adn:{|r l| {|r a| r.add a}\F[r] l};
  ]];


pparse:{|s r|
  i:0; st:(); t:val lex s; pself:self; cmpv:{|x| if t(1;i)~(),x`pt[e:{i:i+1;x};p;dp:p:t.2 i]`0b}; cmpt:{|x| if x~t.0 i`pt!t({i:i+1;1 2 2};i)`x~'expr'`pt[e:'v';p:j].add P.expr({i:#t.0;j};(j:t.2 i)_s)`0b};
  app:{|d r| (:)i:i+1`pt[e:d;p:t.2 i].adn {|a| pself t`r}\M P.pspl(t`d)}; {|c r1 r2| t2:if ^i:*where (c~\R t.1,\M next t.1)&P.pflt t`,t`t T(0,i+2;i,#t.0); if 1=#t2`pself(t2 0;r1)`2=#t2`pt[e:c;p:t.2.0].adn t2 pself\M r2};
  RULES
  r:(val ''$"&",str r)();
  if 0b~r`P.pexc(t.2 (-1+#t.0)&i;"failed")`i=#t.0`r`P.pexc(t.2 i;"unconsumed input")
};
a:();
fext:{|s| esr(;"(*)";{|s| a:a,,por fext -1 _1_s; (str -1+#a),"l"}) xesr("\"'{[";s;"{*}";{|s| a:a,,-1 _1_s; (str -1+#a),"h"})};
prules:{|s| r:prule\M*ltrim";"esp fext s; val ssr(str pparse;"RULES";fmt"\\L {};\n{''ov r(;1)}"`" "ov r(;0))};
prule:{|s| n:1+s?":"; ((n-1)#s;"  ",(n#s),(por n _s),";")};
por:{|s| if 1=#r:*"|"esp s`pand s`{|s|fmt"}!{|| \\L v p; p:i;\n!s!\n    i:p; 0b}"}'' ov{|f| fmt"    if 0b~v:{f}()`i:p`ret v;"}\M pand\M r};
pand:{|s| tn:sums "sSCl"is\R tv:pvalp\M. t:2#val lex s; vv:"v",\R str 1+..max tn;fmt"}?{|| ??; ???? }"`"\\L "," "ov vv`"; "ov pexp\M. (t,(tv;tn)) _\R\W where diff sums _t(1;;0)in"*+?"`(if"h0"is last tv`""`fmt("; {} ({})";if 1<#vv`"pt[].adn"`"";";"ov vv))};
pexp:{|c v pv i| n:"v",str i 0; r:pval pv 0; ret if"h0"is pv 0`r`fmt"ret 0b iff 0b~{n}:{r}" iff 1=#v; r:if "?"=f:*v.1`fmt"}??n?:{|| \\L p x; if 0b~x:?r?`{i:p;pt[]}`x}"`
    fmt"}!!n!:{|v| \\L p x; p:i; if 0b~x:!r!`{i:p;v}`self v.add x} pt[dp:t.2 i]"; r:r,fmt"; ret 0b iff {n}.l=0" iff f="+"; r};
pval:{|w| ret (a w),if "l"is w`"()"`"" iff "hil"is w; ret *w iff "C"is *w; if "s"is w`fmt"{str w}()"`"S"is w`fmt"cmpt('{_str*w}')"`"C"is w`fmt"cmpv(\"{w}\")"`exc"unexp"};
pvalp:{|c v| if 'num'=c`(if"i"is n:val v`,(fmt"({})"`";"ov"v",\R v)`n)`c in'str,sym'`-1 _1_v`*@v in"?+*"`*v`,:\Do[all v in A.A]''$v};

// patts: "{app ';'`patt}"
// patt: "{app2 \"=>\"`vexpr`(por;vexpr)}"
// por: "'..' | (NAME ':' 1)? pand"
// pattsl: "{app ';'`por}"
// pand: pbase ('&' vexpr)?
// pbase: (STR | SYM | NUM) {v1.e:('c';parse\\Try[P.pexc t.2 i-1] v1.e);v1} | ('in'|'is'|'~') EXPR {pt[e:('f';val (),v1.e;v2.e);p:(v1.p;v1.p;v2.p)]} | NAME? '(' pattsl ')' {pt[e:('l';if\"_\"is v1:v1.e`\"0\"`v1;v3.e);p:(v2.p;v1.p;v3.p)]} |
//  NAME '[' pattsi ']' {pt[e:('r';''$v1.e;v3.e);p:(v1.p;v1.p;v3.p)]} | '!' '[' pattsi ']' {pt[e:('d';v3.e);p:(v1.p;v3.p)]} | '@' NAME {pt[e:('n';''$v2.e);p:2#v2.p]} | NAME {v1.e:('a';''$v1.e);v1} | '_' {v1.e:'_';v1}

f:prules "patts: '*; patt'; patt: '!=> por vexpr'; por: (NAME ':')? '*| pand'; pattsi: '*; por'; pand: '!& pbase vexpr'; vexpr: EXPR; pbase: (STR | SYM | NUM) {v1.e:('c';parse\\Try[P.pexc t.2 i-1]v1.e);v1} | ('in'|'is'|'~') EXPR {pt[e:('f';val (),v1.e;v2.e);p:(v1.p;v1.p;v2.p)]} | 
NAME? '(' pattsi ')' {pt[e:('l';if\"_\"is v1:v1.e`\"0\"`v1;v3.e);p:(v2.p;v1.p;v3.p)]} | NAME '[' pattsi ']' {pt[e:('r';''$v1.e;v3.e);p:(v1.p;v1.p;v3.p)]} | '!' '[' pattsi ']' {pt[e:('d';v3.e);p:(v1.p;v3.p)]} | '@' NAME {pt[e:('n';''$v2.e);p:2#v2.p]} | NAME {v1.e:('a';''$v1.e);v1} | '_' {v1.e:'_';v1}";