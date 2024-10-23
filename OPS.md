* auto-gen TOC:
{:toc}

# Basic functions

tags: function : basic operators and functions

## Properties

tags: property : properties of operators and functions

### Legend

tags: legend : shortcuts for types

Legend:
* A - all
* Ax - atom, type x
* Vx - vector, type x
* L - generic list
* T - tuple
* R - record

### Atomic in x

tags: atomic, atomicity : atomicity in one argument

The function is atomic in one argument.
```Rust
f Ax // function specific
f Vx ~ f\M Vx // map f on Vx, the return type depends on the function
f L ~ f\M L // map f on L recursively, return L
f T ~ f\M T // map f on T recursively, return T
f R // call the overloaded generic function or try to cast to T
```
When `f` is applied to a list it will ALWAYS return a list even if it can be collapsed into a vector.

Fns: abs acos asin atan ceil cos exp floor ln neg not null sin sqrt string tan til

### Atomic in x,y

tags: atomic, atomicity : atomicity in 2 arguments

The function is atomic in both arguments:
```Rust
Ax f Ay // function specific
VxLT f Ay ~ VxLT f\L Ay // map on the left arg
Ax f VxLT ~ Ax f\R VxLT // map on the right arg
VxL f VyL ~ VxL f\M VyL // map on both args
VxL f T ~ VxL f\R T // list vs tuple: apply the list to all tuple elements, return T
T f VxL ~ T f\L VxL // apply the list to all tuple elements, return T
T f T ~ T f\M T // map
R f _ // call the overloaded generic function or try to cast R to T
R f R // like above but try to cast both args
```

Fns: + - * / & | = > < <> >= <= div %

### Preserves null (in x)

tags: null : preservation of nulls

The function always returns null if one of its arguments is null.

Fns: + - * / abs acos asin atan ceiling cos div exp floor ln neg sin sqrt tan

### Numerical

tags: numerical : function works with numbers

The function is defined for numerical types only (including temporal). It may return other types as is.

Fns: + - * / % abs acos asin atan ceiling cos div exp floor ln neg not sin sqrt tan

### Float

tags: float : function works with floats

The function always returns a float value (an atomic function returns a float for an atom).

Fns: acos asin atan cos exp ln sin sqrt tan

### Boolean

tags: bool, boolean : function returns a bool

The function always returns a boolean (an atomic function returns a boolean for an atom).

Fns: = > < <> >= <= ~ not null

### String

The function operates with strings.

Fns: ltrim rtrim str string stringn trim lower upper show ss ssr esr ess

### List

The function operates on the structure that contains values not the values themselves.

Fns: distinct hll _ #

### Type symmetrical

For a binary function the result type doesn't depend on the order of arg types: `type f(x,y) ~ type f(y,x)`.

fns: + - * / & | = > < <> >= <= ~

### Reuse

An argument of type Vx can be reused for the result.
```Rust
1+til 100 // here the vec with til 100 can be used to store the result of 1+
```

The argument will be reused if there is only 1 reference to it and its size is the same as the size of the result.
```Rust
1.1+til 100l // ok, long and double have the same size
1l+til 100 // not ok, long and int have a different size
```

Fns: abs + - * / & | = > < <> >= <= acos asin atan ceiling cos div exp floor log neg not null sin sqrt tan

### Aggregation

The function aggregates a list into a value.
```
f LVxAx ~ f_bin\F f_pre LVxAx
where
  f_pre is an optional unary atomic fn that adjusts the arg ('b'$ for all)
  f_bin does the aggregation (& for all)
f T ~ f\M T
f R // either a generic fn or cast to T
```

For `Ax` f_bin will not be called.

For some functions f_bin acts differently on `Vx` vs `L` - it ignores null values (sum vs +).

Fns: all any max min sum

### Lazy

The function will not be executed for Vx values. It will be saved into a thunk and if another lazy function is called with this thunk it will be added to the thunk as well. On assign or when a non-lazy function is called with the thunk it will be executed. The thunk is ALWAYS a vector of a fixed size - you can combine only atoms and vecs of the same size. Also you can use lazy aggregation functions, they will produce a value with type T1 (aggregated thunk). The lazy functions accept T1 values and return T1 values back:
```Rust
a*b+c // b+c will be put into a thunk, a* will be added and then the thunk will be executed
all a+b // all will produce a T1 value
wavg(a,b) ~ (avg a*b)*ncnt a // the reason why agg functions do not execute thunks - to combine the results of several agg functions
```

Why do we use thunks? During execution the vectors inside (they all have the same length) will be splitted into chunks and the expression will be calculated separately for each of them and in parallel. This can potentially significantly reduce the load on the memory when the same vector is used several times and speed up calculations. Also the thunk can detect if some intermediate vector will not be used later and remap chunks to only a small part of it (~ number of CPUs chunks), this will further reduce the memory usage:
```Rust
// consider this expression
sum b+x*(x+a)
// if x is a vec and a and b are atoms:
x+a->v1, x*v1->v1, b+v1->v1, sum v1 -> res
// or 5 vector reads and 3 vector saves, thunk will execute the exp as follows:
for c in (split x.length in chunks): x[c]+a->v1[map[c]], x[c]*v1[map[c]]->v1[map[c]], b+v1[map[c]]->v1[map[c]], avg v1[map[c]] -> sum_c; later sum sum_c -> result
// map[c] here will map chunks into [CPU_ID*chuck_length..CPU_ID*(chunk_length+1)] chunks
// as the result we have only 1 vec read and 0 vec saves: the potential speed up of up to 8 times, because such calcs are usually restricted by the memory speed
// even without sum and when a and b are vecs we would have 3 reads and 1 save vs 6 reads and 3 saves.
```

This logic is used only for vecs longer than CHUNK_SIZE which is 2^15 at the moment. This size need to be such that several chunks would fit into L2 cache.

Fns: + - * / & | = > < <> >= <= abs acos all any asin atan ceiling cos div exp floor log max min neg not null sin sqrt sum tan til

### Early return

The function can return before it processes all input. For example `all` function can exit when it encounters `0b` in Vb.

Fns: all any ~(eqv)

### Monoidal

The function forms a monoid: it is associative and respects the zero element. There is one problem: zero elements and functions are detached. `R` wrapping can be used to change the default choice of zero.

This property means that an aggregation function based on such function can be executed in parallel.

Fns: + & | *

### Idempotent

```
f f x ~ f x, for unary
x f x ~ x, for binary
```

Fns: & | abs ceiling distinct floor

### Message

Related to message passing.

Fns: recv peek flush send ssend

## Unary operators

### _ (floor, lower, not)

Atomic, lazy.

Type map: ef -> il, bxhiltdz -> b, cs -> cs

Performs various useful operations depending on the argument type.

For real/float type does `floor`:
```Rust
1l~_ 1.2
```

For strings/chars does `lower`:
```Rust
"abc"~_"AbC"
```

For numbers/booleans does `not`:
```Rust
010b~_101b
101b~_0 10 0
```

### : (id)

Do not confuse with assign. Returns its argument as is.
```Rust
1 ~ :: 1
-1 ~ -:1 // do not confuse with : suffix
```

### ! (key), key

Deconstruct an object. Generally returns the first argument of `!` construct function (`val` returns the second argument).
* `key dict` - dictionary keys.
* `key record` - public field names (not rid because rid must be a secret). See also binary !.
* `key recordID` - public field names.
* `key atom/vec/tuple/list` - type as a symbol that can be used with `$` or `!`.
* `key user_fn` - arguments.
* `key channel` - pid of the process.

### - (neg), neg

Atomic, numerical, reuse, lazy, preserves null.

Type map: bxc -> i, hileftdz -> hileftdz.

Negates a value.
```Rust
-x
10 ~ neg -10
```

### ^ (null), null

Atomic, boolean, reuse, lazy.

Type map: bxhileftdzsc -> b.

For null returns 1b, otherwise 0b.
```Rust
^x
0b ~ null -10
```

### .. (til), til

Atomic, lazy.

Type map: bxhi -> i, l -> l.

'l' is not used for all return values to reduce the size of index vectors that in most cases do not require 'l' type.

Returns a list of numbers 0..n-1 for '..n'. See also the binary version `range`: `a..b`.
```Rust
..x
..100
til 100 // alternative instead of ..:
```
> `var ..x` is `(..)(var;x)` if `var` is not an unary/binary system function. The same is true for `(expr)..x` and other data-like left values. Alternatives:
```Rust
var ..:x // unary form of ..
var (..x)
var til x;
```

> In the assign it means splice index:
```Rust
a(e ..):val; // is interpreted as a(e 0;e 1;..):val
```

### # (count), cnt

Type: A -> il.

Returns the number of elements in a vector/list/dictionary/tuple. Otherwise returns 1. Returns int if the number of elements is less than int max, otherwise returns long.
```Rust
3~cnt 1 2 3
3~#1 2 3
```

### *, first

Returns the first element of a list. For dictionary - the first element of its value. Returns the argument untouched otherwise.
```Rust
1 ~ *1 2 3
10 ~ first ![a:10;b:20]
```

### , (enlist)

Make a one element list/vector from the argument:
```Rust
,10 // vector
,"aa" // list
,,10 // list with a vector
ulist(10) // more verbose form
```
See also `list`, `ulist`, `tuple`.

### @ (type), type

Returns the generic type of the argument as a char. For more details use `xtype`. Also see `is`.
```Rust
type x;
"I" ~ @: 1 2 3
"I"~type 1 2 3
```
Return values: one of bxchilfedtzs for atoms, one of BXCHILFEDTZS for vectors, 0(generic list), @(function including built-ins), u(tuple), !(dictionary),
rR(record and rec definition), &(reference), #(channel), _(none), j(atomic), o(box).

`@` has the syntactic use so `:` suffix is required: `@:`:
```Rust
f@1+2 // @ here is 'glue'
f@:1+2 // type
```

## Binary operators

### : (right)

Do not confuse with assign. Returns its right argument.
```
2~(:)(1;2)
```
It can be used in the generic amend:
```
@[x;idx;:;val]
```

### + (add)

Atomic, numerical, preserves null, type symmetrical, reuse, lazy, monoidal(0).

Type map:
```
 |bxhileftdzcs
--------------
b|iiiileftdz  
x|ixiileftdz  
h|iihileftdz  
i|iiiileftdz  
l|llllleftdz  
e|eeeeeefeee  
f|ffffffffff  
t|ttttteftzz  
d|dddddefz    
z|zzzzzefz z  
c|           
s|            
```

Adds two values.
```
x + y
2 ~ 1 + 1
0N ~ 1 + 0N // preserves null
```

### & (and)

Atomic, numerical, reuse, lazy, type symmetrical, monoidal(0W), idempotent.

Type map:
```
 |bxhileftdzcs
______________
b|bxhileftdzc
x|xxhileftdzc
h|hhhileftdzc
i|iiiileftdzc
l|llllleftdzc
e|eeeeeefeeee
f|fffffffffff
t|ttttteft t
d|dddddef dd
z|zzzzzeftdz
c|cccccef   c
s|           s
```

Returns the max of x and y. In the case of bool it is "and". The nulls are not preserved per se but because they represent the smallest value the function preserves them de facto.
```
x & y
2 ~ 10 & 2
0N ~ 1 & 0N
```

### $ (cast)

Atomic, reuse, lazy.

Type map: the result type is defined by the first argument.

Casts a value to a type, parses a string into a type. General definition:
```
"t"$value, 't'$value, 'typename'$value, "typename"$value - binary cast where t is in "bxchileftdzs", typename in ("bool","byte","char","short","int","long","real","float","time","date","dt","symbol")
"T"$value, 'T'$str_value - cast from a string/symbol, T is "BXCHILEFTDZS"
''$value - shortcut for "S"$value
'*'$val or "*"$val // no-op cast
```

Cast transforms only basic types. For more complex casts use `!` (construct).

For vectors/atoms symbol indexing is treated as a cast:
```
(..10).time ~ 'time'$..10
obj.f ~ 'f'$obj
"10.1".F ~ 10.1
```

Date, datetime and time have special casts related to date/time components. For date and datetime:
```
v.yy // year as int
v.mm // month as int
v.dd // day as int
v.year // round up to year
v.month // round up to month
v.day // round up to day
```
For time, datetime:
```
v.hh // hour as int
v.mn // minute as int
v.ss // second as int
v.hour // round up to hour
v.minute // round up to minute
v.second // round up to second
```
Or:
```
'hh'$time.t // etc
```

### > (comparison), <, >=, <=

Atomic, boolean, reuse, lazy, type symmerical.

Types: (s,s) -> b, for ty1,ty2 in bxchileftdz, except t,d and d,t pairs: (ty1,ty2) -> b

There is only one real function: >, all others are defined in terms of it:
```
x < y ~ y > x
x >= y ~ not y > x
x <= y ~ not x > y
```
Datetime vs time and date is compared via a cast to time or date.

### , (concatenate)

List.

Concatenates two objects. If both args are atoms/vectors:
```
Ax,Ax => Vx // same type: vector
Ax,Ay -> L  // diff types: list
Ax,Vx -> Vx
Ax,Vy -> L
Vx,Ax -> Vx
Vx,Ay -> L
```
Empty list has a special meaning:
```
(),Ax -> Vx // enlist
(),Vx -> Vx // id
Ax,() -> L  // make a list
Vx,() -> L  // make a list
```
List vs atom or vector produces a list.

Dictionaries are treated as `list(dict)` values except:
```
dict,dict -> dict // if both args are dicts and have the same key type it is a merge where `y` has precedence.
                  // values are treated according to append rules: converted to list if needed.
dict,() // make values a list TODO: really?
(),dict // nothing
```

Tuples:
```
T1,T2 -> T3 where T3.i = T1.i,T2,i // or length exception
T1,val -> T2 where T2.i = T1.i,val
val,T1 -> T2 where T2.i = val,T1.i
```

### ! (construct)

Construct a composite value:
```Rust
keys!values  // create a dictionary
![a:10;b:20] // closely related special syntax for sym dicts
record!dict  // create a record from a dictionary
record!list  // create a record from a list/vector
'u'!list     // create a tuple from a list/vector
'0'!tuple    // create a list from a tuple/vector
'v'!list/tuple // convert to a vector if possible
// inside record function
'0'!record; 'u'!record; '!'!record // return a list/tuple/dictionary of ALL record values
```

### / (division)

Atomic, numerical, float, respects null, reuse, lazy.

Type map: bxhileftdz, the result is always f (when e type is involved it is e).

Divides two values. If y is 0 the result is 0wf.
```
x / y
5.0 ~ 10 / 2
0w ~ 1 / 0
0n ~ 0N / 10
```

### = (equality), <> (inequality)

Atomic, boolean, reuse, lazy, type symmetrical.

Type: bxhileftdzcs, s only with s, t can't be compared with d, the result is always b.

Compares two values. For floats the equality tolerance is used. Datetime is compared with date/time via a cast to date/time.
```
x = y
x <> y
0b ~ 10 = 1
0b ~ 0N = 1 // nulls are treated as smallest possible values
1b ~ 0N = 0n
```

Inequality is `not x=y`.

### ~ (equivalence)

Early exit, type symmetrical, boolean.

Type: any types, the result is always b.

Compares any two values.
```
x ~ y
0b ~ 1 2 3 ~ 10
```

### ^ (fill)

Atomic, reuse, lazy.

Type map:
```
 |bxhileftdzcs
______________
b|bxhileftdzc
x|xxhileftdzc
h|hhhileftdzh
i|iiiileftdzi
l|llllllfllzl
e|eeeileftdze
f|fffflffffzf
t|tttileftdzt
d|dddileftdzd
z|zzzzlefzzzz
c|bxhileftdzc
s|           s
```

Fill fills nulls in the second argument using value(s) in the first argument.

Fill needs arguments of the same type so if they are different it either converts one of them to the bigger type or if both have the same size converts the first arg to the type of the second arg.
```
a^b
10~10^0N;
11~10^11;
1l~1l^0N; // convert to bigger
1e~1^0ne; // convert to the second arg
```

### * (multiplication)

Atomic, numerical, preserves null, type symmetrical, reuse, lazy, monoidal(1).

Type map:
```
 |bxhileftdzcs
______________
b|iiiileftiz
x|ixiileftiz
h|iihileftiz
i|iiiileftiz
l|llllleftlz
e|eeeeeefeee
f|ffffffffff
t|tttttef
d|iiiilef
z|zzzzzef
c|
s|
```

Multiplies two values.
```
x * y
2 ~ 1 * 2
0N ~ 1 * 0N // preserves null
```

### | (or)

Atomic, numerical, reuse, lazy, monoidal(0N or 0), idempotent.

Type map:
```
 |bxhileftdzcs
______________
b|bxhileftdzc
x|xxhileftdzc
h|hhhileftdzc
i|iiiileftdzc
l|llllleftdzc
e|eeeeeefeeee
f|fffffffffff
t|ttttteft t
d|dddddef dd
z|zzzzzeftdz
c|cccccef   c
s|           s
```

Returns the min of x and y. In the case of bool it is "or". The nulls are not preserved.
```
x | y
10 ~ 10 | 2
1 ~ 1 | 0N
```

### ? (rand)

Rand has several forms:
```
num?... where num is 'bxhil'
   ?list/vector - randomly choose num elements from the list.
   ?val where val is 'bxileftdz', val > 0 - randomly choose num elements in the range [0..val), the return type is the val's type.
   ?"c" - randomly choose num elements within a..z.
   ?val, where val=0 - randomly choose num elements from the val's domain, 'bcs' are not supported, for 'ef' it is ~ "num?1f or 1e".
-num?val, where val>=num, val is 'il' - randomly choose unique numbers within [0;val) interval. val=0 is not supported.
-num?list/vector, where len(list)>=num, acts like "list -num?cnt list", choose unique elements from the list.
0N?list or val, where val>0, type(val) in 'il'. Shuffle the list or return a permutation of '.. val'. Type of the null is ignored.
```

If y is a list then the result is a new list created from y. If y is Ax and the fn is defined then the result's type is Vx.

### .. (range)

Atomic, numerical, lazy.

Type map: bxhil -> il. l is returned if one of arguments is l.

Range of indecies.
```
x .. y
3 4 5 ~ 3..6
```

It is defined as `x+(..y-x)`.

### - (subtract)

Atomic, numerical, preserves null, type symmetrical, reuse, lazy.

Type map:
```
 |bxhileftdzcs
______________
b|iiiileft
x|iiiileft
h|iihileft
i|iiiileft
l|llllleft
e|eeeeeefeee
f|ffffffffff
t|ttttteft
d|dddddef
z|zzzzzefz z
c|
s|
```

Subtracts two values.
```
x - y
-1 ~ 1 - 2
0N ~ 1 - 0N // preserves null
```

### # (take)

Take has several forms:
```
num#list/vector - num >=0. Take num elements from the list, if len(list) < num, start from the begining.
-num#list/vector - the same as num#list but the initial offset is num from the end (not 0).
num#Ax - any sign, return a list/vector with x repeated num times.
T(num;offset)#list/vector - num >=0, offset can be negative. start at offset.
num1 num2 ..#list/vector or atom - create an n-dimentional matrix.
Vb#list/vector - len(Vb) = len(list), returns elements marked with 1b
```
The return type is a list/vector, underlying type is derived from the second argument.

See also `wtake`.

### @ (apply)

Applies `x` to `y`:
```Rust
-1 ~ (@)(neg;1)
-1 2 ~ (neg;abs)@\M (1;-2) // usefull with suffixes
```

### % (modulus)

Returns the remainder of `x/y`. It is defined as `x-y*x div y`.

### _ (drop)

Removes elements from a list/vector:
```Rust
num _ list // remove elements 0..num from list
-num _ list // remove num elements from the end of the list
n1 n2 .. nk _ list // cut the list at ni, return a list of cuts, 0..n1 is dropped
Vb _ list // len(Vb) = len(list), remove from the list elements marked with 1b
sym/symlist _ dict // remove keys from the dict
num/-num _ dict // drop first/last num keys from the dict
n1 n2 .. nk _ dict // cut the dict into a list of dicts
```

## Named functions

### abs

Atomic, numerical, reuse, lazy, preserves null, idempotent.

Type map: hileftz -> hileftz. Other values are returned as is.

Returns the absolute value:
```
abs x
10 ~ abs -10
```

### all

Aggregate(pre: 'b'$, agg: &), lazy, early return.

Type map: bxciltf -> b

It treats nulls as 1b.

Returns 1b if all aggregated values are not 0, returns 0b otherwise.
```
all x
1b ~ all 10 0N
01b ~ all (0 10;0x1010) // acts as fold & on lists
```

### any

Aggregate(pre: 'b'$, agg: |), lazy, early return.

Type map: bxciltf -> b

It treats nulls as 1b.

Returns 0b if all aggregated values are 0, returns 1b otherwise.
```
any x
1b ~ any 0 10
01b ~ any (0 10;0x0010) // acts as fold | on lists
```

### avg

Average of a list/vector. In vectors nulls are ignored.
```Rust
>avg 1 2 3 4
2.5f
```

### avgs

Rolling averages. Nulls are ignored.
```Rust
>avgs 1 2 3 4        
1 1.5 2 2.5f
```

### ceil (ceiling)

Atomic, numerical, preserves null, reuse, lazy, idempotent.

Type map: doesn't do anything for any type except ef. For ef returns il.

Rounds a float number up.
```
ceil x
11 ~ ceil 10.1
```

### deltas

Type: VxL -> VxL, * -> *

Returns a list where r(i) equals v(i)-v(i-1), the first item is always v(0).
```
2 0 1 1 0~deltas 2 2 3 4 4
0 0 1 1 0~-\Pr[2] 2 2 3 4 4 // Use \Pr with a param to set the v(-1)
```

### diff

Type: VxL -> Vb, * -> *

Returns a boolean list where 1 means that v(i)<>v(i-1), the first item is always 1b.
```
10110b~diff 2 2 3 4 4
00110b~not~\Pr[2] 2 2 3 4 4 // Use \Pr with a param to set the v(-1)
```

### dist (distinct)

List, idempotent.

Type map: bxcitlfs -> bxcitlfs

Returns unique elements of a list. The order is preserved.
```
dist x
dist Ax -> Ax // atoms are returned as is
1 2 ~ distinct 1 1 2 2
```

Distinct employs 3 strategies: equality check for small vecs (up to 100 elements, O(n^2)), bit map for vecs with the element range fitting into a bitmap of similar size, hashmap.

### div

Atomic, numerical, preserves null, reuse, lazy.

Type map:
```
 |bxhileftdzcs
______________
b|iihilefiil
x|iihilefiil
h|hhhilefiil
i|iiiilefiil
l|llllleflll
e|eeeeeefeee
f|ffffffffff
t|iiiilefiil
d|iiiilefiil
z|llllleflll
c|
s|
```

Divides two values using the integer division. If y is 0 the result is null. Floats are divided as if they are ints (round is called).
```
x div y
3~10 div 3
```

### enc

Encode an expression from a parse tree:
```
enc(parse_tree;positions;text)
enc((+;1;2);0;"sum of 1 and 2")
```
`enc` always returns a function. If the top expression is a function then this fn is returned otherwise the expression gets wrapped into: `("f";,'';expr)`.

The positions must conform with the expressions (you can provide one number for a branch though). The tree must be correct. `enc` allows some liberty not possible with
the normal expressions - you can use any symbol as a name for example.

You can provide a text that matches the positions or you can provide just a description of the function. The positions and text are used for the error reporting.

Functions produced by `enc` (and syntactic transformers/macros) will be shown as:
```
<fn: text>
```
to underline that they are artificial and can't be parsed from its string again.

### err ern

Send to 'stderr' (effect):
```Rust
err x // as is, if x is not a string 'string' willbe called
ern x // like err but add '\n', also if x is a uniform list print each element
ern ("str1";"str2") // ~ ern\M arg
```

### eval

Evaluate a parse tree/string.
```
eval "1+2"
eval (+;1;2)
```

### except

`x` with element from `y` removed:
```Rust
,1 ~ 1 2 3 except 2 3 4
1 3 ~ 1 2 3 except 2
```

### exit

Terminate the process. Currently just terminates, more graceful termination to be added:
```Rust
exit 1
```
Exit sends `exit` msg to `main`.

### exp

Atomic, numerical, float, respects null, reuse, lazy.

Type map: bxhilftdzc -> f, e -> e.

Calculates e^x.
```
exp x
2.71 ~ exp 1
```

### floor

Atomic, numerical, respects null, reuse, lazy, idempotent.

Type map: f -> f, e -> e, other types are returned as is.

Rounds a float number down.
```
floor x
10 ~ floor 10.1
```

### flush

Flush all pending messages:
```Rust
flush(); flush 1b; // with 1b flush also prints them
```
It returns the number of purged messages.

### getenv

Type: symbol, char, string.

Get a virtual environment variable (using `#env` process). If it wasn't set manually try to get the system variable:
```Rust
getenv 'PATH'; // system variable
getenv "not_system_var"; // user defined
```
See also `sysenv`, `setenv`.

### hll (hyper log log)

List.

Type map: bxcitlfs -> i/l, l is used if the result doesn't fit into i.

Returns the approximate number of distinct elements in a vector (except boolean where this doesn't make much sense). For atoms returns 1, for Vb 2. Uses HLL++ method with precision 12 - the expected error is several percents. It is much faster than `cnt dist x`. Maybe later a custom precision could be supported via additional args for BIAS and ESTIMATE. Ahash is the hash function - hll++ requires an excelent function.
```
hll x
3 ~ hll 1000#1 2 3
```

### INT

Internal helper fns:
0. mask
1. parse
2. ref count
3. encode
4. exit
5. ns2module
6. atomic ops
7. create bmap
8. update bmap
9. unpack bmap
10. extract globals
11. voml parser
12. make grefs
13. rename module grefs
14. box a value
15. set the default timezone (times;offsets)
16. length after serialization
17. serialize
18. deserialize

### inter

Intersection of two vectors/lists:
```Rust
2 3 ~ 1 2 3 inter 2 3 4
```

### is

Type: (сCr;*) -> b,

Allows to check the args's type, returns a bool:
```Rust
type_desc is obj
1b~"I" is 1 2 3
0b~"ILH" is (1;2 3)
record_id is obj // obj is a record of this kind
// "r:name" is rec // later, less precise
```

The type description is a sequence of (type letter|type letter:details). For the type letter see `type` function. Details:
* For a vec/list length (range) can be provided: "I:10", "0:1-10', "L:-10", "L:10-". (not implemented).

Additional types: v(vector), V(vector or list), n or N (numerical atom or vector), j or J (integer type: bxhil), a - atom.

### last

Returns the last element of a list. For the dictionary - the last element of its value. Returns the argument untouched otherwise.
```Rust
3 ~ last 1 2 3
```

### lex

Returns tokens as a dictionary with keys:
* cat - token type (symbol).
* value - its value (string).
* start - its start position (int).
* end - position after its end (int).
```
>lex "1+'a'"
cat  | 'num,prim,sym'
value| (,"1";,"+";"'a'")
start| 0 1 2
end  | 1 2 5
```
It is `vek`s own lexer so it returns `vek`s tokens. See also `parse`,`xparse`.

### like

Checks if a pattern `y` matches a string `x`. Allowed patterns:
```
"txt" // ordinary chars
"*txt";"txt*";"txt*txt";"*txt*" // wild card char * can be used but only in these cases
"a?b"; // any char pattern
"a[abc]d"; "a[b0-9]c"; // choice pattern [] can be used, ranges can be used inside it.
"[*?]";"[[]";"]" // use [] to escape special chars
```

```
"a(100)" like "*(???)*"
("p1";"p2") like "p?" // like checks lists on the left
```

### ln

Atomic, numerical, float, respects null, reuse, lazy.

Type map: bxhilftdzc -> f, e -> e.

Calculates ln(x).
```
ln x
1 ~ ln 2.71
```

### lower/upper

Atomic, string.

Type map: for xcs returns xcs. Other types are returned as is.

Returns a value where lower/upper case ASCI letters are changed to the upper/lower case letters:
```
lower val;
upper val;
lower "CASE";
lower "C";
upper "case";
upper 'a';
```

### mavg

Moving average. Nulls are ignored.
```
0n 1 1 1 1 1.3333333333333333 1.5 2 1 1f~3 mavg 0N 1 0N 1 1 2 0N 0N 1 0N
```

### max

Aggregation(agg: |), lazy.

Type map: bxciltdzef -> bxciltdzef.

Returns: for Vx - max value, for Ax - Ax, for L - folds with |. If Vx contains only nulls returns or empty -0W.
```
max x
3 ~ max 1 2 3
```

### maxs

Calculates running max.
```
2 2 3~maxs 2 1 3
```
`maxs` is equivalent to `|\S`.

### mcnt

Moving count. Nulls are ignored.
```
0 1 1 2 2 3 2 1 1 1~3 mcnt 0N 1 0N 1 1 2 0N 0N 1 0N
```

### min

Aggregation(agg: &), lazy.

Type map: bxciltdzef -> bxciltdzef.

Returns: for Vx - min value, for Ax - Ax, for L - folds with &. If Vx contains only nulls or empty - 0W, otherwise nulls are ignored.
```
min x
1 ~ min 1 2 3
```

### minmax

Can be used only with numerical vectors. Returns min,max,length as longs where length is max-min+1 or 0Wl if the difference is too large.
```Rust
0 99 100l~minmax ..100
```
Use this function to check if bmap can be used with this vector.

### mins

Calculates running min.
```
1 1 0~maxs 1 2 0
```
`mins` is equivalent to `&\S`.

### mmax

Moving max.
```
0N 1 1 1 1 2 2 2 1 1~3 mmax 0N 1 0N 1 1 2 0N 0N 1 0N
```

### mmin

Moving min.
```
0N 0N 0N 0N 0N 1 0N 0N 0N 0N~3 mmin 0N 1 0N 1 1 2 0N 0N 1 0N
```

### msum

Moving sum. Nulls are ignored.
```
0 1 1 2 2 4 3 2 1 1~3 msum 0N 1 0N 1 1 2 0N 0N 1 0N
```

### ncnt

Number of elements in a vector without nulls:
```
>ncnt 1 2 0N 2 0N 3  
4
```

### ncnts

Rolling count. Nulls are ignored.
```Rust
>ncnts 1 2 0N 2 0N 3
1 2 2 3 3 4
```

### next

Shifts a vector/list to the left.
```
2 3 0N~next 1 2 3
```
The default list value is added as the last element (null, 0, empty list, etc).

See also `prev`,`xprev`.

### not

Atomic, numerical, boolean, reuse, lazy, idempotent.

Type map: bxhileftdzc -> b.

For 0 return 1b, otherwise 0b. `c` type is processed according to `"b"$` logic.
```Rust
not x
0b ~ not -10
```

### oun out

Send to 'stdout' (effect):
```Rust
out x // as is, if x is not a string 'string' will be called
oun x // like out but add '\n', also if x is a uniform list print each element
oun ("str1";"str2") // ~ oun\M arg
```

### ov (object from vector)

Joins together list/vector elements.

Join if `x` is a vector/atom and `y` is a list of vectors/atoms of the same type:
```Rust
"xx" ov ("aa";"bb") // ordinary join
'' ov ("aa";"bb") // join strings using the OS specific delimiter
10 ov (1 2;3 4) // any base type can be joined
```

Get an atom from a bit representation:
```Rust
Ax ov Vb // get atom of type x, Vb length must be compatible with Ax size
1234~1 ov 1b vo 1234
1b ov Vb // result type (XHIL) is guessed from Vb size
```

Get an atom from a hex representation:
```Rust
Ax ov Vh // get atom of type x, Vh length must be compatible with Ax size
1234~1 ov 0x0 vo 1234 // the argument is expected to be in the big endian format (as returned by vo)
0x0 ov Vh // result type (XHIL) is guessed from Vh size
"i" ov byte_vector // convert several values using the default platform endianess
"I" ov byte_vector // + swap endianess, all numerical types are supported
V.be("i") ov byte_vec // or V.le if you want a specific endianess
```

Get an int/long from an int/long list and base(s):
```Rust
1234~10 ov 10 vo 1234
678~100 10 ov 100 10 vo 123445678
```

### parse

Returns a parse tree.
```Rust
>parse "1+a"
+
1
'a'
```
See also `xparse`,`lex`.

### peek

Print all pending messages:
```Rust
peek(); peek 10; // all/only the first 10
```

See also `flush`.

### prev

Shifts a vector/list to the right.
```
0N 1 2~prev 1 2 3
```
The default list value is added as the first element (null, 0, empty list, etc).

See also `next`,`xprev`.

### recv

Wait for a message on the process's read channel and handle it:
```Rust
recv(queue_id;timeout;?[pattern=>handler;..])
recv(time.z;0;{|m| if m~'msg'`1b`none})
```
`recv` reads all available messages before processing them to prevent input queue overflow.
Your handler function must either handle the message or return `none` to indicate that the message wasn't handled. `queue_id` can be used to avoid scanning all messages on repeated recv calls.
`time.z` id can be used for unique ids. recv always scans messages from the start if id is 0.

Use the special form `recv`, it handles `none` case automatically:
```Rust
recv[
  'msg' => do_something;
  ...
]
```

### rot rotn

Rotate a list/vector.
```
1 2 3 4 0 ~ rot..5 // rotate 1 left
2 3 4 0 1 ~ 2 rotn..5 // rotate 2 left
3 4 0 1 2 ~ -2 rotn..5 // rotate 2 right
T(#x;2)#x // rotate is based on take
```

### send

Send an async message:
```Rust
'#p' send ('msg';data)
```
Returns a bool to indicate success/failure (the channel is not valid). 0b is returned because there is no way to guarantee the validity of a channel. Also 1b doesn't guarantee that the message will be received.

### setenv

Set a virtual environment variable (using `#env` process):
```Rust
'var' setenv 1 2 3; // it is not a system variable so any value is accepted
```
Setting a system environment variable is dangerous in a multithreaded process so it is not yet supported.

See also `getenv`, `sysenv`.

### show

Type map: A -> id.

Convert a value into its user friendly string representation and print it to stdout.
```
show x
```

### sqrt

Atomic, numerical, float, respects null, reuse, lazy.

Type map: bxhilftdz -> f, e -> e.

Calculates x^(1/2).
```
sqrt x
3f ~ sqrt 9
```

### ss (string search)

Searches a string for a substring. You can use one * inside the pattern. See the pattern's description in `like`. `ss` returns a pair of lists of start/end positions.
```Rust
(,1;,3) ~ "abcd" ss "[bp]c"
(1 7;5 12) ~ "a(10),b(100)" ss "(*)"
("a(10),b(100)";"d(-100)") ss "(*)" // ss also searches inside lists on the left
```

### ssend

Make a sync request:
```Rust
channel ssend message
channel message; // there is a shortcut, no need to use ssend explicitly
'#m' ('ch';'#stock.tp') // try to get a service by name
```
`ssend` creates a `req` (request) from the message, sends it to the channel and waits for `resp` message. There is no timeout but `send` checks every second if the target channel is still alive.

### ssr (search string and replace)

Searches a string for a pattern and replaces it with another string. You can use one * inside the pattern. See the pattern's description in `like`:
```
"ax,bx" ~ ssr("a(10),b(100)";"(*)";"x") // replace with a string
"a0 1,b0 1 2" ~ ssr("a(2),b(3)";"(*)";{|x| string .."I"$1_-1_x})
```


### str

Atomic, string

Type map: Ax -> Vc.

Returns a string representation of an atom.
```
str x
```

### string stringn

String

Type: A -> Vc.

Returns a string representation of an object. `stringn` returns a `show` representation. `string` returns a 1 line representation.
```
"1 2\n2"~stringn (1 2;2)
"(1 2;2)"~string (1 2;2)
```
Both functions use `params.wh` to set max width/height. They use `string_` and `stringn_` as `f (obj;params.wh)`.

### sum

Aggregation(agg: +), lazy.

Type map: bcix -> i, hltefz -> hltefz.

Returns: for Vx - sum of values, for Ax - Ax, for L - folds with +. If Vx contains only nulls or empty - 0 otherwise nulls are ignored.
```
sum x
6 ~ sum 1 2 3
```

### sums

Calculates partial sums for ranges 0..1,0..2,...,0..cnt arg. Nulls are ignored.
```
1 3 6~sums 1 2 3
```
sums is equivalent to `+\S`.

### sysenv

Type: symbol, string, char.

Get a system environment variable (with no caching via `#env`):
```Rust
sysenv 'PATH'
```

### trigonometric functions

Fns: sin, cos, tan, asin, acos, atan.

Atomic, numerical, float, respects null, reuse, lazy.

Type map: * -> f.

```
sin x // etc
```

### trim functions

Rang 1 atomic (acts on Vc), string.

Type map: A -> A.

Trim whitespace from left/rigth/both sides. Trim functions return values of all types except Vc and Ac untouched.
```
trim x; ltrim x; rtrim x
```

Whitespace is: " \t\n\r" (unlike in Q where it is just " ").

### union

Add to `x` all elements from `y` that are not in `x`:
```Rust
1 2 3 4 ~ 1 2 3 union 2 3 4
```

### val

The result depends on the input value:
* string - parse and execute in the current context.
* symbol - get a global variable (raise an err if it doesn't exist).
* symbol-channel (`#ch`) - try to get the requested channel.
* symbol-reference (`&name`) - try to get the local/ctx local/global. Ctx local will be found only if it is also used normally in the function.
* list - execute as a function call: `x.0 . 1_x`.
* dictionary - returns the value part.
* tuple - system commands, see below.
* user function - returns a dictionary with the fn's info.
* internal unary/binary/n-ary - returns its ID number.
* partial/composite function - returns components.
* reference - get the reference's value (raise `ref` err if it is not valid).
* channel - 1b/0b. Opened/closed.

System commands:
* T("pos") - returns a list (line,column,fn name,current line).
* T("pos";idx) - if idx is positive returns info for the fn idx levels below, if negative - idx levels from the start (usefull to get the calling position in a script). If the fn at idx is not a user fn next idx is tried.
* T("stack") - returns a list of entries where each entry corresponds to a function call/other entity. Fn call: (func,start idx,line,col,name,line txt). Effect: symbol. Internal: string.
* T("env") - current global user env.
* T("senv") - system env.
* T("benv") - basic env (default user env).
* T("stackv"), T("stackv";idx) - get the value stack, a value from the stack at idx.
// idea: * T("exec";"expr"\[;is_sync\[;env_dict\]\]) - execute an expression. `is_sync` is true by default (means execute in a separate sync function, execute on the current stack otherwise). `env_dict` is an optional environment (sym!list), the current env is used otherwise, applicable only if `is_sync=1b`.

### vo (vector from object)

Splits an object into parts. The exact meaning depends on the argument types.

Split a vector by atom/another vector (this function is slower than _(cut)).
```Rust
(,"a";,"b")~"=" vo "a=b" // split strings
0 1 vo 100?5 // but other vectors can be split too
'' vo "a=b\rc=d" // special case to split along \r \r\n
// you can provide some customization
T(patt;keep delimiter: 0 - no, 1 - on the right, -1 - on the left;remove empty lists: 1b/0b;smart split:1b/0b) vo y
T('';0;1b) vo "a=b\r\rc=d" // keep delimiter is not available in this case
// smart split works only for XC types, it takes into account ([{}]) and skips vek like strings and syms
(,"1";"'2,3'";,"4")~T(",";0;1b;1b) vo "1,'2,3',4"
(,"1";"(2,3)";,"4")~T(",";0;1b;1b) vo "1,(2,3),4"
```

Get a bit representation of an atom.
```Rust
00000000000000000000010011010010b~0b vo 1234
```

Get a hex representation of an atom.
```Rust
0x000004d2~0x0 vo 1234 // the returned value is in the big endian format, `rev` it if needed
```

Get a representation in base N.
```Rust
1 2 3 4 ~ 10 vo 1234 // fixed base
12 34 ~ 100 100 vo 1234 // each position in its own base
```

### where

Returns indecies corresponding to 1s in a bool vector:
```
where 10101b ~ 0 2 4
```

When applied to byte/short/int/long vector with non-negative numbers returns a long vector where each index i is repeated input(i) times (ungroup mode):
```
where 1 2 3 ~ 0 1 1 2 2 2
```

Complex objects:
* for lists/tuples it gets applied to items recursively.
* for dictionaries returns keys instead of indecies.

### wtake (weak take)

`wtake` is similar to `#`(take) but doesn't duplicate items in lists. If there are less items than requested then less items will be returned:
```
1 2 3~5 wtake 1 2 3
1 2 3 1 2 ~ 5#1 2 3
```

### xparse

Returns a two element list - parse tree and positions.
```
>xparse "1+a"
(+;1;'a')
(1;0;2)
```
Positions are always lists or atoms (never vectors). See also `parse`,`lex`.

### xprev

Shifts a list `y` by `x` positions left. This function assumes that `x` is small.
```
3 xprev ..100
// for a large x use indexing
y (..#y)-x
```

### xtype

Return an extended type description.
```
xtype x;
"@:f3"~xtype {|a b c|}
```
The return value is a char as returned by `type` and additional info after ":" for some types.
* For vectors and lists: "I:xutm", where letters are flags. x(if the vec is splitted), u(list is uniform), t(obj is a thunk), m(not allocated: empty or static).
* For functions: "@:xN" like "@:f3" where x is one of: f(ordinary function), u(unary), b(binary), p(parted), c(composite), n(n-ary). N is the number of args. In the case of a composite function it can be equal to 0 if the first function is not a function.
* Additionaly for unary/binary functions their internal index is added: "@:u1,1034".
* Additionaly for unary/binary functions `a` is added if they are atomic: "@:ua1,34".
* For a dictionary generic types of its key/value are added: "!:SI".
* For a record definition its record index is added: "R:10".
* For a record its name and index are added: "r:time,2".
* For a reference: "&:g" or "&:l" (reference to a global/local or context local).
* for thunked aggregations "1" is returned (`type` forces its argument in this case).

## Suffixes

### DM (deep map)

Recursive map:
```
f\DM(a1;..an)
f\DM[arg](a1;..an)
```

Where arg:
* absent or 0 - apply f\\DM recursively to all lists/vectors.
* 1..100 - apply f\\DM recursively up to N times.
* -1 - apply f\\DM recursively to lists but not vectors.
* -2 - apply f\\DM recursively to only non uniform lists.
* 1b - apply f\\DM as if arg is 0 but use only the first argument to shape the result (assignment mode).

The default (0) mode makes any function similar to the built-in atomic functions. -1 mode is similar to how trim, etc behave, also it makes functions more efficient
because they will be applied to vectors and atoms. -2 mode can also be used for efficiency - to parallelize calcs for example. 1+ modes are not very usefull because
the same can be done with `M` suffix applied several times. 1b mode is used in the deep assign.

### Do Dos

Repeat a function N times:
```Rust
f\Do[N] a; f\Do[N](a1;..;an)
{|x| neg\Do[x<0] x} // it can be used as a conditional, if N <= 0, args are returned as is
first 0 {|x y| (y;x+y)}\Do[19] 1 // Multiple args are ok, but `f` must return a list/vec of the same length
```

`Dos` (do scan) is similar to `Do` but returns all intermediate results (including the start value) as a list.
```
(0 1;1 1;1 2; 2 3) ~ 0 {|x y| (y;x+y)}\Dos[3] 1
```

### F (fold)

Applies a function between elements in a vector/list. In the case of one argument:
```Rust
6 ~ +\F 1 2 3 // function must be binary
7 ~ +\F[1] 1 2 3 // optional initial arg can be provided
```

In case of 2+ arguments:
```Rust
// function must have 1 argument more
// initial arg must be provided
1 2 {|x y z| x+y+z}\F[10] 1 2
```

The first argument is always the accumulator.

### I (identity)

Does nothing, only changes a noon to a verb:
```Rust
1~1\I
2~1 (0 1;2 3)\I 0 // suffix makes (..) a verb
```

### L (left)

Call `f` for each `x` with the same `y`. A helper function based on `map` (`map[10b]` to be exact).
```Rust
x f\L y
("a-x";"b-x";"c-x") ~ "abc",\L"-x"
```

### Lock

*Local* critical section:
```Rust
1b~{|| locked 'x'}\Lock['y']\Lock['x'](); // query state
>{|| {||}\Lock['x']}\Lock['y']\Lock['x']() // double use => exception
Unhandled effect: exc
Exception: locked
```
Because it is local you can't wait until the lock is lifted. You can only abort/raise an exception.

Particulary useful in `recv` to ensure data consistency in case you (or `vek`) call `recv` inside `recv`.

### M (map), Mi (map with index)

Call a function once for each value(s) in a list(s):
```Rust
f\M 10; // for atoms and other non-list values it acts as `id`
f\M list/vector; // for lists/vectors it will be called 1 time for each element
1 1~first\M (1 2;1 2) // map will return a vector if possible
3 5~1 2+\M 2 3; // map can be called with more than 1 arg
```
In case of several args:
* if there is a list/vector atoms will be duplicated

Map supports the argument mask - 0b entries will be treated as atoms regardless of their type:
```Rust
3 5 ~ 1 2 +\M 2 3 // but
(3 4;4 5) ~ 1 2 +\M[10b] 2 3 // the right arg is treated as an atom
```
The mask must have the length equal to the number of args and be a bool vector.

`Mi` is an extention on top of `M`. It adds one argument - current index. It always returns a list even if all args are atoms.
```Rust
{|i x| if i<5`x*2`-x}\Mi 10?10
```

### Ov (over) Ovs (over scan)

Iterate over an argument until it repeats or becomes equal to the initial arg:
```Rust
{|x| (x+1)%10}\Ov 0; // becomes equal to the initial
{|x y| (x+1;y+1)&10}\Ovs(0;0) // repeats
```
For more than 1 argument `f` must have the same rank and return a list/vector with the same number of elements.

### Pr (prior)

Return a list/vector of `f(v i,v i-1)` for a list/vector `v`. An initial value can be provided, otherwise the first element is used (and skipped):
```
10 -8 1 ~ -\Pr 10 2 3
0 -8 1 ~ -\Pr[10] 10 2 3
```

`Pr` is lazy and fast for selected binary functions (~, =, -, /). It is also optimized for other atomic binary functions.

### R (right)

Call `f` for each `y` with the same `x`. A helper function based on `map` (`map[01b]` to be exact).
```Rust
x f\R y
("x-a";"x-b";"x-c") ~ "x-",\R"abc"
```

### S (scan)

Applies a function between elements in a vector/list, returns all intermediate results. In case of one argument:
```Rust
1 3 6 ~ +\S 1 2 3 // function must be binary
2 4 7 ~ +\S[1] 1 2 3 // optional initial arg can be provided
```

In case of 2+ arguments:
```Rust
// function must have 1 argument more
// initial arg must be provided
1 2 {|x y z| x+y+z}\S[10] 1 2
```

The first argument is always the accumulator.

### TO (timeout)

Sends 'timeout' message after the provided time has passed. The message is handled by the default handler that raises '?timeout' effect. It will have no effect if TO function has returned,
otherwise timeout exception is raised:
```Rust
f\TO[100](a1;..) // in ms
f\TO[00:00:10] // time interval
f\TO[time.z+0D00:01] // up to timestamp
f\TO[0D00:01] // timespan interval, value must be less than 1000D
```
You can use several TOs with different timeouts at the same time. TO starts a new subprocess on each call with a different guard value.

Currently timeout can be received only if `recv` is called. TODO: force recv from time to time.

### W (swap)

One argument - duplicates it and calls `f`:
```Rust
2 ~ +\W 1
```

Two arguments - swaps them:
```Rust
1 ~ -\W(1;2)
```

N arguments - rotates them left/right by M positions:
```Rust
f\W[M](a1;...an)
3 1 2 ~ {|x y z| (x;y;z)}\W[2](1;2;3)
```

### Wh (while) Whs (while scan)

Repeat a function while a guard condition is true:
```Rust
f\Wh[g] a; f\Wh[g](a1;..;an)
{|x|x-1}\Wh[0<] 10 // subtract while x>0
10 {|x y| (x-1;y-1)}\Wh[{|x y| 0<x+y}] 2 // Multiple args are ok, but `f` must return a list/vec of the same length
f\Wh arg; // g is id if not provided, repeat until f returns 0b
```
Both functions must have the same arity.

`Whs` (while scan) is similar to `Wh` but returns all intermediate results (including the start value) as a list.
```Rust
(10 2;9 1;...;4 -4) ~ 10 {|x y| (x-1;y-1)}\Whs[{|x y| 0<x+y}] 2
```

### X (eXecute)

Start a new process without a channel:
```Rust
f\X(a1;..) // default environment (val T("benv"))
f\X[dict](a1;..) // with additional environment
```
1b is returned on success.

### XX (eXtended eXecute)

Start a new process. Additional parameters:
* ch - 0b/1b create or not a channel.
* e - user environment.
* qlen - message queue length (default: 100, qlen == 0 means use the default).
Returns the started process's channel on success if ch is 1b or 1b otherwise. Non 0 qlen value automatically sets ch to 1b.

(!) It is not possible to change the queue length of an existing queue.

```Rust
ch:f\XX[![ch:1b]] data;
```

## Prefixes

### \ (exit)

Sends `exit` message to `main`:
```Rust
\\ // exit with 0 code
\\ 1 // exit with any code
exit 1 // translates into exit
```

### g (global)

Define a global. The definition affects everything after and only after it even if it is in a subblock.
```Rust
{|| \g a; ...} // define g as a global
{|| \g a1 a2; ...}
{|a| \g a; .. } // exception!
```
> you can't use `l` after `g` to restore a local, vars will be global in subfunctions as well! Also it doesn't create globals, you need to do it yourself. Use case:
```Rust
{|| \g a; a:10} // without 'g' 'a' is considered a local
```
Alternatives:
```Rust
'global' set value;
{|| g; g:10} // if g exists
```

### l (local)

Define a local(s). The definition affects everything after and only after it even if it is in a subblock.
```Rust
{|| \l a; ...} // define a as a local
{|| \l a1 a2; ...}
```
`l` doesn't override context locals. If a local/context local is already defined nothing happens. Use case:
```Rust
{|| \l a; {|| a:10}} // otherwise a would be a local in the subfunction.
```
`l` is usefull in macroses, in the normal function it is easier to create a local via assign.

### L (local)

Define a local. Similar to `l` but overrides context locals.

### t (time)

Returns the execution time:
```Rust
\t expr // run 1 time
\t:1000 expr // run several times
```

It can be used with any expression:
```Rust
(\t expr1;\t expr2)
```

`t` wraps `expr` in a function and executes it using `Do`.

## Special functions

### eff

Call an effect.
```Rust
effect eff value
'exc' eff "error"
```

An effect (or an algebraic effect) is a tool to abstract side effects. It can be used to implement global variables, exceptions, IO operations, async ops and out of order computations in general.

You can create your own effects or use the built-ins like 'time', 'exc', 'file', etc.

All effects including the system effects can be intercepted. The handler can decide - continue the operation, abort it or save the current state and call it later.

### seff

Sets up an effect handler.
```Rust
seff(effect;handler;func;a1;..;an)
seff('exc';{|e| abort e};+;1;'a')
```

The handler must be a function that accepts one/two arguments. `func` will be called with the provided args in the context of this handler. If you call `abort val` in the handler the calculation will be cancelled
and resumed at the point of `seff` call. Otherwise it will resume at `eff` call.

Two arguments are not yet supported. The second argument will be a continuation - you can save it and decide to resume later and do it several times. This form should be avoided because it is
resource consuming - all stack between seff/eff must be saved, all locals within it will be copied if updated after this, other locals will be inaccessible.

### abort

It can be used in an effect handler to stop the current calulation and return to the point where `seff` was called. `exc` is the prime example. It acts as `id` otherwise.
```Rust
abort val;
seff('exc';{|e| abort e};{|x y| "passed: ",x+y};1;'a') // returns "type"
seff('exc';{|e| e};{|x y| "passed: ",x+y};1;'a') // without abort you get "passed: type"
```

`abort` can be used with a function. In this case a clean up of the stack will be done and this function will be tail called from the handler. The stack between `seff` and `eff` calls is freezed until the handler is done via `abort` so in this way
you may unfreeze it and free unnecessary variables.
```Rust
abort {|x y| x+y}`1`2;
```

Special `abort` call (NYI):
```Rust
abort eff value; // reraise the same eff
// not strictly required because
'eff' eff value; // does the same thing but allows you to terminate the handler at any point + ensures all resources from the current handler are freed
```

## Special forms

### @ (general amend)

In place assign/function application. Up to 3 arguments are supported.
```Rust
@[obj;idx;fn] // unary
@[obj;idx;fn;a1] // binary
@[obj;idx;fn;a1;a2] // ternary
```
Tranlates into:
```Rust
{|v i f| v(i):f\M v i; v} // app1 function, app2, app3 are similar
app1(obj;idx;fn) // @[..] syntax is supported because it is similar to K/Q.
```
Special cases:
```Rust
@[obj;idx;:;a] // generic assign
@[ref var_name;idx;...] // amend some variable in-place
```
Returns either the updated obj or ref.

### . (deep general amend)

In place assign/function application. Up to 3 arguments are supported.
```Rust
.[obj;(idx1;..);fn] // unary
.[obj;(idx1;..);fn;a1] // binary
.[obj;(idx1;..);fn;a1;a2] // ternary
```
Tranlates into:
```Rust
{|v i f| v(i..):f\DM[1b] v . i; v} // dapp1 function, dapp2, dapp3 are similar
dapp1(obj;(idx1;..);fn) // .[..] syntax is supported because it is similar to K/Q.
```
Special cases:
```Rust
.[obj;(idx1;..);:;a] // generic assign
.[ref var_name;(idx1;..);...] // amend some variable in-place
```
Returns either the updated obj or ref.

### if

See `if` description. Conditional evaluation.

### iff

See `iff` description. Conditional evaluation.

### fmt

Create a string from `vek` expressions:
```Rust
fmt"Const str {expr} {}"`value;
fmt"result: {res}, {1+1}"; // variable name or expression
fmt"result: {}",res+1; // as an argument
"{|x| x+10}"~fmt"}!{|x| x+!!}"`10; // change {} to some other char
```

> `fmt` is NOT a function and it can't be called. The result is constructed from the left to be more efficient.

> Don't use "" inside fmt expression blocks. It screws up the synt highlighting.

> fmt string is a normal string so ", \\ etc inside "{..}" MUST be prefixed with \\.

### own

Take a value from a variable and substitute it with `id`.
```Rust
r:10;
a:own[r];
r~id
```

### ref

Get a reference for a variable. It can be usefull if you want to update it in-place.
```Rust
ref name;
```
`ref` is a weak reference and is valid only while the referenced variable exists.

### ret

Return a value from a function:
```Rust
ret value;
ret(1;2;3); // ~ ret (1;2;3), ret always returns 1 value
```

### v

Parse `voml` expression:
```
d:v[
 a=10
 "a's type"='int'
 [dict]
 x = 0D10:10
];
```
`voml` is similar to `toml` format, the difference is all constants follow `vek` rules.

## Pattern matching

You can use the pattern matching in:
* ? - generic pattern matching
* : - assignment
* {[..] } - deconstruct arguments
* recv - message handling helper function

`vek` supports the following patterns:
```Rust
_  // anything, always succeeds
10; "str"; 'sym' // constants of basic types, match: value ~ constant
name // value is assigned to the name
name: p1 // assign p1 value to name: it is match+assign unlike just name which is assign only
@name // take the value from the variable 'name' and compare using ~
() (p) (p1;p2) (p;..) (..;p) (p1;..;p2) // match a generic list or vector with a fixed or variable number of elements
0(..) S(), etc // type letter can be added before () to specify the exact type
name[] name[field: p1] name[field: p1; field2: p2] // match a record
p1 | p2 // p1 or p2
p & expr // a guard expr is evaluated if p is true, expr can't contain | (use parens: "10 & (a|b)")
~ expr // calculate expr and compare it:  e~value
in expr // calculate expr and compare it: e in value
is expr // calculate expr and compare it: expr is e
```

All PM expressions create a function that wraps calculations with `e` variable binded to the current expression:
```Rust
{|e| if patt ...}
```
So there is an issue with variables defined in the pattern, see the rules below.

### ? pattern

```Javascript
patt => expr // basic block of ? expression, if patt is true execute expr
?[expr;patt1 => expr1; ..; pattN => exprN; default] // both default and expr are optional
\? patt => expr ... // prefix form is equivalent to ?[..]
?[patt1 => expr1;..] // without expr you get a function that does PM
?[patt1 => expr1;..] expr // with expr it is equivalent to this expression
?[(1;name) => ..] // name has no default binding rules, generally it will be visible only in its expr and below
name:() or \l name; ?[..]  // define it explicitly if you need it to be visible after ?
?[patt => expr; expr1; expr2; patt2 => ..] // you can insert simple expressions anywhere, they get executed if all patterns above are false
none~?[10;1=>2] // default can be absent, in this case none is returned
```

### : pattern

```Javascript
:[pattern] expr; // generalized assign
:[pattern]; // by itself it evaluates to a match function
\: pattern  // prefix form
:[(1;name)] ~ {\l name; {|e| ..}} // all names within the pattern will be declared as locals
// this means this PM doesn't work in the global context only inside functions
// \l declaration guaranties that bindings will be visible after :[]
// it doesn't override context locals though - you need to be careful with them
:[1] 2 // mismatch exception will be raised if the pattern fails
```

### arguments pattern

```Javascript
{[pat1;..;patn] body} // usage
{|a1 .. an| :[pat1] a1; .. ; :[patn] an; body} // it is equivalent to this
{[patt;name] .. } -> {|a1 name| ..} // name remains as an arg, a2 doesn't exist 
// see : PM for details
// ?[] can be used instead for small functions with 1 arg
?[('a';..) => 1; ('b';..) => 2]
```

### recv pattern

It can be used to receive msgs from other processes:
```Javascript
recv[expr;patt1 => expr1;..; default] // it is similar to ?
```
Differences are:
* the first expr if provided is expected to produce a timeout of `t` or `z` type.
* if the default expr is absent then recv will store incoming unmatched msgs in `msgs` global variable and replay them on the next call.

`recv` will end on timeout or when there is a match. It doesn't define locals for the bindings inside it.
```Javascript
recv(timeout;\? 'a'=> 1) // equivalent to this
```

## Special records

### atomic

Operations with atomic values. They can be used as an alternative to messages:
```Rust
a:atomic.new num; // create a new atomic and init it with a number
atomic.get a; // get its value
atomic.set a`num; // set its value
atomic.add a`num; // add a number to it (can be negative to imitate sub)
atomic.swap a`num; // swap and return its previous value
atomic.cmpx a`num1`num2; // set to num2 iff it equals to num1, returns 1b(success)/0b(failure)
```
Atomics are longs. They are allocated therefore can be shared between processes. They are atomics so it is safe to modify them concurrently.

Note that `a` is passed by value. It is ok to create copies of an atomic value. Communication example:
```Rust
a:atomic.new 1; {|a| {||sleep 100}\Wh[{|| 1=atomic.get a}](); show "end"}\X a; // start a process
atomic.set a`0 // force it to stop
```

### C

Simple tcp connection:
```Rust
c:C[p:port;h:"host";n:"name";pwd:"pass";d:"descr"] // all optional except port`
c:C[p:1234].open; // use open to open the connection
// connection opens in request/reply mode only
```
This record is for debug/exploration/etc. For any serious use there should be a special module.

### time

Can be used to get GMT/local (date)time.
```Rust
time.z; time.d; time.t // GMT datetime, date, time
time.Z; time.D; time.T // local time
```

### path

Path is used to represent a file system path:
```Rust
p["some/path"] // short version
path[p: "some/path"] // record syntax
path!,"some/path" // raw syntax
```

Operations:
```Rust
p.stat // returns a dict with fields: dir - yes/no, link - yes/no, len - long, mt at ct - modify, access, create times.
p.len // length as long
p.dir // is a dir
p.rdir // returns a string list of files
p.file // file part of the path
p.ext // extention part of the path
p.read "x" // read an array from a file, x is a type letter (bxchileftdz, s is not supported), x=b => values will be cast to 0/1.
p.get // if extention is v load the file and execute
p.cd sym/str/char/str list/sym list // make a new path: old_path/x/y
p[].cwd // get the current working dir
```

## Variables

### A

Contains usefull constants:
* `n` - numbers.
* `a` - ASCII small letters.
* `A` - ASCII capital letters.
* `aA` - `a` and `A`.
* `aAn` - `a` and `A` and `n`.
* `pi`
* `t` - vek base types as letters.
* `T` - vek base types as capital letters.

### V

Less used function.

#### args

Returns a list of the process arguments:
```Rust
V.args()
```

#### be

if the platform endianess is big it is `id`, otherwise it is `upper`. To be used with `ov` to select the desired endianess.

#### globals

Extract globals from a value in the given enviroment:
```Rust
V.globals val T("env")`{|| ... } // from a function for example
// the second arg is a sym list => process values in the provided env
V.globals val T("env")`'f1,f2'
```
The function returns a list with three values:
* all referenced globals (except basic variables).
* assigned (writable) globals.
* 0b/1b - 1b if recursion is detected. Self recursion doesn't count.

#### le

if the platform endianess is little it is `id`, otherwise it is `upper`. To be used with `ov` to select the desired endianess.

#### listen

Starts a tcp listener:
```Rust
c:V.listen 'name'`port`(); // port can be 0 to use a random port, the third argument is explained below
// all listeners register with 'main' so you can get them by name
'#m' '@name'
// to stop it
c 'stop';
```
This is a very basic listener that start a new subprocess for each connection. The third param may be a dictionary with fields:
* check - arg: reference to the conn dictionary, return 1b if it is ok. This func is called in the listener itself.
* open - arg: reference to the conn dictionary, it is called in the new connection process when its channel is ready.
* close - the connection is closed, the input value: "" - you closed it, "stop" - peer closed it, "some err" - there was an error, other - unserialized msg (avoid it).
* msg - args: reference to the conn dictionary, msg. Async message.
* req - args: reference to the conn dictionary, msg. Request message. The func must return a correctly serialized reply.
* repl - args: reference to the conn dictionary, msg. Reply message.

Connection dictionary: ip,uname,pass,desc,ch.

The default functions:
* check always returns 1b.
* open does nothing.
* close does nothing.
* msg applies `val` and prints errors.
* req returns back the result of `val` (including exceptions).
* repl does nothing.

#### tzinfo

Parse a file in tzinfo format: `V.tzinfo "/usr/share/zoneinfo/Europe/Berlin"`.

#### scnt

Given a vek object returns its length after serialization on success. Returns the (sub)object that can't be serialized otherwise (so there is an error if it retuns non int/long/atom in general).
The returned length is slightly less than the length of the vector returned by `V.ser` (9 bytes atm) to make this fn easier to use with records.

You can serialize: atoms, vectors, lists of serializable objects, none, dictionary, tuple, unary/binary/naery primitives.
Functions can be serialized if they don't use globals/context locals and have a correct text representation (not produced by a macro/encode). Also it is an error to send a function that uses any macroses except the default ones.
The reason - functions are sent as text.

#### ser

Serialize a vek object. Returns a byte list. Use `scnt` to check if the object can be serialized.

#### deser

Deserialize a vek object.

#### sys

Execute a system command: `V.sys "ls ."`. Returns:
* a list of strings on success
* an exception "error" if the cmd was unsuccessful, details field will contain the stderr output
* an exception "failed" if the cmd is incorrect, details field will contain the error

#### pget

Get a system parameter:
* restart, bool - restart or not the process if there is an unexpected error. 0b by default.
* rlimit, int - how many times to restart. 0W by default.
* rfn, function - the function that will be called on restart.
* wh, (int;int) - width/height for string/stringn/show/etc functions. (0N;50) by default.
* rvalue, bool - send the return value to the parent process as a message: ('child';pid;value). The value can be an exception. Not implemented.

> Parameters are local to a process. 
> 'rlimit' is not getting decremented, there is another counter. This counter gets reseted after each successful async call. You can maintain your own counter to enforce a different policy.
> restart functionality is implemented to avoid loosing data (like a very big table) accidentally. With Erlang's "just restart" approach data would be lost.

#### pset

Set a system parameter. See `pget`.
```Rust
>V.pget 'wh'
0N 50
>V.pset 'wh'`20 30
1b
```

#### voml

`voml` parser. See `toml` help online. `voml` is similar except that all names/constants follow `vek` rules. See also `v` syntactic extention.

## Effect protocols

### channel

* '#s' - get self write channel (create it if it doesn't exist yet).
* '#m' - get main's write channel
* '#p' - get parent write channel
* (id;msg;timeout) - receive, msg is not none if it was rejected (it is not the first call). id is recv id - if called several times the position in queue is saved. All pending msgs will be received and stored in a queue, only one is returned. Output: (0x00; msg) on success, 0x01 - empty, 0x02 - disconnected, 0x03 - timeout. 0x01 is returned if timeout is 0, if timeout is negative - default timeout (1 year atm).
* (channel;msg) - send a message. Returns a bool to indicate success/failure (channel is invalid). There is no exception because channel validity can't be guaranteed.
* channel - return 1b if valid, 0b otherwise.

You can send messages to yourself. If '#s' has only one refcount (itself) the process will terminate.

### net

* (0x00;ip) - returns hostname, port can be added, atm it is hardcoded.
* (0x01;"host:port") - returns ip, port is required.
* (0x02;ip;port;flags) - listen, returns listener channel so you can control it, listener sends msgs to the parent
* (0x03;ip;port;uname;pass;desc;flags) - connect

#### listen/connect

See `IPC`.

#### when connected

You can send messages using the socket channel: ('msg';msg). You can send control commands: 'stop' (atm only one).

You get back: ('msg';msg), ('err';error).

Outbound msg must be produced with serialize.

### spawn

Params:
* (f;a1;a2;..) - function to execute with its args
* env as dict - environment, T("benv") values are expected
* bool - create a channel or not
* queue length