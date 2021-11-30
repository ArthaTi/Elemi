module elemi_old;

import std.conv;
import std.string;
import std.algorithm;


pure @safe:

version (none):


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

/// Process the given content, filtering it to attributes.
package string processAttributes(T...)(T content) {

    string attrText;
    static foreach (i, Type; T) {

        static if (is(Type : Attribute)) {

            attrText ~= " " ~ content;

        }

    }

    return attrText;

}

/// Process the given content, sanitizing user input and passing in already created elements.
package string processContent(T...)(T content)
if (!T.length || !is(T[$-1] == bool)) {

    return processContent(content, true);

}

/// Ditto
package string processContent(T...)(T content, bool escape) {

    import std.range : isInputRange;

    string contentText;
    static foreach (i, Type; T) {

        // Given an attribute, ignore it
        static if (is(Type == Attribute)) { }

        // Given a string
        else static if (is(Type == string) || is(Type == wstring) || is(Type == dstring)) {

            // Escape it and add
            contentText ~= escape
                ? content[i].escapeHTML
                : content[i];

        }

        // Given a range of elements (this is unsafe! needs a patch)
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

unittest {

    assert(processContent() == "");

}

/// Represents a HTML element.
///
/// Use [elem] to generate.
struct Element {

    // Commonly used elements

    /// Doctype info for HTML.
    enum HTMLDoctype = elemX!("!DOCTYPE", "html");

    /// XML declaration element. Uses version 1.1.
    enum XMLDeclaration = elemX!("?xml", q{ version="1.1" encoding="UTF-8" });

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

        /// If true, this is a preprocessor directive like `<!DOCTYPE>` or `<?xml >`. It's self-closing, and its content
        /// is placed within the tag itself.
        bool directive;

        /// Attribute string of the element.
        string attrs;

        /// HTML of the element.
        string html;

        /// Added at the end.
        string postHTML;

    }

    pure @safe:

    private this(string name, string attributes = null, string content = null,
        ElementType type = ElementType.startEndTag)
    do {

        // Character denoting tag end
        string trail;

        with (ElementType)
        final switch (type) {

            // Start and end tag combo
            case ElementType.startEndTag:

                // Add the end tag
                trail = ">";
                postHTML = name.format!"</%s>";
                break;

            // Create a self-closing tag
            case ElementType.emptyElementTag:

                assert(content.length == 0,
                    "Self-closing tag " ~ name ~ " cannot have children, its content must be empty."
                    ~ format!"content(%s) = \"%(%s%)\""(content.length, content));

                // Instead of a tag end, add a slash at the end of the beginning tag
                // Also add a space if there are any attributes
                trail = (attributes.length ? " " : "") ~ "/>";
                // Review note: The space is probably not necessary, but should be kept as Elemi output is not meant to
                // change for the same code.

                break;

            // XML declaration
            case ElementType.declarationTag:

                // Place everything within the tag, and add a question mark at the end
                trail = " ";
                postHTML = " ?>";
                directive = true;

                break;

            case ElementType.doctypeTag:

                // Place everything within the tag
                trail = " ";
                postHTML = ">";
                directive = true;

                break;

        }

        // Attributes in
        if (attributes.length) {

            html = format!"<%s %s%s%s"(name, attributes.stripLeft, trail, content);

        }

        // No attributes
        else html = format!"<%s%s%s"(name, trail, content);

    }

    unittest {

        const Element elem;
        assert(elem == "");

    }

    string toString() const {

        return directive
            ? html.stripRight ~ postHTML
            : html ~ postHTML;

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


        html ~= content.processContent(!directive);
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

    /// Create a new XML element as a child
    Element addX(string name, string[string] attributes = null, T...)(T content)
    if (!T.length || !is(T[0] == string[string])) {

        html ~= elemX!(name, attributes)(content);
        return this;

    }

    /// Ditto
    Element addX(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

        html ~= elemX!(name, attrHTML)(attributes, content);
        return this;

    }

    /// Ditto
    Element addX(string name, string attrHTML, T...)(T content)
    if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

        html ~= elemX!(name, attrHTML)(null, content);
        return this;

    }

    alias opOpAssign(string op = "~") = add;

    // Yes. This is legal.
    alias toString this;

}

/// Create a HTML element.
///
/// Params:
///     name = Name of the element.
///     attrHTML = Unsanitized attributes to insert.
///     attributes = Attributes for the element as an associative array mapping attribute names to their values.
///     children = Children and text of the element.
/// Returns: a Element type, implictly castable to string.
Element elem(string name, string[string] attributes = null, T...)(T content)
if (!T.length || !is(T[0] == string[string])) {

    // Overload 1: attributes from a CTFE hash map

    // Ensure attribute HTML is generated compile-time.
    enum attrHTML = attributes.serializeAttributes;

    enum type = name.isVoidTag
        ? ElementType.emptyElementTag
        : ElementType.startEndTag;

    return Element(name, attrHTML, content.processContent, type);

}

/// Ditto
Element elem(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

    // Overload 2: attributes from a CTFE attribute string and from a runtime hash map

    enum attrInput = attrHTML.splitter("\n")
        .map!q{a.strip}
        .filter!q{a.length}
        .join(" ");

    enum type = name.isVoidTag
        ? ElementType.emptyElementTag
        : ElementType.startEndTag;

    return Element(
        name,
        attrInput ~ attributes.serializeAttributes,
        content.processContent,
        type,
    );

}

/// Ditto
Element elem(string name, string attrHTML, T...)(T content)
if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

    import std.stdio;

    // Overload 3: attributes from a CTFE attribute string

    return elem!(name, attrHTML)(null, content);

}

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
        ) == `<input type="text" value="&quot;XSS!&quot;" />`
    );

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

/// Represents an attribute.
struct Attribute {

    /// Name of the attribute.
    string name;

    /// Value assigned to the attribute.
    string value;

    /// Assign a new value
    void opAssign(string newValue) {

        value = newValue;

    }

    void opAssign(string[] newValues) {

        value = newValues.join;

    }

    string toString() {

        return format!q{%s="%s"}(name, value.escapeHTML);

    }

}

/// Create an attribute
Attribute attr(string name) {
    return Attribute(name);
}

/// ditto
Attribute attr(string name)() {
    return Attribute(name);
}


unittest {

    assert(elem!"div"(
        attr("id") = "name",
        attr("class") = ["hello", "world"],
    ) == `<div id="name" class="hello world"></div>`);

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

/// Create an element from trusted HTML/XML code.
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

/// Create an XML element.
///
/// Params:
///     name = Name of the element. If the name ends with a slash, the tag will be made self-closing and will not accept
///         children.
///     attrHTML = Unsanitized attributes to insert.
///     attributes = Attributes for the element, as an.
///     children = Children and text of the element.
/// Returns: a Element type, implictly castable to string.
Element elemX(string name, string[string] attributes = null, T...)(T content)
if (!T.length || !is(T[0] == string[string])) {

    // Overload 1: attributes from a CTFE hash map

    // Ensure attribute code is generated compile-time.
    enum attrHTML = attributes.serializeAttributes;

    alias data = XMLTagData!name;

    return Element(data.name, attrHTML, content.processContent(data.sanitize), data.type);

}

/// Ditto
Element elemX(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

    // Overload 2: attributes from a CTFE attribute string and from a runtime hash map

    enum attrInput = attrHTML.splitter("\n")
        .map!q{a.strip}
        .filter!q{a.length}
        .join(" ");

    alias data = XMLTagData!name;

    return Element(
        data.name,
        attrInput ~ attributes.serializeAttributes,
        content.processContent(data.sanitize),
        data.type,
    );

}

/// Ditto
Element elemX(string name, string attrHTML, T...)(T content)
if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

    import std.stdio;

    // Overload 3: attributes from a CTFE attribute string

    return elemX!(name, attrHTML)(null, content);

}

///
unittest {

    enum xml = elemX!"xml"(
        elemX!"heading"("This is my sample document!"),
        elemX!("spacing /", q{ height="1em" }),
        elemX!"spacing /"(["height": "1em"]),
        elemX!"empty",
        elemX!"br",
        elemX!"container"
            .addX!"paragraph"("Foo")
            .addX!"paragraph"("Bar"),
    );

    assert(xml == "<xml>" ~ (
            "<heading>This is my sample document!</heading>"
            ~ `<spacing height="1em" />`
            ~ `<spacing height="1em" />`
            ~ `<empty></empty>`
            ~ `<br></br>`
            ~ "<container>" ~ (
                "<paragraph>Foo</paragraph>"
                ~ "<paragraph>Bar</paragraph>"
            ) ~ "</container>"
        ) ~ "</xml>");

}

/// Check if the given tag is a HTML5 self-closing tag.
bool isVoidTag(string tag) {

    switch (tag) {

        // Void element
        case "area", "base", "br", "col", "command", "embed", "hr", "img", "input":
        case "keygen", "link", "meta", "param", "source", "track", "wbr":

            return true;

        // Containers
        default:

            return false;

    }

}

enum ElementType {

    startEndTag,
    emptyElementTag,
    declarationTag,
    doctypeTag,

}

/// Get XML element data from Elemi tag name notation.
template XMLTagData(string tag) {

    static if (tag.startsWith("?")) {

        enum name = tag;
        enum type = ElementType.declarationTag;
        enum sanitize = false;

    }

    else static if (tag.startsWith("!")) {

        enum name = tag;
        enum type = ElementType.doctypeTag;
        enum sanitize = false;

    }

    else static if (tag.endsWith("/")) {

        enum name = tag[0..$-1].stripRight;
        enum type = ElementType.emptyElementTag;
        enum sanitize = true;

    }

    else {

        enum name = tag;
        enum type = ElementType.startEndTag;
        enum sanitize = true;

    }

}

unittest {

    void assertValid(string tag, string expectedString, ElementType expectedType)() {

        alias data = XMLTagData!tag;

        enum fmt = "wrong %s result for string \"%s\", %s vs expected %s";

        assert(data.name == expectedString, format!fmt("string", tag, data.name, expectedString));
        assert(data.type == expectedType,   format!fmt("type", tag, data.type, expectedType));

    }

    with (ElementType) {

        assertValid!("br",   "br",  startEndTag);
        assertValid!("br ",  "br ", startEndTag);
        assertValid!("br /", "br",  emptyElementTag);
        assertValid!("br/",  "br",  emptyElementTag);

        assertValid!("myFancyTag",    "myFancyTag", startEndTag);
        assertValid!("myFancyTag /",  "myFancyTag", emptyElementTag);
        assertValid!("myFancyTäg /",  "myFancyTäg", emptyElementTag);

        assertValid!("?br", "?br", declarationTag);
        assertValid!("!br", "!br", doctypeTag);

    }

}

// Issue #1
unittest {

    enum Foo = elem!("p")("<unsafe>code</unsafe>");

}

unittest {

    assert(elemX!"p" == "<p></p>");
    assert(elemX!"p /" == "<p/>");
    assert(elemX!("!DOCTYPE", "html") == "<!DOCTYPE html>");
    assert(Element.HTMLDoctype == "<!DOCTYPE html>");
    assert(elemX!("!ATTLIST", "pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"!ATTLIST"("pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"!ATTLIST".add("pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"?xml" == "<?xml ?>");
    assert(elemX!("?xml", q{ version="1.1" encoding="UTF-8" }) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml"(`version="1.1" encoding="UTF-8"`) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml".add(`version="1.1" encoding="UTF-8"`) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(Element.XMLDeclaration == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml"(["version": "1.1"]).addTrusted(`encoding="UTF-8"`)
        == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?php" == "<?php ?>");
    assert(elemX!"?php"(`echo "Hello, World!";`) == `<?php echo "Hello, World!"; ?>`);
    assert(elemX!"?="(`"Hello, World!"`) == `<?= "Hello, World!" ?>`);
    // ↑ I will not special-case this to remove spaces.

    auto php = elemX!"?php";
    php.add(`$target = "World!";`);
    php.add(`echo "Hello, " . $target;`);
    assert(php == `<?php $target = "World!";echo "Hello, " . $target; ?>`);

}
