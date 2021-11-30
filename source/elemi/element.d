module elemi.element;

import std.string;

import elemi.xml;
import elemi.internal;


pure @safe:


/// A collection to hold multiple elements next to each other without a wrapper element.
enum elems = Element();

/// Represents a HTML element.
///
/// Use [elem] to generate.
struct Element {

    pure:

    // Commonly used elements
    enum {

        /// Doctype info for HTML.
        HTMLDoctype = elemX!"!DOCTYPE"("html"),

        /// XML declaration element. Uses version 1.1.
        XMLDeclaration = elemX!"?xml"(
            attr!"version" = "1.1",
            attr!"encoding" = "UTF-8",
        ),

        /// Enables UTF-8 encoding for the document
        EncodingUTF8 = elemX!"meta"(
            attr!"charset" = "utf-8",
        ),

        /// A common head element for adjusting the viewport to mobile devices.
        MobileViewport = elemX!"meta"(
            attr!"name" = "viewport",
            attr!"content" = "width=device-width, initial-scale=1"
        ),

    }

    package {

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
            that.endTag = "?>";

        }

        // Declaration
        else static if (tagName[0] == '!') {

            that.startTag = format!"<%s"(tagName);
            that.trail = " ";
            that.endTag = ">";

        }

        else {

            that.startTag = format!"<%s"(tagName);
            that.trail = ">";
            that.endTag = format!"</%s>"(tagName);

        }

        return that;

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

            content ~= escapeHTML(item);

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

        void test(T)(T thing, string expectedResult) {

            Element elem;
            elem.addItem(thing);
            assert(elem == expectedResult);

        }

        test(`"Insecure" string`, "&quot;Insecure&quot; string");
        test(Element.make!"div", "<div></div>");
        test(Element.make!"?xml", "<?xml ?>");

        Element outer;
        outer.addItem(Element.make!"div");
        outer.addItem(`<XSS>`);
        test(outer, "<div></div>&lt;XSS&gt;");

    }

    string toString() const {

        import std.conv;

        return startTag ~ attributes ~ trail ~ content ~ endTag;

    }

    alias toString this;

}
