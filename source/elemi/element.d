module elemi.element;

import std.string;

import elemi;
import elemi.internal;

/// Represents a HTML element.
///
/// Use `elem` to generate.
struct Element {

    // Commonly used elements
    enum {

        /// Doctype info for HTML.
        HTMLDoctype = elemX!("!DOCTYPE", "html"),

        /// XML declaration element. Uses version 1.1.
        XMLDeclaration1_1 = elemX!"?xml"(
            attr!"version" = "1.1",
            attr!"encoding" = "UTF-8",
        ),
        XMLDeclaration1_0 = elemX!"?xml"(
            attr!"version" = "1.0",
            attr!"encoding" = "UTF-8",
        ),
        XMLDeclaration = XMLDeclaration1_1,

        /// Enables UTF-8 encoding for the document
        EncodingUTF8 = elemH!"meta"(
            attr!"charset" = "utf-8",
        ),

        /// A common head element for adjusting the viewport to mobile devices.
        MobileViewport = elemH!"meta"(
            attr!"name" = "viewport",
            attr!"content" = "width=device-width, initial-scale=1"
        ),

    }

    package {

        bool directive;
        string startTag;
        string attributes;
        string trail;
        string content;
        string endTag;

    }

    /// Create the tag.
    static package Element make(string tagName)() pure @safe
    in(tagName.length != 0, "Tag name cannot be empty")
    do {

        Element that;

        // Self-closing tag
        static if (tagName[$-1] == '/') {

            // Enforce CTFE
            enum startTag = format!"<%s"(tagName[0..$-1].stripRight);

            that.startTag = startTag;
            that.trail = "/>";

        }

        // XML tag
        else static if (tagName[0] == '?') {

            that.startTag = format!"<%s"(tagName);
            that.trail = " ";
            that.endTag = " ?>";
            that.directive = true;

        }

        // Declaration
        else static if (tagName[0] == '!') {

            that.startTag = format!"<%s"(tagName);
            that.trail = " ";
            that.endTag = ">";
            that.directive = true;

        }

        else {

            that.startTag = format!"<%s"(tagName);
            that.trail = ">";
            that.endTag = format!"</%s>"(tagName);

        }

        return that;

    }

    /// Check if the element allows content.
    bool acceptsContent() const pure @safe {

        return endTag.length || !startTag.length;

    }

    /// Add trusted XML/HTML code as a child of this node.
    /// Returns: This node, to allow chaining.
    Element addTrusted(string code) pure @safe {

        assert(acceptsContent, "This element doesn't accept content");

        content ~= code;
        return this;

    }

    void opOpAssign(string op = "~", Ts...)(Ts args) {

        import std.meta;

        // Interpolate arguments
        static if (withInterpolation) {

            template inString(size_t index) {
                static if (is(Ts[index] == InterpolationHeader))
                    enum inString = true;
                else static if (is(Ts[index] == InterpolationFooter))
                    enum inString = false;
                else static if (index == 0)
                    enum inString = false;
                else
                    enum inString = inString!(index - 1);
            }

            static foreach (i, Type; Ts) {
                static if (!is(Type == InterpolationFooter)) {
                    addItem!(inString!i)(args[i]);
                }
            }
        }

        // Check each argument
        else {
            static foreach (i, Type; Ts) {
                addItem(args[i]);
            }
        }

    }

    @safe unittest {
        assert(elem!"p"(i"Hello, $(123)!", " ... ", i"Hello, $(123)!") ==
            "<p>Hello, 123! ... Hello, 123!</p>");
        assert(!__traits(compiles, elem!"p"(123)));
        assert(!__traits(compiles, elem!"p"(i"Hello ", 123)));

        assert(elem!"p"(i"Hello, $(elem!"b"("Woo!"))~") ==
            "<p>Hello, <b>Woo!</b>~</p>");
    }

    private void addItem(bool allowInterpolation = false, Type)(Type item) {

        import std.range;
        import std.traits;

        // Element
        static if (is(Type : Element)) {

            assert(acceptsContent, "This element doesn't accept content");
            content ~= item;

        }

        // Attribute
        else static if (is(Type : Attribute)) {

            attributes ~= " " ~ item;

        }

        // String
        else static if (isSomeString!Type) {

            addText(item);

        }

        // Range
        else static if (isInputRange!Type && __traits(compiles, addItem(item.front))) {

            // TODO Needs tests
            foreach (content; item) addItem(content);

        }

        // Perform interpolation
        else static if (allowInterpolation) {

            addText(item);

        }

        // No idea what is this
        else static assert(false, "Unsupported element type " ~ fullyQualifiedName!Type);

    }

    private void addText(T)(T item) {

        import std.conv;

        assert(acceptsContent, "This element doesn't accept content");
        content ~= directive ? item.to!string : escapeHTML(item.to!string);

    }

    pure @safe unittest {

        void test(T...)(T things, string expectedResult) {

            Element elem;
            elem ~= things;
            assert(elem == expectedResult, format!"wrong result: `%s`"(elem.toString));

        }

        test(`"Insecure" string`, "&quot;Insecure&quot; string");
        test(Element.make!"div", "<div></div>");
        test(Element.make!"?xml", "<?xml ?>");
        test(Element.make!"div", `<XSS>`, "<div></div>&lt;XSS&gt;");

        test(["hello, ", "<XSS>!"], "hello, &lt;XSS&gt;!");

    }

    string toString() const pure @safe {

        import std.conv;

        // Special case: prevent space between trail and endTag in directives
        if (directive && content == null) {

            return startTag ~ attributes ~ content ~ endTag;

        }

        return startTag ~ attributes ~ trail ~ content ~ endTag;

    }

    alias toString this;

}

/// Creates an element to function as an element collection to place within other elements. This is functionally
/// equivalent to a regular element, server-side, but is transparent for the rendered document.
Element elems(T...)(T content) {

    Element element;
    element ~= content;
    return element;

}

///
pure @safe unittest {

    const collection = elems("Hello, ", elem!"span"("world!"));

    assert(collection == `Hello, <span>world!</span>`);
    assert(elem!"div"(collection) == `<div>Hello, <span>world!</span></div>`);

}

/// Create an element from trusted HTML/XML code.
///
/// Warning: This element cannot have children added after being created. They will be added as siblings instead.
Element elemTrusted(string code) pure @safe {

    Element element;
    element.content = code;
    return element;

}

///
pure @safe unittest {

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


// Other related tests

pure @safe unittest {

    const Element element;
    assert(element == "");
    assert(element == elems());
    assert(element == Element());

    assert(elems("<script>") == "&lt;script&gt;");

}

pure @safe unittest {

    assert(
        elem!"p".addTrusted("<b>test</b>")
        == "<p><b>test</b></p>"
    );

}

pure @safe unittest {

    auto foo = ["foo", "<bar>", "test"];
    auto bar = [
        elem!"span"("Hello, "),
        elem!"strong"("World!"),
    ];

    assert(elem!"div"(foo) == "<div>foo&lt;bar&gt;test</div>");
    assert(elem!"div"(bar) == "<div><span>Hello, </span><strong>World!</strong></div>");

    assert(elem!"div".add(foo) == "<div>foo&lt;bar&gt;test</div>");
    assert(elem!"div".addTrusted(foo.join) == "<div>foo<bar>test</div>");
    assert(elem!"div".add(bar) == "<div><span>Hello, </span><strong>World!</strong></div>");

}

pure @safe unittest {

    auto attributes = [
        attr("rel") = "me",
        attr("href") = "https://samerion.com",
    ];

    assert(elem!"meta"(
        attributes,
        attr("x") = "woo",
    ) == `<meta rel="me" href="https://samerion.com" x="woo"/>`);

}
