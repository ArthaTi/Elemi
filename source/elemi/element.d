module elemi.element;

import std.string;

import elemi;
import elemi.internal;


pure @safe:


/// Represents a HTML element.
///
/// Use `elem` to generate.
struct Element {

    pure:

    // Commonly used elements
    enum {

        /// Doctype info for HTML.
        HTMLDoctype = elemX!("!DOCTYPE", "html"),

        /// XML declaration element. Uses version 1.1.
        XMLDeclaration = elemX!"?xml"(
            attr!"version" = "1.1",
            attr!"encoding" = "UTF-8",
        ),

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
    static package Element make(string tagName)()
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

    /// Add trusted XML/HTML code as a child of this node.
    /// Returns: This node, to allow chaining.
    Element addTrusted(string code) {

        content ~= code;
        return this;

    }

    void opOpAssign(string op = "~", Ts...)(Ts args) {

        // Check each argument
        static foreach (i, Type; Ts) {

            addItem(args[i]);

        }

    }

    pragma(inline, true)
    private void addItem(Type)(Type item) {

        import std.range;
        import std.traits;

        // Attribute
        static if (is(Type : Attribute)) {

            attributes ~= " " ~ item;

        }

        // Element
        else static if (is(Type : Element)) {

            content ~= item;

        }

        // String
        else static if (isSomeString!Type) {

            content ~= directive ? item : escapeHTML(item);

        }

        // Range
        else static if (isInputRange!Type) {

            // TODO Needs tests
            foreach (content; item) addItem(content);

        }

        // No idea what is this
        else static assert(false, "Unsupported element type " ~ fullyQualifiedName!Type);

    }

    unittest {

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

    string toString() const {

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
unittest {

    const collection = elems("Hello, ", elem!"span"("world!"));

    assert(collection == `Hello, <span>world!</span>`);
    assert(elem!"div"(collection) == `<div>Hello, <span>world!</span></div>`);

}

/// Create an element from trusted HTML/XML code.
///
/// Warning: This element cannot have children added after being created. They will be added as siblings instead.
Element elemTrusted(string code) {

    Element element;
    element.content = code;
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


// Other related tests

unittest {

    const Element element;
    assert(element == "");
    assert(element == elems());
    assert(element == Element());

    assert(elems("<script>") == "&lt;script&gt;");

}

unittest {

    assert(
        elem!"p".addTrusted("<b>test</b>")
        == "<p><b>test</b></p>"
    );

}

unittest {

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
