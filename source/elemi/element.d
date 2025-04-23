/// This module holds the [Element] type, used and emitted by [elemi.html](elemi.html.html)
/// and [elemi.xml](elemi.xml.html).
module elemi.element;

import std.string;

import elemi;
import elemi.internal;

/// Represents an HTML element. Elements can be created using [elem].
///
/// `Element` implicitly converts to a string, but when passed to `elem`, it will be recognized
/// as HTML code, and it will not be escaped.
///
/// ---
/// Element e1 = elem!"div"();
/// string  e2 = elem!"div"();
/// elems(e1);  // <div></div>
/// elems(e2);  // &lt;div&gt;&lt;/div&gt;
/// ---
///
/// `Element` does not store its data in a structured manner, so its attributes and content cannot
/// be read without using an XML parser. It does, however, have the capability of inserting
/// attributes and content at runtime:
///
/// ---
/// Element e = elem!"div"();
/// e ~= attr("class") = "one";
/// e ~= elem!"div"("two");
/// e ~= "three";
/// ---
struct Element {

    /// [Document type declaration](https://en.wikipedia.org/wiki/Document_type_declaration) for
    /// HTML, used to enable standards mode in browsers.
    enum HTMLDoctype = elemX!("!DOCTYPE", "html");

    /// Prepend a document type declaration to your document.
    pure @safe unittest {
        auto html = elems(
            Element.HTMLDoctype,
            elem!"html"(),
        );

        assert(html == "<!DOCTYPE html><html></html>");
    }

    /// XML declaration element. Uses version 1.1.
    enum XMLDeclaration1_1 = elemX!"?xml"(
        attr!"version" = "1.1",
        attr!"encoding" = "UTF-8",
    );

    /// XML declaration element. Uses version 1.0.
    enum XMLDeclaration1_0 = elemX!"?xml"(
        attr!"version" = "1.0",
        attr!"encoding" = "UTF-8",
    );

    /// Default XML declaration element, uses version 1.1.
    alias XMLDeclaration = XMLDeclaration1_1;

    /// Enables UTF-8 encoding for the document.
    enum EncodingUTF8 = elemH!"meta"(
        attr!"charset" = "utf-8",
    );

    /// A common head element for adjusting the viewport to mobile devices.
    enum MobileViewport = elemH!"meta"(
        attr!"name" = "viewport",
        attr!"content" = "width=device-width, initial-scale=1"
    );

    package {

        bool directive;
        string startTag;
        string attributes;
        string trail;
        string content;
        string endTag;

    }

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

    /// Returns:
    ///     True if the element allows content.
    ///
    ///     To accept content, the element must have an end tag.
    ///     In HTML, void elements such as `elemH!"input"` do not have one, and thus, cannot have
    ///     content. In XML, a self closing tag (marked with `/`) `elemX!"tag/"` also cannot
    ///     have content.
    bool acceptsContent() const pure @safe {

        return endTag.length || !startTag.length;

    }

    /// Add trusted XML/HTML code as a child of this node.
    /// See_Also:
    ///     [elemTrusted] to construct an `Element` from XML/HTML source code.
    /// Params:
    ///     code = Raw XML/HTML code to insert into the element.
    /// Returns:
    ///     This node, to allow chaining.
    Element addTrusted(string code) pure @safe {

        assert(acceptsContent, "This element doesn't accept content");

        content ~= code;
        return this;

    }

    /// Append content to this node.
    ///
    /// Params:
    ///     args = Content to append. The content can include: $(LIST
    ///       * A child `Element`,
    ///       * An [Attribute] for this element
    ///       * An [i-string](https://dlang.org/spec/istring.html)
    ///       * A regular [string]
    ///     )
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

    /// Convert the element to a string.
    ///
    /// If `Element` is passed to something that expects a `string`, it will be casted implicitly.
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

/// Creates an element to function as an element collection to place within other elements.
/// For Elemi, it acts like an element, so it can accept child nodes, and can be appended to,
/// but it is invisible for the generated document.
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
/// Warning: This element cannot have children added after being created. They will be added as
/// siblings instead.
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
