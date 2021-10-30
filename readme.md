# elemi

Elemi is a tiny, dependency free library to make writing sanitized HTML and XML a bit easier.

Check the [source code](source/elemi.d) or the [documentation](http://elemi.dpldocs.info) to learn how to use it!

```d
import elemi;

// HTML document
auto document = Element.HTMLDoctype ~ elem!"html"(

    elem!"head"(
        elem!"title"("Hello, World!"),
        Element.MobileViewport,
        Element.EncodingUTF8,
    ),

    elem!"body"(

        // All input is sanitized.
        "<Welcome to my website!>"

    ),

);

// An XML document too!
auto xml = Element.XMLDeclaration ~ elemX!("feed", `xmlns="http://www.w3.org/2005/Atom"`)(

    elemX!"title"("Example feed"),
    elemX!"subtitle"("Showcasing using elemi for generating XML"),
    elemX!"updated"("2021-10-30T20:30:00Z"),

    elemX!"entry"(
        elemX!"title"("Elemi home page"),
        elemX!("link", `href="https://github.com/Soaku/Elemi"`),
        elemX!"updated"("2021-10-30T20:30:00Z"),
        elemX!"summary"("Elemi repository on GitHub"),
        elemX!"author"(
             elemX!"Soaku",
             elemX!"soaku@samerion.com"
        )
    )

);
```
