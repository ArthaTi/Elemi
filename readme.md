# elemi

Elemi is a tiny, dependency free library to make writing sanitized HTML a bit easier.

Check the [source code](source/elemi.d) or the [documentation](http://elemi.dpldocs.info) to learn how to use it!

```d
import elemi;

auto document = Element.HTMLDoctype ~ elem!"html"(

    elem!"head"(
        elem!"title"("Hello, World!"),
        Element.MobileViewport,
    ),

    elem!"body"(

        // All input is sanitized.
        "<Welcome to my website!>"

    ),

);
```
