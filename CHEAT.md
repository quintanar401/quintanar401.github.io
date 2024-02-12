## Privitve ops

| sign | binary      | unary      | double      | dunary     | comment |
| ---- | ----------- | ---------- | ----------- | ---------- | ------- |
| #    | take        | count      | N/A         | N/A        | construct |
|      | filter      |            |             |            | a form of take |
| _    | drop        | floor/not/lower | N/A    | N/A        | deconstruct/misc |
|      | filter      |            |             |            | |
| $    | cast        | last/str?  |             |            | convert between values |
| ^    | fill        | null       | N/A         | N/A        | nulls |
| &    | and/min     | where?     | logical and |            | minimum |
| \|   | or/max      | rotate?    | logical or  |            | maximum  |
| +    | add         | ?          | N/A         | N/A        | addition |
| -    | minus       | neg        | N/A         | N/A        | negation |
| *    | mult        | first      | N/A         | N/A        | multiplication |
| /    | divide      | reciprocal | N/A         | N/A        | float division |
| %    | mod         |            | N/A         | N/A        | |
| <    | less        | iasc       | N/A         | N/A        | order, sorting |
| >    | greater     | idesc      | N/A         | N/A        | |
| =    | equal       | group      | N/A         | N/A        | equality, grouping |
| ~    | equivalent  | last?      | N/A         | N/A        |  |
| ?    | rand        | rand 1     |             |            | uniform rand (x is an atom) |
|      | find        | distinct   | N/A         | N/A        | search, uniqueness |
| ,    | concat      | enlist     |             |            | compose objs |
| .    | apply       |            | range       |  til       | see syntax |
| @    | unary apply | type(@:)   |             |            | see syntax | 
| !    | construct   | key        |             |            | new record |
| >=   |             |            |             |            | greater or equal |
| <=   |             |            |             |            | less or equal |
| <>   |             |            |             |            | unequal |

## Syntax

| sign | meaning | comment |
| ---- | ------- | ------- |
| \`    | sugar for function arguments | f(a;b;c) -> f a\`b\`c |
|       | list                         | (a;b;c) -> a\`b\`c |
| \`\`  | remove argument - not sure, \`[]  may be preferable   | f(a;c) -> f a\`\`b\`c |
| ;     | expresson delimiter          | `(a;b;) ![a: 10; b: 20]` |
| \|    | function arguments           | `{\|a b\| a+b}`, `{\|\| 10}` |
| {}    | function/block               | `{\|a\| 10*a}`, `{a:10; a+1}` |
| ()    | arg list                     | `f(a;b)` no spaces |
| ()    | list                         | `(a;b)` at least one ; is mandatory |
| ()    | subexpression                | `(1+2)*3` no ;, space has no meaning |
| ()    | empty generic list           | `()` |
| T()   | tuple                        | `T(1;2)` |
| .     | index                        | `dict.vec.0` - index a var by int const/symbol |
| .     | part of a const              | 12:12:12.111 101.111 |
| .     | non syntactic meanings       | final `.` can't be a part of a name |
|       | deep index                   | `a .(1;2)` |
|       | apply                        | `binf.(1;2)` |
|       | deep index as a function     | `(.)` and other cases where `.` is isolated |
|       | deep idx with a suffix       | `.\Sfx` |
| ..    | any length in a pattern      | `?[x;(1;..) => 2]` |
| ..    | non syntactic meanings       |
|       | range/til                    | 2..10, 10 2..100, ..100 |
| //    | comment                      | // some comment |
| \\    | suffix                       | `+\M`, `f\F\L'` |
| []    | syntactic block              | |
|       | suffix args                  | `f\Sfx[a;b]` |
|       | new record                   | `name[a: 1;b: 2]` |
|       | new dict                     | `![a:1; b: 2]` |
|       | syntax extention             | `recv[1=>2]` |
| '     | symbol/symbol list           | 'sym1', 'sym1,sym2' |
| "     | string/char                  | "str\n\r\t\012", "x" |
| @     | sugar for parentheses        | |
|       | glue(no spaces)              | a@b c ~ (a b) c |
|       | strong glue                  | a b c @ d ~ (a b c) d |
| @     | composition                  | (a b c@), composition of functions |
| @     | non syntactic meanings       | |
|       | unary app as a function      | `(@)` and other cases where `@` is isolated |
|       | unary app with a suffix      | `@\Sfx` |
| :     | assign                       | a:10 |
|       | assign + index               | a(b;c):x, also a.b.0: 10 |
|       | generic assign               | `@[name;idx;:;arg1;...]` |
| :     | intransitivity               | +\L:, make a verb intransitive |
|       | unarity                      | +:, ..:, explicitly make unary |

@ has a greater priority than \`.

## Ops

| Op | meaning | example | comment |
| -- | ------- | ------- | ------- |
| +  | add | 10 + 1 2 3 | add numeric vectors and/or atoms |