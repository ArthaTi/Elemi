
module elemi;

import std.conv;
import std.string;
import std.algorithm;

pure @safe:

/// Escape HTML elements.
///
/// Package level: input sanitization is done automatically by the library.
package string escapeHTML(const string text) {

    if (__ctfe) {

        return text
            .replace(`<`, "&lt;")
            .replace(`>`, "&gt;")
            .replace(`&`, "&amp;")
            .replace(`"`, "&quot;")
            .replace(`'`, "&#39;");

    }

    else return text.substitute!(
        `<`, "&lt;",
        `>`, "&gt;",
        `&`, "&amp;",
        `"`, "&quot;",
        `'`, "&#39;",
    ).to!string;

}

/// Serialize attributes
package string serializeAttributes(string[string] attributes) {

    // Generate attribute text
    string attrHTML;
    foreach (key, value; attributes) {

        attrHTML ~= format!` %s="%s"`(key, value.escapeHTML);

    }

    return attrHTML;

}

/// Process the given content, sanitizing user input and passing in already created elements.
package string processContent(T...)(T content) {

    import std.range : isInputRange;

    string contentText;
    static foreach (i, Type; T) {

        // Given a string
        static if (is(Type == string) || is(Type == wstring) || is(Type == dstring)) {

            /// Escape it and add
            contentText ~= content[i].escapeHTML;

        }

        // Given a range of elements
        else static if (isInputRange!Type) {

            foreach (item; content[i]) {

                contentText ~= item;

            }

        }

        // Given an element, just add it
        else contentText ~= content[i];
    }

    return contentText;

}

/// Represents a HTML element.
///
/// Use [elem] to generate.
struct Element {

    // Commonly used elements

    /// Doctype info for HTML.
    enum HTMLDoctype = "<!DOCTYPE html>";

    /// Enables UTF-8 encoding for the document
    enum EncodingUTF8 = elem!("meta", q{
        charset="utf-8"
    });

    /// A common head element for adjusting the viewport to mobile devices.
    enum MobileViewport = elem!("meta", q{
        name="viewport"
        content="width=device-width, initial-scale=1"
    });

    package {

        /// HTML of the element.
        string html;

        /// Added at the end
        string postHTML;

    }

    pure @safe:

    package this(const string name, const string attributes = null, const string content = null) {

        auto attrHTML = attributes.dup;

        // Asserts on attributes
        debug if (attributes.length) {

            assert(attributes[0] == ' ', "The first character of attributes isn't a space");
            assert(attributes[1] != ' ', "The second character of attributes cannot be a space");

        }

        // Create the ending tag
        switch (name) {

            // Empty elements
            case "area", "base", "br", "col", "embed", "hr", "img", "input":
            case "keygen", "link", "meta", "param", "source", "track", "wbr":

                assert(content.length == 0, "Tag %s cannot have children, its content must be empty.".format(name));

                // Instead of a tag end, add a slash at the end of the beginning tag
                // Also add a space if there are any attributes
                attrHTML ~= (attrHTML ? " " : "") ~ "/";

                break;

            // Containers
            default:

                // Add the end tag
                postHTML = name.format!"</%s>";

        }

        html = format!"<%s%s>%s"(name, attrHTML, content);

    }

    unittest {

        const Element elem;
        assert(elem == "");

    }

    string toString() const {

        return html ~ postHTML;

    }

    /// Create a new element as a child
    Element add(string name, string[string] attributes = null, T...)(T content)
    if (!T.length || !is(T[0] == string[string])) {

        html ~= elem!(name, attributes)(content);
        return this;

    }

    /// Ditto
    Element add(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

        html ~= elem!(name, attrHTML)(attributes, content);
        return this;

    }

    /// Ditto
    Element add(string name, string attrHTML, T...)(T content)
    if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

        html ~= elem!(name, attrHTML)(null, content);
        return this;

    }

    /// Add a child
    Element add(T...)(T content) {

        html ~= content.processContent;
        return this;

    }

    /// Add trusted HTML code as a child.
    Element addTrusted(string code) {

        html ~= elemTrusted(code);
        return this;

    }

    ///
    unittest {

        assert(
            elem!"p".addTrusted("<b>test</b>")
            == "<p><b>test</b></p>"
        );

    }

    // Yes. This is legal.
    alias toString this;

}

/// Create a HTML element.
///
/// Params:
///     name = Name of the element.
///     attrHTML = Unsanitized attributes to insert.
///     attributes = Attributes for the element.
///     children = Children and text of the element.
/// Returns: a Element type, implictly castable to string.
Element elem(string name, string[string] attributes = null, T...)(T content)
if (!T.length || !is(T[0] == string[string])) {

    // Ensure attribute HTML is generated compile-time.
    enum attrHTML = attributes.serializeAttributes;

    return Element(name, attrHTML, content.processContent);

}

/// Ditto
Element elem(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

    import std.stdio : writeln;

    enum attrInput = attrHTML.splitter("\n")
        .map!q{a.strip}
        .filter!q{a.length}
        .join(" ");

    enum prefix = attrHTML.length ? " " : "";

    return Element(
        name,
        prefix ~ attrInput ~ attributes.serializeAttributes,
        content.processContent
    );

}

/// Ditto
Element elem(string name, string attrHTML, T...)(T content)
if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

    return elem!(name, attrHTML)(null, content);

}

///
unittest {

    import std.stdio : writeln;

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

        elem!"input"(["type": "text", "value": `"XSS!"`])
        == `<input type="text" value="&quot;XSS!&quot;" />`

    );
    assert(
        elem!("input", q{ type="text" })(["value": `"XSS!"`])
        == `<input type="text" value="&quot;XSS!&quot;" />`
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

}

/// A general example page
@system
unittest {

    import std.stdio : writeln;
    import std.base64 : Base64;

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
            elem!"p"("Hello there,",
                elem!"br", "may you want to read some of my articles?"),

            elem!("div", q{ class="article" })(
                elem!"h2"("Stuff"),
                elem!"p"("Description")
            )

        )

    );

    enum target = cast(string) Base64.decode([
        "PCFET0NUWVBFIGh0bWw+PGh0bWw+PGhlYWQ+PHRpdGxlPkFuIGV4YW1wbGUgZG9jdW",
        "1lbnQ8L3RpdGxlPjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1k",
        "ZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MSIgLz48bWV0YSBjaGFyc2V0PSJ1dG",
        "YtOCIgLz48c3R5bGU+aHRtbCwgYm9keSB7aGVpZ2h0OiAxMDAlO2ZvbnQtZmFtaWx5",
        "OiBzYW5zLXNlcmlmO3BhZGRpbmc6IDA7bWFyZ2luOiAwO30uaGVhZGVyIHtiYWNrZ3",
        "JvdW5kOiAjZjdhO2ZvbnQtc2l6ZTogMS41ZW07bWFyZ2luOiAwO3BhZGRpbmc6IDVw",
        "eDt9LmFydGljbGUge3BhZGRpbmctbGVmdDogMmVtO308L3N0eWxlPjwvaGVhZD48Ym",
        "9keT48aGVhZGVyIGNsYXNzPSJoZWFkZXIiPjxoMT5FeGFtcGxlIHdlYnNpdGU8L2gx",
        "PjwvaGVhZGVyPjxoMT5XZWxjb21lIHRvIG15IHdlYnNpdGUhPC9oMT48cD5IZWxsby",
        "B0aGVyZSw8YnIvPm1heSB5b3Ugd2FudCB0byByZWFkIHNvbWUgb2YgbXkgYXJ0aWNs",
        "ZXM/PC9wPjxkaXYgY2xhc3M9ImFydGljbGUiPjxoMj5TdHVmZjwvaDI+PHA+RGVzY3",
        "JpcHRpb248L3A+PC9kaXY+PC9ib2R5PjwvaHRtbD4=",
    ].join);

    assert(page == target);

}

// README example
unittest {

    import elemi : elem, Element;

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

}

/// Create an element from trusted HTML code.
///
/// Warning: This element cannot have children added after being created. They will be added as siblings instead.
Element elemTrusted(string code) {

    Element element;
    element.html = code;
    return element;

}

///
unittest {

    assert(elemTrusted("<p>test</p>") == "<p>test</p>");
    assert(
        elem!"p"(
            elemTrusted("<b>foo</b>bar"),
        ) == "<p><b>foo</b>bar</p>"
    );
    assert(
        elemTrusted("<b>test</b>").add("<b>foo</b>")
        == "<b>test</b>&lt;b&gt;foo&lt;/b&gt;"
    );

}

// Issue #1
unittest {

    enum Foo = elem!("p")("<unsafe>code</unsafe>");

}
