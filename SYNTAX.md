# Overview

`vek` can be described as `APL`(`K` dialect) + `Erlang` + `Lisp`. It is `APL` because it is an array language on the expression level. It is `Erlang` because it
supports message passing between processes and is concurrent by nature. It is `Lisp` because it is based on lists and supports macroses and syntax extentions.
Also `vek` supports algebraic effects - a concept so powerful that its full potential is not yet known.

Additional features:
* Pattern matching.
* Modules to build large applications.
* Async and parallel operations support. `vek` is multithreaded by default.
* Explicit IO instead of mmap (specifically io_uring will be used for FSIO).

As an array language it differs from other similar languages in:
* Complex types are based on a record type, users can define their own types.
* Arrays have only 1 dimension (similar to K/Q). The generic list type is used for nested arrays.
* `vek` doesn't use special characters (ASCII only). Only selected operations are mapped to symbols (# - count/take, etc).
* Noun - verb - adverb scheme is changed to noun - (in)transitive verb. Adverbs are changed into suffixes. More adverbs(suffixes) are available, user defined suffixes are possible.
* \[\] are used for syntactic extentions. Indexing/calling a function and generic lists use ().

Async/concurrent features:
* All basic operations are parallelized if possible. `vek` also implements a feature that makes them even faster if they are groupped together.
* All values are safe to use from different threads. If needed `vek` does copy-on-write. There is no shared writable memory/semaphors, etc, only messages.
* All IO operations are async in nature - they do not block, but sync for the programmer (they can be executed in a subprocess if full async is required).
* The cost of starting a new process if very low (like in Erlang).

// * Resource monitoring: cpu, memory, IO. Limits per user.

### Array language - more details

`vek` is closer to K/Q than APL/J. `vek` like K has only typed vectors and the mixed generic list that can be used to emulate matrices. A key difference vs K: there is no automatic conversion of
a mixed list into a vector, instead there is a special function that can do it. Reason - it is really annoying when sometimes a list randomly changes into a vector, if a list is almost
a vector except an element at the end it will be fully checked on each update - introduces unexpected delays. `vek` adds a concept of a uniform generic list - a list with
elements of one type (atoms or vectors). Operations with uniform lists can be easily parallelized. Records are introduced to allow new user types.

Syntactically `vek` also is closer to K/Q. The main difference is: adverbs are substituted by inflections to substantially increase their number.
Also instead of being monadic/diadic/etc all functions are either transitive (expect a noun on their left) or intransitive, this concept is introduced because one of the goals of `vek` is to reduce
the visual weight of expressions (get rid of () and \[\] mostly):
* with the transitive/intransitive concept we can introduce clear rules when a function can be used in the infix position and avoid () or \[\].
* \` can be used to separate expressions instead of (..;..;) or \[..;..;\].
* control structures like if are changed to be more lightweight, their branches are more visible.
* Indexing with int constants and symbols: `a.0.field` ~ `a(0;'field')`.

Another `vek`s goal is to increase the number of types (in Q there are anonymous lists and dictionaries only). `vek` has tuple and record types that are basically mixed lists with a fixed length.
This allows us to add a label (name) to a type and access its elements also by name. Also we can be sure that it's impossible to assign to a missing name/index.

The next goal is to introduce modules to make it easier to build large applications and libraries. `vek` is multithreaded so modules can't have (unprotected) internal state (unlike Q). Instead they
are supposed to start subprocesses that can have global variables. These subprocesses can then handle requests asynchronously.

IO operations are async, functions are executed on several worker threads. IO/Exceptions, etc are done via algebraic effects. Mmap is not used because it can block threads unpredictably and generally is worse than AIO (especially uring).

### Effects

This concept is not yet fully understood. It is easier to list some of their applications.

#### Control flow

Effects can be used to implement flow control structures like exceptions, break, continue, etc. In particular exceptions are implemented in `vek` via an effect by literally one line of code.

#### State

Effects can be used to implement dynamic/global state. If you need a global variable and don't want to pollute the global namespace you need just 1 line of code to implement them.

#### Tests

Everything that has a side effect is implemented by effects in `vek`. If you want to test some code you can just define your own effect handlers and provide predefined values on each call. For the tested
code there is no difference if effects are really executed or return predefined values.

# Syntax

## Expressions

### Literal expressions

#### Bool

```JS
1b // atom
0b
11011b // vector
```

#### Byte

```JS
0xa // atom
0x1f
0x1718182f // vector
```

#### Char

```JS
"x" // atom
""  // 0 length string
"abc\t\r\n\\\"\010\x1a"  // vector(string), special sequences
```

#### Symbol

```JS
'abc'    // atom
''       // null/empty symbol
'x,y,$z' // vector
''$","   // convert explicitly if it contains ,
```

#### Numeric types

Int(default, i), long(l), short(h), float(f), real(e).
```JS
122 // any sequence of digits is an int/long
12.122; 11e10 // if it contains a dot/e it is a float
1e+10;1e-10; // other float formats
122h // type marker changes the default type
1 2 3 // vector - numbers separated by exactly 1 space
1 2.3 4 // float vector
1 2 3f // type marker
0N // int null
0n // float null
0Nh // type marker
0W 0w 0Wh // infinities
-0W -0w -0Wh // negative infinities
-100 // negative number if there is a space/expr start before -
-20 -20 -20 // also in a vector
```
`_` is allowed inside integer consts to make them more readable:
```JS
10_000_000
```

#### Temporal types

Date(d), time(t), datetime(z).
```JS
2010.10.10 // date
10:10:10.111 // time
10:10 // at least one : is required
2010.10.10T10:10:10.000 // datetime
2010.10.10Z // time part can be shorter/absent, also T and D can be used
10T10:10 // define as a time span, it is still datetime
1000t // define via int with a type marker -> 10:00
0Nd 0Wz -0Wt // nulls, infinities
10:10 10:11 10:12 // vector - values separated by exactly 1 space
-10:10 // rules are similar to ints
time.z; time.Z // + d,t. Can be used to get GMT/local date(time)
```

### Composite expressions

#### Generic list

```Rust
() // empty list
(1;"a") // a list is generic if elements are different
(1;2) // vector, similar to 1 2
list(1;2) // explicitly generic
ulist(1;2) // the same as (1;2), u means uniform - check uniformity and convert to a vector if possible
,x // enlist, produces a 1 element vector or list
(),x // make a vector(if possible)/list
x,() // make a generic list regardless of x's type
'v'!x // try to convert to a vector
```

#### Tuple

A generic list with a fixed length.
```Rust
T() // empty tuple
T(1;2) // syntactic sugar
tuple(1;2) // actual function
```

#### Records

See REC.md

#### Function/Block

Function:
```Rust
{|a1 a2|...}
{|| } // 0 args, it is a function with 1 arg that is ignored
f[x+y] // synt extention for functions with 0,x,x y,x y z args.
\f x+y // prefix form, can be used only if delimited. error: 1,\f x+y, should be 1,(\f x+y)
```

Return from a function:
```Rust
{|a| a+1} // the last expression is returned by default
{|a| ret a; b} // ret keyword can be used
{|a| ret; ret(1;2)} // both allowed. ~ ret :: & ret (1;2)
```

Call a function:
```Rust
f 1 // unary call
f() // unary call, arg will be id function
f(a;b) // generic call
a div b  // if f is transitive
a f b`c  // special call syntax for transitive functions
f a`b`c  // and for intransitive
```

Block:
```Rust
{...}
if cond`{expr1; expr2};
```
A block can be used anywhere, it is executed from left to right, the result of its last expression is its result:
```Rust
{...;+}(1;2)
```
There is an alternative to the block:
```Rust
// probably will remove it because `[] can be used for quote
a``b``c // a``b is {b;a}
a+1``a:10 // evaluates right to left
```
It can be used to maintain right to left flow.

#### Other functions

There are unary and binary core functions:
```Rust
3~#1 2 2 // unary function
3~1 2 3#:1 2 // explicitly unary
3 3~2#3 // binary
neg 1 // some unary/binary functions have names
10 div 3
2~#(1;2) // symbols can't be called with () directly
(#)(1;2) // use ()
```
One symbol can mean an unary or binary function. See transitivity rules for more info. Generally it is unary if there is a function (or similar) object on the left or nothing at all.
You can always enforce unarity by adding `:`: `#:`. () makes any symbol binary: `(#)`. `I` (identity) suffix also makes any function binary: `+\I 1`.

Partial functions:
```Rust
>1+
+(_;)
>{|x y|}(;1)
{|x y|}(;_)
>val {|x y|}(;1) 
{|x y|}
??
1
```
If you call a function with less arguments than it expects you get a partial function. In the output filled arguments are substituted with `_`. To see arguments apply `val`.

Composite functions:
```Rust
#neg+ // if a list of functions ends with a binary fn
#1+{|x y| x*y}@ // in other cases use @
```

Multiargument functions. These are internal functions that do not have a fixed number of arguments. These are mostly suffixes like \\M.

#### Variables

Function arguments - up to 128 (artificial limitation). 0 argument functions have 1 invisible arg.
```Rust
{|a1 a2| a1 + a2}
```

Function locals - up to 2048 minus number of args.
```Rust
{|a| l:10; }; // assignment marks a local, otherwise it is a global
{|a| l+10; }; // l is a global
{|a| \g l; l:10} // use \g prefix to make a variable global
{|| l:10; {|a| l:10; }()}; // (!) l is a context local in this case
{|| l:10; {|a| \L l; l:10; }()}; // use \L prefix to override.
```

Context locals. Syntactically binded locals in the enclosing functions. Max depths - 8 functions. Only the first 256 locals at each depth can be referenced.
```Rust
40~{|a| l:10; {|x| x+l+a} 20} 10;
```
> CONTEXT LOCALS ARE NOT CLOSURE LOCALS LIKE IN OTHER FUNCTIONAL LANGUAGES. See their description for their limitations.

Globals = up to 2048 globals. `set` and `val` can be used to set/get value of a global as a symbol.

Context local's limitations:
* `vek` doesn't create closures so such a local can be accessed only until its function returns.
* any manipulation with a function - saving it for later use (tmp assignments are ok), sending to another thread, etc will break its link to the clocals.
* all above means that they can't be used to save state for a long time/emulate objects (unless you do an infinite loop like `{|| recv[..]; self()}`).
If a function was successfully created then all its context locals can be theoretically accessed. If there is a runtime error then the function is called out of its syntactic context.
There are advantages too: you can change such locals and the changes will be visible in the current computation in other functions.

The main reason to make such locals is to allow you to store large objects in them and update them in place.

#### Tail calls

Whenever there is a call that is the last expression the enclosing function may be ended (its stack/args/locals cleared) before this call starts:
```Rust
{|| a:10; ret f a; f a} // both exprs are a tail call
{|| a:10; ret 1+f a} // this is not because 1+ is pending
{|| ...; self()}() // tail calls can be used for infinite loops or just loops.
```
Tail calls are not fully compatible with the context locals:
```Rust
{|| a:10; {|b| a+b} 20}() // it is not a tail call because {|b| ..} references clocals
{|| a:10; {|b| {|x| x+1} a+b} 20}() // {|x| ..} call removes {|b| ..} function but {|a| ..} is not removed because its locals may be used by its child functions (not in this case though)
```
Any function that either contains clocals used by another function or is between such functions is marked as not eligible for a tail call and will not be removed from the stack.
On the other hand a function that uses clocals but doesn't contain functions that also use them (its locals or locals below) can be removed from the stack:
```Rust
{|x| {|| x:x+1; ret 0 iff x>10000; self()}()} 1; // {|| ..} is removed from the stack on each self call
```
The safe bet is to use only top level functions for recursion.

#### Effects

Direct access to effects is restricted. `eff` and `seff` functions can be used only with root permissions.

Effect is an action executed outside the normal execution flow. Usually it is a request for an external resource, something that has a global side effect.
The most common effects are: IO or communication requests, exceptions, global state (for efficiency `vek` supports native global variables), async functions,
continuations. In particular exceptions are an effect `exc` in `vek`.

In `vek` an effect is triggered via `eff` function:
```Rust
'effect_name' eff value
```
The value will be passed to the effect handler if there is one. The effect may or may not return or may return more than once. Exceptions do not return. Continuations
can return several times.

A handler is set using `seff`:
```Rust
seff('effect_name';handler;fn;a1;..)
```
It setups a handler and executes the provided fn in the context of this handler. The handler function MUST take one of 2 forms:
* {|v| v+1 } - general case. Its return value is the return value of `eff` expression. The handler may abort the computation (like an exception handler) with `abort` keyword.
* {|v cont| } - continuation case. In this case a copy of the stack will be created (values will get ref count +1, so cont can't be used to share). `cont` is a continuation and it can be used to resume the current calculation at any moment.
Case 2 is resource consuming and doesn't work well with the context locals.

To abort the computation inside a handler (abort value is the return value of the corresponding `seff` call):
```Rust
handler:{|v| if v=1`2`abort 3} 
```

Soft effects:
```Rust
'?name' eff value
```
A soft effect call will not fail if there is no handler. `none` is returned instead.

#### Other

```JS
() // empty generic list
none // indicates absence of a value
```

### Composite expressions

#### List

```JS
() // Empty generic list
,x; ulist x; // 1 element list, if x is an atom the result is a vector 
(1;2;3) // n element list, if all elements are atoms of the same type the result is a vector
list x; list(x;y;z) // the result is always a generic list
```

To convert between generic/typed list
```Rust
0#0 // typed of size 0
'i'$() // typed of size 0
x,() // make generic, x: list, vector, atom
(),x // make typed, x: vector, atom
'v'!lst // try to convert lst to a vector
```

### Control expressions

Cycles can be and should be implemented via suffixes/tail recursion.

#### if/then/else

Short `if`. `iff` acts as an expression breaker. `a b iff c ~ (a b) iff c`
```JS
expr1 iff expr2 // infix form, execute expr1 if and only if expr2 is true, the return value is the value of expr1 if expr2 is true and:
expr1 is: // Not impl atm
  a: expr // return `a` if expr2 is false
  a(idx;..): expr // also `a`
  expr // return () otherwise
iff(a;b) // functional form
```

Normal and long `if`:
```JS
if a`b`c // simple if, `c` is optional (`b` is also optional).
if a`b`else c // `else` can be used in long ifs for readability
if a`b`c`d`e // generic if (case), the last expr (e) is optional
if a`b`elif c`d`else e // `elif` also can be used to make long ifs readable
if(a;b;c;d;e) // `if` acts like a function so it can be 'called'
```

The return value of a missing branch is `()`. In a long `if` to create a block:
```Rust
if cond`{
    expr1;
    ...
}
```

To avoid nested ifs use the lazy `and` and `or` functions:
```JS
if a && b || c` .. ` ..
```
They are evaluated as all functions from right to left (the expression above is `(a && b) || c`)!
```JS
a && b ~ if b`a`0b
a || c ~ if b`1b`a
```

### Errors/exceptions

`vek` by default distinguishes 3 types of errors:
* signals - timeout, exit and etc.
* errors - unexpected errors caused by invalid expressions: `1+'a'`.
* exceptions - errors raised by a user/library.
All of them are based on effects and can be intercepted. Additional types of errors can be defined with effects too.

#### signals

These are hardcore exceptions. Usually you don't want to intercept them because they are not meant for you.

#### errors

They indicate that something is wrong with the program so you usually don't want to catch them unless you intentionally provoke them (tests).
```Rust
f\Err[handler or value]
handler:{|er| ..};
```
To raise an error you can evaluate a bad expression that causes it.

Effect: `err`.

#### exceptions

Ordinary exceptions that can be raised and captured by a user.
```Rust
f\Exc[handler or value]
handler:{|ex| ..};
exc ![e:"name";st:0b;msg:"";data:()]; // only e is required
exc "name"; // ~ exc ![e:"name"]
exc data; // ~ exc ![e:"user";data:data]
exc rexc!![...] // can be reraised or created manually
```

You can raise a chained exception - a list of 1+ normal exceptions.
```Rust
exc cexc!![data:(e1;..;en)]
exc ![e:"chained";(e1;..;en)];
```
Each `ei` will be converted into an exception if needed, chained exceptions will be spliced (the result will contain only simple exceptions).

`exc` will construct an exception record with fields (only `e` is required), all of them except `data` read-only:
* e - short name (string).
* st - add/not add stack trace (bool). In the record it will contain the value returned by `val T("stack")` or ().
* msg - description (string).
* data - additional data.

Available functions:
* str - returns a string representation of the exception.
* show - prints the exception.

You can (using `eff` directly) raise an exception of any type but do not do it. `exc` expects either `rexc` or `cexc`. You can create your own kind of exception if needed.

Effect: `exc`.

### Verbs, nouns and etc

`Vek` like other vector languages uses the natural language analogy. Unlike other languages that are based (most likely) on English, `Vek` is inspired by so called agglutinative languages (Finish, Japanese, ...). In these languages words are formed by stringing together morphemes and each morpheme generally has only one meaning/grammatical category. This means there is no need for adverbs and other similar constructs because their role can be taken by special morphemes.

Let's first define what we mean by verbs and nouns. Generally a verb is a function and noun is data. In the vector languages however data can be "called" like a function and functions can be passed around as data and stored in variables. Nonetheless it makes sense to consider some entities as verbs - functions almost always are called and this allows us to treat them differently in a sentence. Thus true verbs are:
* primitive operations like `+`.
* core functions like `div`.
* user defined functions: `{|..| ...}`.
* inflected words (more below).

There are also some clear nouns like constants, lists, etc. User variables can be functions and data. We could force a user to use different names for them but this doesn't make much sense. By default we treat names as nouns.

There are no adverbs in `Vek`. In Q adverbs are used to organize cycles: fn each data -> apply fn to each element of data. In an agglutinative language inflections play this role:
```Rust
b f'a // Q/K
b f\M a // with a suffix
```

We can use suffixes and prefixes:
```JS
word\Suffix  // most common inflection 
+\F // +/ in Q 

\prefix expr // can be used for annotations, commands, other special purposes
\t:100 f\M list // time it function
```

The example above doesn't look impressive but agglutinative languages are really powerful when you want to condense a lot of meaning into one word.
```JS
a f\Try[0]\Map\Swap b // Map,Swap for clarity. Swap args, apply g to each pair of a,b where g is f wrapped with an exception handler that returns 0 on an exception
```

The main benefit here is that we can use as many suffixes as we want. Some of them can play the grammatical role (Swap), others add an effect (Try), others change the behaviour (Map).

### Transitive/intransitive verbs

A transitive verb is a verb that expects an argument on its left. These are:
* Binary primitives like `+`.
* Other core functions that are marked as transitive: `div`.
* All verbs with a suffix: `f\L`.

All other verbs are intransitive. Note that a function with more than 2 args also can be transitive. A transitive verb becomes intransitive under the following conditions:
* There is nothing on the left: an opening paren, ;, start of file and etc: `(-x;#x)`.
* There is an unary/binary primitive on the left: `^-x`.
* There is another core function on the left: `x div -y`.
* There is an inflected word on the left: `+\F -x`.
* There is a user function on the left: `{|..|..} -x`.

Special exceptions are `@` and `.` (apply functions) because they expect a function on the left.

In other words a verb becomes intransitive if there is nothing that looks like data on its left. Note that you can use () to make any expression look like data: `(+)`. The transition rules are:
* A binary primitive becomes an unary primitive: take -> count.
* Functions stay the same but expect their args on the right: `x div y -> div x`y`.
* Suffixed functions also expect their args on the right.

The conversion can be done explicitly with `:`
```Rust
+ -> +:
+\F -> +\F:
div -> use () like div(x;y) or div x`y
```