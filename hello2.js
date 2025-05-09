// hello2.js
let greeting = "Hi";
let name = "Alice";
let times = 3;

function repeatGreet() {
    let i = 0;
    while (i < times) {          // while‑loops aren’t supported, so this block is skipped
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

repeatGreet();       // will print nothing for now

