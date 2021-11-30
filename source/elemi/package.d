module elemi;

public {

    import elemi.xml;
    import elemi.html;
    import elemi.element;
    import elemi.attribute;

}

alias elem = elemi.html.elem;
alias add = elemi.html.add;


///
unittest {

    // Compile-time empty type detection
    assert(elem!"input" == "<input/>");
    assert(elem!"hr" == "<hr/>");
    assert(elem!"p" == "<p></p>");

    // Content
    assert(elem!"p"("Hello, World!") == "<p>Hello, World!</p>");

    // Compile-time attributes — variant A
    assert(

        elem!("a", [ "href": "about:blank", "title": "Destroy this page" ])("Hello, World!")

        == `<a href="about:blank" title="Destroy this page">Hello, World!</a>`

    );

    // Compile-time attributes — variant B
    assert(

        elem!("a", q{
            href="about:blank"
            title="Destroy this page" })(
            "Hello, World!"
        )
        == `<a href="about:blank" title="Destroy this page">Hello, World!</a>`

    );

    // Nesting and input sanitization
    assert(

        elem!"div"(
            elem!"p"("Hello, World!"),
            "-> Sanitized"
        )

        == "<div><p>Hello, World!</p>-&gt; Sanitized</div>"

    );

    // Sanitized user input in attributes
    assert(
        elem!"input"(
            attr("type") = "text",
            attr("value") = `"XSS!"`
        ) == `<input type="text" value="&quot;XSS!&quot;"/>`
    );

    assert(

        elem!"input"(["type": "text", "value": `"XSS!"`])
        == `<input type="text" value="&quot;XSS!&quot;"/>`

    );
    assert(
        elem!("input", q{ type="text" })(["value": `"XSS!"`])
        == `<input type="text" value="&quot;XSS!&quot;"/>`
    );

    // Alternative method of nesting
    assert(

        elem!("div", q{ style="background:#500" })
            .add!"p"("Hello, World!")
            .add("-> Sanitized")
            .add(
                " and",
                " clear"
            )

        == `<div style="background:#500"><p>Hello, World!</p>-&gt; Sanitized and clear</div>`

    );

    import std.range : repeat;

    // Adding elements by ranges
    assert(
        elem!"ul"(
            "element".elem!"li".repeat(3)
        )
        == "<ul><li>element</li><li>element</li><li>element</li></ul>"

    );

    // Significant whitespace
    assert(elem!"span"(" Foo ") == "<span> Foo </span>");

    // Also with tilde
    auto myElem = elem!"div";
    myElem ~= elem!"span"("Sample");
    myElem ~= " ";
    myElem ~= elem!"span"("Text");
    myElem ~= attr("class") = "test";

    assert(
        myElem == `<div class="test"><span>Sample</span> <span>Text</span></div>`
    );

}

/// A general example page
@system
unittest {

    import std.stdio : writeln;
    import std.base64 : Base64;
    import std.array : split, join;
    import std.algorithm : map, filter;

    enum page = Element.HTMLDoctype ~ elem!"html"(

        elem!"head"(

            elem!("title")("An example document"),

            // Metadata
            Element.MobileViewport,
            Element.EncodingUTF8,

            elem!("style")(`

                html, body {
                    height: 100%;
                   font-family: sans-serif;
                    padding: 0;
                    margin: 0;
                }
                .header {
                    background: #f7a;
                    font-size: 1.5em;
                    margin: 0;
                    padding: 5px;
                }
                .article {
                    padding-left: 2em;
                }

            `.split("\n").map!"a.strip".filter!"a.length".join),

        ),

        elem!"body"(

            elem!("header", q{ class="header" })(
                elem!"h1"("Example website")
            ),

            elem!"h1"("Welcome to my website!"),
            elem!"p"("Hello there,", elem!"br", "may you want to read some of my articles?"),

            elem!("div", q{ class="article" })(
                elem!"h2"("Stuff"),
                elem!"p"("Description")
            )

        )

    );

    enum target = cast(string) Base64.decode([
        `PCFET0NUWVBFIGh0bWw+PGh0bWw+PGhlYWQ+PHRpdGxlPkFuIGV4YW1wbGUgZG9jdW1lbnQ8L3Rp`,
        `dGxlPjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGlu`,
        `aXRpYWwtc2NhbGU9MSIvPjxtZXRhIGNoYXJzZXQ9InV0Zi04Ii8+PHN0eWxlPmh0bWwsIGJvZHkg`,
        `e2hlaWdodDogMTAwJTtmb250LWZhbWlseTogc2Fucy1zZXJpZjtwYWRkaW5nOiAwO21hcmdpbjog`,
        `MDt9LmhlYWRlciB7YmFja2dyb3VuZDogI2Y3YTtmb250LXNpemU6IDEuNWVtO21hcmdpbjogMDtw`,
        `YWRkaW5nOiA1cHg7fS5hcnRpY2xlIHtwYWRkaW5nLWxlZnQ6IDJlbTt9PC9zdHlsZT48L2hlYWQ+`,
        `PGJvZHk+PGhlYWRlciBjbGFzcz0iaGVhZGVyIj48aDE+RXhhbXBsZSB3ZWJzaXRlPC9oMT48L2hl`,
        `YWRlcj48aDE+V2VsY29tZSB0byBteSB3ZWJzaXRlITwvaDE+PHA+SGVsbG8gdGhlcmUsPGJyLz5t`,
        `YXkgeW91IHdhbnQgdG8gcmVhZCBzb21lIG9mIG15IGFydGljbGVzPzwvcD48ZGl2IGNsYXNzPSJh`,
        `cnRpY2xlIj48aDI+U3R1ZmY8L2gyPjxwPkRlc2NyaXB0aW9uPC9wPjwvZGl2PjwvYm9keT48L2h0`,
        `bWw+`,
    ].join);

    assert(page == target);

}

// README example
unittest {

    import elemi;

    auto document = Element.HTMLDoctype ~ elem!"html"(

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

    );

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

}

// UTF-32 test: generally `string` is preferred and in most cases, is required. There's one exception, content, and it
// must preserve the support.
//
// In the future, it might be preferrable to introduce support for any UTF encoding.
unittest {

    import elemi;

    auto data = cast(dchar[]) "Foo bar"d;

    assert(elem!"div"("Hello, World!"d) == "<div>Hello, World!</div>");
    assert(elem!"div"(elem!"span"("Hello, World!"d)) == "<div><span>Hello, World!</span></div>");
    assert(elem!"div"(["class": "foo bar"], "Hello, World!"d) == `<div class="foo bar">Hello, World!</div>`);
    assert(elem!"p"(data) == `<p>Foo bar</p>`);

}
