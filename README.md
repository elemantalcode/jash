# jash – a JavaScript‑ish interpreter in BASH

> I didn’t build this because we **should**. We built it because we **could** – and because it was fun.

`jash.sh` is a single Bash script that can execute a very small (and growing!) subset of JavaScript: variable declarations, `console.log`, arithmetic comparisons, simple string concatenation, `if … else` blocks, and zero-argument function definitions/calls. That’s it – no promises, no guarantees, definitely no production support.

---

## Quick Start

```bash
chmod +x jash.sh          # make it executable
DEBUG=false ./jash.sh test.js   # run the first demo (quiet mode)
DEBUG=true  ./jash.sh hello2.js # run the second demo with verbose tracing
```

The **`DEBUG`** environment variable (default `true`) controls the flood of `DEBUG:` lines that show the script’s internal decision‑making.

---

## Demo Scripts

### 1 · `test.js`

```js
// test.js
let x = 10;
let y = 5;
let z = "Hello";
let w = "World";

if (x > y) {
    console.log(z + " " + w);
    console.log(x + y);
}

function myFunc() {
    let a = 20;
    console.log(a);
}

myFunc();
```

**Expected output**

```text
Hello World
15
20
```

### 2 · `hello2.js`

```js
let greeting = "Hi";
let name = "Alice";
let times = 3;

function repeatGreet() {
    let i = 0;
    while (i < times) {        // not implemented yet → loop skipped
        console.log(greeting + ", " + name + "!");
        i = i + 1;
    }
}

if (times > 1) {
    console.log(greeting + ", " + name + "! (once)");
    console.log(greeting + ", " + name + "! (twice)");
} else {
    console.log(greeting + ", " + name + "!");
}

repeatGreet();
```

**Expected output**

```text
Hi, Alice! (once)
Hi, Alice! (twice)
```

Because `while` loops aren’t implemented (yet!), `repeatGreet()` prints nothing – a neat smoke‑test for when loops eventually land.

---

## Turning the Knobs

* **Enable/disable debug**

  ```bash
  DEBUG=false ./jash.sh yourScript.js   # quiet mode
  DEBUG=true  ./jash.sh yourScript.js   # very chatty
  ```
* **Supported features**: `let`/`var`, basic math/comparison, string concatenation with `+`, `if … else`, zero‑arg function calls.
* **Unsupported** (for now): loops (`while`, `for`), `else if`, arrays, objects, everything fancy.

---

## Why Bash?

* It was a light-hearted "what if" challenge.
* Bash’s crazy quoting rules make regex parsing surprisingly educational.
* It fits in a single shell script you can drop on almost *any* Unix box.
* Part of the "in roughly 100 lines of BASH" challange, created for myself, because sometimes, Perl, Python, Java, C, Golang is just not as "fun".

*Is it a good idea?* Absolutely not. Is it fun? Absolutely yes.

---

## Contributing / Extending

Pull requests welcome if you’d like to add a tiny new feature (loops are the next obvious milestone). Keep it under 200 lines, keep it POSIX-ish, and keep it playful.

---

© 2025 — hack for laughs, not for mission-critical workloads.

