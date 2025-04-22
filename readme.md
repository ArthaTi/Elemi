# elemi

Elemi is a tiny, dependency free library to make writing sanitized HTML and XML a bit easier.

Visit the [online documentation](https://elemi.dpldocs.dlang.org/elemi.html) for reference.

## New syntax

As of 1.4.0, Elemi comes with two different flavors: the new one (`elemi.generator`), and the old
one (`elemi.element`). Using the new syntax, HTML is output directly to a range or a string,
making it more lightweight and faster. Additionally, it allows for control flow alongside content.

```d
import elemi;

auto document = buildHTML() ~ (html) {
    html ~ Element.HTMLDoctype;
    html.html ~ {
        html.head ~ {
            html.title ~ "Hello, World!";
            html ~ Element.MobileViewport;
            html ~ Element.EncodingUTF8;
        };
        html.body.classes("home", "logged-in") ~ {
            html.main ~ {

                html.img
                    .attr("src", "/logo.png")
                    .attr("alt", "Website logo") ~ { };

                // All input is sanitized
                html.p ~ {
                    html ~ "My <hobbies>:";
                };

                // Control flow is allowed
                html.ul ~ {
                    foreach (item; ["Web development", "Music", "Trains"]) {
                        html.li ~ item;
                    }
                };

                // i-strings are supported
                html.p ~ i"1+2 is $(1+2).";
            };
        };
    };
};
```
For more information on the new syntax, see [`elemi.generator` in the online
documentation](https://elemi.dpldocs.dlang.org/elemi.generator.html)

## Old syntax

The "classic" syntax is still available. It is simpler and easier to learn, but more verbose and
slower.

Read more about the old syntax through
[`elemi.element`](https://elemi.dpldocs.dlang.org/elemi.element.html)


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
