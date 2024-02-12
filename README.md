# Overview

`vek` is an array language with features from Erlang and Lisp.

## Data types

Basic - atomic or vector (array).
|name|letter|atom|vector|size|
|----|------|----|------|----|
|bool|b|1b|10101b|1|
|byte|x|0x1a|0x1112|1|
|char|c|"a"|"ab\t\n"|1|
|short|h|10h|10 -20 30h|2|
|int|i|10|10 -20 30|4|
|long|l|10l|10 -20 30l|8|
|real|e|10e|10 -20 30e|4|
|float|f|10.1|10 -20 30.1|8|
|time|t|10:01:02.003|10:00 11:00 12:00|4|
|date|d|2010.01.02|2023.01.01 2023.01.02|4|
|datetime|z|2010.01.02D10:00|2010.01.02D10:00 2010.01.02D10:01|8|
|symbol|s|'sym'|'s1,s2,s3'|4|

Strings are char vectors. Symbols are int indexes into an array of interned strings. Datetime has an alternative representation - time span: 0D10:00.

Generic list: `()`,`(1;"a")`,`list(10)`. Size: 16*length.

Tuple: `T(),T(1;2)`. A tuple is a generic list with fixed length.

Record:
```Javascript
complex:r['.n':'complex'; a:0N; b: 0N]; // define
c:complex[a:1 2;b: 2]; // create
```
Don't use records for OOP. Use them to 1) extend basic types (complex) 2) hide info (resource handle) 3) create a micro library (time). Records are based on the generic list.

Functions:
```Javascript
+: // unary primitive
+ // binary primitive
neg div // internal functions
{|a1 a2| a1+a1} // function, generic definition
f[x+y]; (\f x+y) // function, short form
f(;10) // partially called function
f1 f2@ // composition
```

Dictionary:
```Javascript
list!list // generic constructor
![a:10; b:20] // sugar for dicts with symbol keys
```

Other types:
|name|constr|print|descr|
|----|------|-----|-----|
|none|none|none|argument is not provided, channel is empty/timeout|
|write channel|val '#name'|\<ch\>|write channel of a process|
|reference|ref name|\<&g\> \<&l\>|weak reference to a global/local|
|record ID|r\[..\]|\<rec def\>|record definition|
|read channel| | |internal|

`vek` uses `none` to indicate that there are no messages in a channel - don't send it as a message.

## syntax

Execution of expressions is from right to left. Operations don't have priorities. There are several logical exceptions to these rules. Overview:
```Rust
// applications/calls
f a // right argument is applied to the left: f(a)
e1 transitive_func e2 // some functions are transitive and can have an arg on the left
e1 + e2 // in particular binary primitives are transitive
f(a1;a2) // use () to call f explicitly
+(1;2) // primitives ignore ()
(+)(1;2) // correct way
f a1`a2`a3 // ` can be used instead of f(a1;a2;a3)
a1 f_tran a2`a2 // the same applies to the transitive fns
g f\M: 1 2 3 // suffix : can be used to make a transitive function intransitive
+: // it also converts a binary primitive to unary
div: // error, it can't be used with named primitives atm, use div(1;2)
0 (1 2 3;4 5 6)\I 2 // suffix I(identity) converts any obj into a transitive fn
f\M // suffix application
+\F[0] // suffixes can have parameters
+\F[0]\M // suffixes can be chained
f\M(1 2;3 4) // suffixes have priority over ()
1 2 +\M 3 4 // all suffixed expressions are transitive (unless they end with :)
f@a+1 ~ (f a)+1 // @ or glue can be used to break right to left eval rule
9~1+@2*3 // glue in case of a transitive fn
f a@ b+c // strong glue, maybe it is useless and needs to deleted
a.1; a.b; a.b.1.3 // const indecies into lists/dicts/records
(a+1).1.2 // they also can be applied to expressions
.1.2 // but they are just a sugar so this syntax is not allowed

// special forms
{e1;e2;e3} // block of expressions, evaluates from left to right and returns e3
{|a1 a2| expr} // function
ret e // explicit return from a function
{|x| ..; x+1} // implicit return - the last calculated value
if cond`e1`cond2`e2`default // "if" allows any number of branches
if(cond;..) // the same
if cond`e1`elif cond2`e2`else e3 // elif/else are ignored and can be used in large ifs to make them clearer
if cond`{a:10; a+1}`2 // use {} (blocks) in large ifs
d.a iff 'a' in !d // if and only if ~ if 'a' in !d`d.a
self // the current function
\g name (name)* // declare variables as globals
\l name (name)* // declare variables as locals but don't override context locals
\L name (name)* // declare variables as locals in the current function (strong variant of \l)
// the three above affect expressions that follow them and all of them, even if you use them in a subexpression
// though you can use \g then \l again the new local will not be the same local as before - TODO: fix

// syntax extentions
@[f;idx;fn;a1;a2]; @[f;idx;fn;a1]; @[f;idx;fn] // generic apply, based on app1,..
.[f;idx;fn;a1;a2]; .[f;idx;fn;a1]; .[f;idx;fn] // generic deep apply, dapp1,..
p["/path/xx/"] // create a path record from a string
rid:r[a:0;b:0] // define a record
rid[a:10;b:20] // create a record ~ rid!![a:0;b:0]
![a:1;b:2] // create a dictionary with symbolic keys
?[pattern => expr; ..; default] // pattern matching function
?[expr;pattern => expr; ..; default] // pattern matching in place
:[pattern] expr; // destructive assignment
{[pattern;..] ..} // destructive assignment in arguments
recv[timeout;pattern => expr; ..] // match incoming messages
m.name[e1;..;en] or \m name e1;..;en // macros
\prefix expr // another kind of macros/extention
multiline text macroses - not specified atm, probably something like \\name, \NAME etc
```

### suffix

A functor that you can apply to a function to make it behave differently, add some side effect. These are mostly: 1) generalizations like map
2) syntactic functors like swap/duplicate 3) side effect handlers like exception handlers. Suffixes are also functions, the difference is subtle. 
Any function that adds some generic effect to other functions can be considered a suffix.

Suffixes can have parameters. The suffix decides what to do with the function arguments based on its logic and parameters:
```Rust
f\F[10] 1 2 3; // here we use 10 as the initial value for fold suffix
f\M 1 2 3 // map generally doesn't need parameters
```
You can easily define your own suffix:
```Rust
'\MySfx' set {|params func| ..} // more general form, see Exc for example
'\MySfx' set {|params func a1 ..| ..} // more rigid, see \R
// params is set to none if not provided, otherwise it is a value/list.
```

> Suffix must be general like map, spawn, dynamic break, etc!

There are also prefixes:
```Rust
\t:1000 sin 1
1,(\f x+y) // prefixes must be delimited
```
They provide syntactic extentions.

### transitive functions

Extention of the idea of a binary primitive. They allow you to use functions in the infix position and get rid of extra (). Generally a function-like
object will be transitive if there is a noon-like object on its left. See `SYNTAX` for the exact rules.

> a binary primitive becomes unary if it is intransitive! So you can chain them: `!#*x` = `key cnt first x`.

### : suffix

A special suffix that makes a transitive fn intransitive and converts binary primitives to unary.

### ` delimiter

Its goal is to reduce the visual weight of expressions and number of (). You can use it only once per an expression unless brackets/parens are used. See `SYNTAX` for the exact rules.

### @ (glue)

It is used to avoid (). In simple cases you can just glue two simple expressions together. There must be no spaces around it.

### index expr

If you index a list with a number or a dictionary/record with a name you can use dot notation: `a.b.1`. It is the same as `a('b';1)`.

### syntax extentions

They exist to allow you to deliberately break `vek` syntactic rules. There are some predefined extentions like `?`. All signs and 1 letter names are reserved. Records and extentions use the same syntax so you need to be carefull. Macroses are special extentions with their own rules.
```Rust
?[(x;..) => x*10] // pattern matching extention
recv[('msg';data) => process data] // helper extention for recv function
![a:10] // dict sugar is an extention too
f[x+y]  // also an extention
// there are also prefix extentions
\t expr; \t:100 expr // timing extention
\l name1 name2 // these are also extentions
```

## Execution

The order of execution is from right to left. First all arguments are calculated starting from the last, then the function expression. Suffix params are calculated with the function expression also from right to left.

Suffixes are applied also from right to left. `f\M\F` - in this case `F` will be called with `f\M`.

Transitive case may be confusing because the first arg is calculated before the function but it appears after the function. The rule is: args are always calculated first.

`if` and `iff` naturally have a different control flow. First a condition is calculated and if it is not 0b/0/0l/0h/0x00 then the corresponding "then" branch otherwise the next condition/default branch.

Effects including errors/exceptions break the default flow. If there is a handler it will be executed out of order on tp of the stack. The handler may resume the normal flow or abandon it, see effects documentation.

Async requests do not break the flow (by default) but they may suspend it indefinitely. Use timeouts. They are effects though so you can redefine the defaul behaviour.

`g`, `l` and `L` special forms only affect bytecode generation.

Syntax extentions/macroses are resolved at the parse stage. Each subexpression will be evaluated in a separate sync enviroment so they are totally isolated and don't have access to async functions (can't send/recv msgs in particular).

`vek` supports tail calls with some restrictions. A tail call will not be used if it may (not necessarilly will) break context locals. See `SYNTAX` for more info.

`vek` doesn't support closures (intentionally!) but you can reference outer local variables with some restrictions. See `SYNTAX`. The reason why `vek` doesn't support them is that it is highly
concurrent so closures become automatically readonly - useless for big data. Instead of closures the global environment can be used (closure=process+its globals) or records.

## Effects

Effects are like interrupts. You call an effect using `name eff arg` function, `vek` searches for a handler, if one is found it executes it. The handler can either return a value or
abort the current computation, in this case `vek` resumes from the place where the handler was set up. This sounds like exceptions/exception handling and indeed `vek`'s default exceptions
work via an effect. You can easily implement your own exceptions using effects. What is puzzling - why effects are not used in any other language - they are so simple, powerful and
abstract.

> Effects were studied as a generalization of monads in Haskell. They allow you to combine different monadic computations (computations that must be done in a sequence) into one big computation.
> They are therefore ideal for async IO operations, exceptions, flow control structures.

One really powerful feature of effects - they make your program like a template where effect operations can be defined later. In a real program for example if you read a file you get back
its content but in a test you can redefine the effect handler to return a predefined value:
```
function:... // code itself doesn't do much
interpeter1(function;handlers) - one possible interpretation of the code
interpeter2(function;handlers) - another possible interpretation of the code
...
// for example
'log' eff message // we do not care what happens: log may save the msg in a file, print it, ignore etc
```

## Processes and messaging

`vek` supports unlimited number of processes that communicate using async channels (very similar to Erlang but the execution is done by Rust async lib: tokio). The process always has access
to `#m`(main) and `#p`(parent) write channels and may have its own write channel `#s`. For efficiency
the write channel is not always created. `vek` core doesn't define how messages are processed and their format but it has some helper functions in `vek.v`:
```
// all messages are divided into async messages (expected format is ('name';...)) and requests (via req record)
'#p' send ('getData';1) // send an async message
// requests emulate sync messages on top of async
res:'#p' syncsend ('getData';1)
res:'#p' ('getData';1) // shorter alternative

// recv macro can be used to process async msgs/requests
recv[
    r:is req => ?[r.m;
        ('getDataReq';1) => r.repl 2;
    ];
    ('getDataMsg';1) => 2;
]
```

The input queue size is set to 100. `recv` drains all messages so this should not be a problem unless 1000+ processes write at the same time. TODO: queue size increase.

Spawn:
```
{|a| a+1}\X 10 // env is copy of the current env
// TODO: set env - clean/current/provided generic/proc specific, channel: create y/n, queue size: N; default handlers? \X[1b;1000;'def';![v:10]]
```

Number of processes can be very large. `vek` or `tokio` to be more exact can handle even millions, the issue is - the default input channel is too small. Tests:
* 150.000 cycles per second in spawn/send a msg to parent/wait for child mode cycle.
* 75.000 processes spawned at the same time, wait for a random delay 0..1 sec, send a msg to the parent. Parent waits for all children.
* ~500.000 processes if the interval is 1..10 secs. The bottleneck is the input queue.

You need to adapt the mindset in which start of a new processes is like calling +.

## Overall program structure

The following is not a part of the core and can be changed.

`vek` starts in the following configuration:
```
main-->stdin-->repl
    -->auth?
    -->mod?
    -->gbin
```
where each name is a separate process. `main` provides general services to all other processes, it processes channel search requests for example. `stdin` reads stdin and sends lines to clients. It also starts `repl`
which becomes its main client if `vek` is started from console. `auth` validates requests for resources. `mod` manages `vek` modules. `gbin` (garbage bin) recycles large generic lists and calls destructors for records.

`vek` emulates OS to some extent. Processes have a parent for example. Children on the other hand are not required to register with their parents. This is done for efficency. If you start millon subprocesses all this 
bureaucracy can take a lot of time.

CHECK, maybe impact is not that big: Also channel queues take a lot of memory. A simple process that doesn't have a channel and doesn't change globals will consume little memory. `vek` in the future will impose
time/space constraints on orphan processes and force them to register if they break them. You'll be able to kill them then.