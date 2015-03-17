# reader-writer-state

A Haskell addendum to @TatumCreative's presentation "Killing JavaScript's
`this` - Practical Functional Programming".

## Setting up

To follow along, you should have GHC and Cabal installed. @bitemyapp has a nice
[community-maintained guide](https://github.com/bitemyapp/learnhaskell) on how
to setup GHC and Cabal for various operating systems (note: you should *not*
install `haskell-platform` that is typically available in package
repositories). Make sure that the `cabal` binary is in your path, then clone
this repository, create a sandbox in which to install dependencies, and start a
REPL.

```
$ git clone https://github.com/zerokarmaleft/reader-writer-state
$ cd reader-writer-state
$ cabal sandbox init
$ cabal install --only-dependencies
$ cabal repl
```

The last command - `cabal repl` - launches GHCi (an interactive session with
GHC, the compiler), and Cabal ensures that the dependencies of the project as
well as the code of the project itself is made fully available. The GHCi prompt
itself should look like:

```
Prelude> 
```

The "Prelude" means that GHCi has loaded the Haskell Prelude module, which you
can regard as a relatively small standard library.

## Writer

Let's start by creating a purely functional logger. You want a pure function
that implements some useful computation and returns a value, yet also logs some
messages elsewhere so that you have an accounting for things that were done. At
first glance, logging seems intrinsically *un-pure*.

You can easily write log messages out to the console in JavaScript:

```
function Logger(message) {
  this.count = 0;
  this.message = message;
}

Logger.prototype.log = function() {
  this.count++;
  console.log(this.count + ":" + this.message);
};
```

If we decompose the functionality of `log` into separate parts, perhaps we can
build it back up in a purely functional style and gain insight along the way.

What's the type of the `log` function? It accepts no arguments and returns no
result. In Haskell, the type might be expressed as `() -> ()` where `()` is
pronounced 'unit'. `log` is invoked *solely* for its side effects of printing a
message to the console. It also tracks how many times it's been invoked, and
includes the count as part of the message.

A pure function *must* return a value, so let's rewrite `log` to return *a pair*
containing the state of the log, *and* the value `log` normally returns (which
is `()`). If we were to represent the state of our log with a simple string,
then the type of our pure `log` function would be `() -> (String, ())`.

In Haskell, this is a standard abstraction and it's called `Writer`. A
simplified type definition for `Writer` might look like this:

```
newtype Writer w a = Writer w a
```

where `w` is the type of the log - the values we want to accumulate - and `a` is
the type of the return value for the pure computation. In our case, `w` is just
a String. We still want logged computations to be able to return any type of
value, so we leave the `a` type parameter untouched. Let's create a type synonym
so our intent is a bit clearer.

```
type PureLogger a = Writer String a
```

Anywhere we would write `Writer String a`, we can write `PureLogger a`
instead. A value with this type implies that it is a purely functional, logged
computation that returns a value of type `a`.

One of `Writer`'s operations, `tell`, writes values of type `w` to our
log. Since `PureLogger` is a synonym for `Writer`, all of `Writer`'s operations
work equivalently with `PureLogger`. Let's write a simple helper function for
logging string messages:

```
logMessage1 :: String -> PureLogger a
logMessage1 message =
  do tell $ message ++ "\n"
     return ()
```

We've added a bit of extra logic to append a newline for each message written to
the log. I'll explain why this is necessary shortly. Now, in GHCi, we can
see what happens by invoking `logMessage1`:

```
Prelude> logMessage1 "hello"
WriterT (Identity ((),"hello\n"))
```

Evaluating `logMessage1 "hello"` *returns a pure value*. It's wrapped inside a
couple of curious looking constructors which are out of the scope of this
write-up, but if we look carefully, we notice that the payload is the pair we
expect.

GHCi resolves type synonyms fully before displaying them. `PureLogger a` is a
synonym for `Writer String a`, and `Writer String a` is a synonym for `WriterT
String Identity a`. Hence, instead of displaying `PureLogger ((),"hello\n")`,
GHCi resolves the synonyms and displays `WriterT (Identity
((),"hello\n"))`. `Writer` has an operation, `runWriter`, that returns the
payload.

```
Prelude> runWriter (logMessage1 "hello")
((),"hello\n")
```

What happens when we invoke `logMessage1` twice?

```
Prelude> runWriter (do { logMessage1 "hello"; logMessage1 "goodbye" })
((),"hello\ngoodbye\n")
```

You can see that both of our messages are logged. When we decide to actually
print out the log value, we want each message to be printed on its own line,
which is why we append newlines to a message in the implementation of
`logMessage1`. Notice also that the messages in the log value are in the same
order as the calls to `logMessage1`. `Writer` preserves the ordering by
concatenating each new message onto the end of the log state from the previous
invocation of `logMessage1`.

Let's say that we to use our logger to track the progress of a pure,
two-stage computation.

```
sumOfSquares :: Int -> Int -> Int
sumOfSquares x y = (x * x) + (y * y)
```

`sumOfSquares` is, of course, a pure function that returns the sum of the
squares of `x` and `y`. Now let's add logging:

```
sumOfSquares1 :: Int -> Int -> PureLogger Int
sumOfSquares1 x y =
  do logMessage1 $ "Input parameters: " ++ show x ++ " and " ++ show y
     let xSquared = x * x
         ySquared = y * y
     logMessage1 $ "Squaring first parameter: " ++ show xSquared
     logMessage1 $ "Squaring second parameter: " ++ show ySquared
     return $ xSquared + ySquared
```

We use `logMessage1` in `sumOfSquares1` to log the input parameters and the
intermediate, squared results. The result of the sum is returned as the first
element of the payload.

Let's check it out in GHCi:

```
Prelude> runWriter (sumOfSquares 4 5)
(41,"Input parameters: 4 and 5\nSquaring first parameter: 16\nSquaring second parameter: 25\n")
```

One of the benefits of this approach in typed languages that support `Writer`
(e.g. Haskell, Scala), is that logging messages is purely functional. That is,
`sumOfSquares1` doesn't require complicated state to be initialized before
testing it. `sumOfSquares1` always returns the same value if given the same
input parameters. If the log were actually written out to the console, then we
could need some form of complicated testing harness to capture that output.

Even better, the fact that we are capturing the effect of logging in
`sumOfSquares1` is made explicit from its type signature. Compare the type
signatures of `sumOfSquares` and `sumOfSquares1`:

```
Prelude> :type sumOfSquares
sumOfSquares :: Int -> Int -> Int
Prelude> :type sumOfSquares1
sumOfSquares1 :: Int -> Int -> PureLogger Int
```

