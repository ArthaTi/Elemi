/// This module provides syntax for generating HTML and XML documents from inside of D,
/// including control flow.
module elemi.generator;

import std.meta;
import std.range;
import std.string;
import std.functional;

import elemi.html;
import elemi.element;
import elemi.attribute;

static if (withInterpolation) {
    import core.interpolation;
}

/// Elements are created using a tilde, followed by curly braces. This syntax is called an
/// **element block**.
@safe unittest {
    string output = buildDocument() ~ {
        HTML.div ~ {
            HTML.span ~ { };
        };
    };
    assert(output == "<div><span></span></div>");
}

/// Instead of a block, you can follow an element with a string to specify text content.
@safe unittest {
    string output = buildDocument() ~ {
        HTML.p ~ "Hello, World!";
    };
    assert(output == "<p>Hello, World!</p>");
}

/// You can add attributes to an element using the [Tag.attr] method.
@safe unittest {
    string output = buildDocument() ~ {
        HTML.a.attr("href", "https://example.com") ~ "Visit my website!";
    };
    assert(output == `<a href="https://example.com">Visit my website!</a>`);
}

/// Common HTML attributes are available through methods.
@safe unittest {
    string output = buildDocument() ~ {
        HTML.div.id("my-div") ~ { };
        HTML.div.classes("one", "two", "three") ~ { };
        HTML.a.href("https://example.com") ~ { };
    };
    assert(output == `<div id="my-div"></div>`
        ~ `<div class="one two three"></div>`
        ~ `<a href="https://example.com"></a>`);
}

/// Generate HTML tags with code.
@safe unittest {
    string output = buildDocument() ~ {
        HTML.ul ~ {
            foreach (item; ["1", "2", "3"]) {
                HTML.li ~ item;
            }
        };
    };
    assert(output == `<ul><li>1</li><li>2</li><li>3</li></ul>`);
}

/// Omit the attribute to append text.
@safe unittest {
    string output = buildDocument() ~ {
        HTML ~ "Hello, ";
        HTML.strong ~ "World!";
    };
    assert(output == "Hello, <strong>World!</strong>");
}

/// All HTML content is automatically escaped.
@safe unittest {
    string output = buildDocument() ~ {
        HTML ~ "<script>alert('fool!')</script>";
        HTML.input.attr("value", "\" can't quit me") ~ { };
        HTML.div.classes("classes are <no exception>") ~ { };
    };

    assert(output == `&lt;script&gt;alert(&#39;fool!&#39;)&lt;/script&gt;`
        ~ `<input value="&quot; can&#39;t quit me"/>`
        ~ `<div class="classes are &lt;no exception&gt;"></div>`);
}

static if (withInterpolation) {
    /// Interpolated expression strings, aka istrings, are supported.
    unittest {
        string output = buildDocument() ~ {
            const user = "<user>";
            HTML ~ i"Hello $(user)";
            HTML.div ~ i"Hello $(user)";
            HTML.div.attr("name", i"$(user)") ~ { };
            HTML.a.href(i"https://example.com/$(user)") ~ { };
        };
        assert(output == `Hello &lt;user&gt;`
            ~ `<div>Hello &lt;user&gt;</div>`
            ~ `<div name="&lt;user&gt;"></div>`
            ~ `<a href="https://example.com/&lt;user&gt;"></a>`);
    }
}

/// To reduce verbosity, you can use the [`with`
/// statement](https://dlang.org/spec/statement.html#WithStatement).
@safe unittest {
    with (HTML) {
        string output = buildDocument() ~ {
            div.id("my-div") ~ {
                p ~ "Hello, World!";
            };
        };
    }
}

static if (__traits(compiles, { import core.attribute : mustuse; })) {
    import core.attribute : mustuse;
}
else {
    alias mustuse = AliasSeq!();
}

@safe:

private static void delegate(string fragment) @safe elementOutput;

/// Write XML or HTML elements to an output range.
/// Params:
///     range = Output range to write the output to. If not given, the builder will return
///         a string.
/// Returns:
///     A struct that accepts an element block `~ { }` and writes the content to the output
///     range.
auto buildDocument(T)(ref T range)
if (isOutputRange!(T, char))
do {
    return DocumentBuilder!(fragment => put(range, fragment))();
}

/// Write XML or HTML elements to a string or [Element].
///
/// Returns:
///     A struct that accepts an element block `~ { }` and writes the content to a string.
DocumentBuilder!() buildDocument() @safe {
    return DocumentBuilder!()();
}

/// If no arguments are specified, `buildDocument()` will output to a string. Under the hood,
/// it uses an [std.array.Appender].
@safe unittest {
    string stringOutput = buildDocument() ~ {
        HTML.p ~ "Hello!";
    };

    Appender!string rangeOutput;
    buildDocument(rangeOutput) ~ {
        HTML.p ~ "Hello!";
    };
    assert(stringOutput == rangeOutput[]);
}

/// This special struct writes XML or HTML elements through a predicate function. It accepts an
/// element block `~ { }` as input.
///
/// The predicate can be used with `std.range.input` to write content to an input range.
@mustuse
struct DocumentBuilder(alias fun) {

    void opBinary(string op : "~")(void delegate() @safe build) {
        elementOutput = (string fragment) => unaryFun!fun(fragment);
        scope (exit) elementOutput = null;
        build();
    }

    void opBinary(string op : "~")(void delegate() @system build) {
        elementOutput = (string fragment) => unaryFun!fun(fragment);
        scope (exit) elementOutput = null;
        build();
    }

}

/// This special struct writes XML or HTML elements to a string.
///
/// The resulting string is wrapped in an [Element] so it is recognized as a valid element
/// by other parts of the Elemi API.
@mustuse
struct DocumentBuilder() {

    Element opBinary(string op : "~")(void delegate() @safe build) @safe {
        Appender!string output;
        elementOutput = (string fragment) => output ~= fragment;
        scope (exit) elementOutput = null;
        build();
        return elemTrusted(output[]);
    }

    Element opBinary(string op : "~")(void delegate() @system build) @safe {
        Appender!string output;
        elementOutput = (string fragment) => output ~= fragment;
        scope (exit) elementOutput = null;
        build();
        return elemTrusted(output[]);
    }

}

/// Generic XML tag.
@mustuse
struct Tag {

    /// Name of this HTML tag.
    string tagName;

    /// If true, this is a "self-closing" tag. No child nodes or text can be added.
    bool isSelfClosing;

    /// The tag can be marked as self-closing so it does not generate content nor an end tag.
    unittest {
        auto normal = buildDocument() ~ {
            Tag("a") ~ { };
        };
        auto selfClosing = buildDocument() ~ {
            Tag("a").makeSelfClosing() ~ { };
        };

        assert(normal == "<a></a>");
        assert(selfClosing == "<a/>");
    }

    unittest {
        auto normal = buildDocument() ~ {
            Tag("a").attr("k", "k") ~ { };
        };
        auto selfClosing = buildDocument() ~ {
            Tag("a").attr("k", "k").makeSelfClosing() ~ { };
        };

        assert(normal == `<a k="k"></a>`);
        assert(selfClosing == `<a k="k"/>`);
    }

    /// True if an attribute has been added to this tag.
    ///
    /// This changes whether the whole opening tag will be added when content starts (no
    /// attributes), or just the right bracket (with attributes).
    bool withAttributes;

    /// Returns:
    ///     The same tag, but marked using [withAttributes]. This should be used to return from
    ///     attribute-adding methods.
    Tag attributed() const @safe {
        return Tag(tagName, isSelfClosing, true);
    }

    /// Returns:
    ///     This tag, but edited to be self-closing.
    Tag makeSelfClosing() const @safe {
        return Tag(tagName, true, withAttributes);
    }

    void opBinary(string op : "~")(typeof(null)) @safe {
        begin();
        end();
    }

    void opBinary(string op : "~")(string text) @safe {
        begin();
        if (!isSelfClosing) {
            pushElementText(text);
            end();
        }
    }

    static if (withInterpolation)
    void opBinary(string op : "~", Ts...)(InterpolationHeader, Ts text) {
        begin();
        if (!isSelfClosing) {
            pushElementText(text);
            end();
        }
    }

    void opBinary(string op : "~")(void delegate() @safe builder) @safe {
        begin();
        if (!isSelfClosing) {
            builder();
            end();
        }
    }

    void opBinary(string op : "~")(void delegate() @system builder) @system {
        begin();
        if (!isSelfClosing) {
            builder();
            end();
        }
    }

    /// Add an attribute to the element.
    /// Params:
    ///     name  = Name of the attribute.
    ///     value = Value for the attribute. Supports istrings.
    /// Returns:
    ///     Tag builder.
    Tag attr(string name, string value) @safe {
        return attr(Attribute(name, value));
    }

    /// ditto
    static if (withInterpolation) {
        Tag attr(Ts...)(string name, InterpolationHeader, Ts value) @safe {
            beginAttributes();
            pushElementMarkup(" ");
            pushElementMarkup(name);
            pushElementMarkup(`="`);
            pushElementText(value);
            pushElementMarkup(`"`);
            return attributed;
        }
    }

    /// Add a prepared set of attributes to the element.
    /// Params:
    ///     attributes = Attributes to add to the element.
    /// Returns:
    ///     Tag builder.
    Tag attr(Attribute[] attributes...) @safe {
        beginAttributes();
        foreach (attribute; attributes) {
            pushElementMarkup(" ");
            pushElementMarkup(attribute.name);
            pushElementMarkup(`="`);
            pushElementText(attribute.value);
            pushElementMarkup(`"`);
        }
        return attributed;
    }

    void begin() @safe {
        if (tagName is null) return;
        if (!withAttributes) {
            pushElementMarkup("<");
            pushElementMarkup(tagName);
        }
        if (isSelfClosing) {
            pushElementMarkup("/>");
        }
        else {
            pushElementMarkup(">");
        }
    }

    void beginAttributes() @safe {
        if (tagName is null) return;
        if (!withAttributes) {
            pushElementMarkup("<");
            pushElementMarkup(tagName);
        }
    }

    void end() @safe {
        if (tagName is null) return;
        if (!isSelfClosing) {
            pushElementMarkup("</");
            pushElementMarkup(tagName);
            pushElementMarkup(">");
        }
    }

}

/// Low-level function to write elements into current document context. Raw markup can be used,
/// i.e. ("<b>Hi</b>")` will include unescaped HTML code.
///
/// If escaping is desired, try [pushElementText].
///
/// Params:
///     content = Markup to output.
void pushElementMarkup(string content) @safe {
    assert(elementOutput,
        "No Elemi context is currently active. Try prepending the document with "
        ~ "`buildDocument() ~`.");
    elementOutput(content);
}

/// Low-level function to write escaped text.
/// Params:
///     content = Content to write. Interpolated expression strings (istrings) are supported.
void pushElementText(string content) {
    while (!content.empty) {
        const nextMarkup = content.indexOfAny(`<>&"'`);

        // No markup remains to be escaped
        if (nextMarkup == -1) {
            pushElementMarkup(content);
            return;
        }

        // Escape the character
        else {
            pushElementMarkup(content[0 .. nextMarkup]);
            pushElementMarkup(content[nextMarkup].escapeHTMLCharacter);
            content = content[nextMarkup + 1 .. $];
        }

    }
}

/// ditto
void pushElementText(Ts...)(Ts content) {

    import std.format.write;

    auto writer = EscapingElementWriter();

    foreach (item; content) {
        formattedWrite!"%s"(writer, item);
    }

}

/// This output range writes escapes the text it writes.
struct EscapingElementWriter {

    void put(char content) {
        if (auto escaped = escapeHTMLCharacter(content)) {
            pushElementMarkup(escaped);
        }
        else {
            immutable(char)[1] c = content;
            pushElementMarkup(c[]);
        }
    }

    void put(string content) {
        pushElementText(content);
    }

}

/// Escape an ASCII character using HTML escape codes.
/// Returns:
///     A corresponding HTML escape code, or null if there isn't one.
private string escapeHTMLCharacter(char ch) {
    switch (ch) {
        case '<':  return "&lt;";
        case '>':  return "&gt;";
        case '&':  return "&amp;";
        case '"':  return "&quot;";
        case '\'': return "&#39;";
        default:   return null;
    }
}
