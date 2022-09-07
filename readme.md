# elemi

Elemi is a tiny, dependency free library to make writing sanitized HTML and XML a bit easier.

Check the [source code](source/elemi.d) or the [documentation](http://elemi.dpldocs.info) to learn how to use it!

```d
import elemi;
import std.conv;

// HTML document
auto document = text(
    Element.HTMLDoctype,
    elem!"html"(

        elem!"head"(
            elem!"title"("Hello, World!"),
            Element.MobileViewport,
            Element.EncodingUTF8,
        ),

        elem!"body"(
            attr("class") = ["home", "logged-in"],

            elem!"main"(

                elem!"img"(
                    attr("src") = "/logo.png",
                    attr("alt") = "Website logo"
                ),

                // All input is sanitized.
                "<Welcome to my website!>"

            )

        ),

    ),

);

// XML document
// You may `import elemi.xml` if you prefer to type `elem` over `elemX`
auto xml = text(
    Element.XMLDeclaration1_0,
    elemX!"feed"(

        attr("xmlns") = "http://www.w3.org/2005/Atom",

        elemX!"title"("Example feed"),
        elemX!"subtitle"("Showcasing using elemi for generating XML"),
        elemX!"updated"("2021-10-30T20:30:00Z"),

        elemX!"entry"(
            elemX!"title"("Elemi home page"),
            elemX!"link"(
                attr("href") = "https://git.samerion.com/Artha/Elemi",
            ),
            elemX!"updated"("2021-10-30T20:30:00Z"),
            elemX!"summary"("Elemi repository on GitHub"),
            elemX!"author"(
                 elemX!"Artha",
                 elemX!"artha@samerion.com"
            )
        )

    )

);
```
