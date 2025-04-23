/// Wrappers allow defining custom HTML/XML structures that take children as content.
///
/// This module builds upon [elemi.generator](elemi.generator.html).
///
/// $(B [#examples|See examples] for usage instructions!)
///
/// History: $(LIST
///     * Introduced in Elemi 1.4.0
/// )
module elemi.wrapper;

/// Wrappers make it possible to place children inside chunks of premade HTML or XML code.
/// A wrapper is given a function — `content` in this example — which writes user-given code
/// to the output stream.
@safe unittest {
    import elemi;

    auto text = buildHTML() ~ (html) {

        // Wrapper: <span></span><div>CONTENT</div>
        // Prepends an empty span node, and wraps the content in a div.
        auto divWrapper = buildWrapper() ~ (content) {
            html.span ~ { },
            html.div ~ {
                content();
            };
        };

        // Place text content inside the wrapper
        divWrapper ~ {
            html ~ "First wrapper";
        };
        divWrapper ~ {
            html ~ "Second wrapper";
        };
    };
    assert(text == "<span></span><div>First wrapper</div><span></span><div>Second wrapper</div>");

}

/// Wrappers are especially useful when created in a function.
@safe unittest {
    import elemi;

    Wrapper section(HTML html, string title) {
        return buildWrapper() ~ (content) {
            html.div ~ {
                html.h1 ~ title;
                content();
            };
        };
    }

    auto text = buildHTML() ~ (html) {
        section(html, "Title") ~ {
            html.p ~ "Content";
        };
    };

    assert(text == "<div><h1>Title</h1><p>Content</p></div>");

}

import elemi.generator;

static if (__traits(compiles, { import core.attribute : mustuse; })) {
    import core.attribute : mustuse;
}
else {
    import std.meta : AliasSeq;
    alias mustuse = AliasSeq!();
}

/// Prepare a wrapper. Connect with a one parameter function: `buildWrapper ~ (content) { }`.
/// The argument given, `content`, is a function, which can be called to write user-provided
/// content.
///
WrapperBuilder buildWrapper() @safe {
    return WrapperBuilder();
}

/// A wrapper builder. Create using `buildWrapper`.
///
/// See [module documentation for examples](elemi.wrapper.html#examples).
@mustuse
struct WrapperBuilder {

    Wrapper opBinary(string op : "~")(void delegate(Wrapper.Generator) @safe build) @safe {
        return Wrapper(build);
    }

    SystemWrapper opBinary(string op : "~")(void delegate(Wrapper.Generator) build) @safe {
        return SystemWrapper(build);
    }

}

/// A wrapper element that can be used in `@safe` code.
@mustuse
struct Wrapper {

    alias Generator = void delegate() @safe;

    /// Function generating wrapper code.
    void delegate(Generator) @safe generator;

    /// Place XML/HTML code in this wrapper, and write it to the output stream.
    /// Params:
    ///     build = Function to write content inside the wrapper.
    void opBinary(string op : "~")(void delegate() @safe build) @safe {
        generator(build);
    }

    /// ditto
    void opBinary(string op : "~")(void delegate() @system build) @system {
        Generator trustedBuild = () @trusted => build();
        generator(trustedBuild);
    }

}

/// A wrapper element that can only be used in `@system` code.
@mustuse
struct SystemWrapper {

    alias Generator = Wrapper.Generator;

    /// Function generating wrapper code.
    void delegate(Generator) generator;

    /// Place XML/HTML code in this wrapper, and write it to the output stream.
    /// Params:
    ///     build = Function to write content inside the wrapper.
    void opBinary(string op : "~")(void delegate() @system build) @system {
        Generator trustedBuild = () @trusted => build();
        generator(trustedBuild);
    }

}

@("Wrappers can be used with @system")
@system unittest {
    import elemi.html;

    auto safeWrapper(HTML html) {
        return buildWrapper() ~ (content) @safe {
            html.h1 ~ { };
            content();
        };
    }

    auto content = buildHTML() ~ (html) @system {
        safeWrapper(html) ~ {
            html.h2 ~ { };
        };
    };

    assert(content == "<h1></h1><h2></h2>");
}

@("Wrappers themselves can be system")
@system unittest {
    import elemi.html;

    auto systemWrapper(HTML html) {
        return buildWrapper() ~ (content) @system {
            html.h1 ~ { };
            content();
        };
    }

    auto content = buildHTML() ~ (html) {
        systemWrapper(html) ~ () @safe {
            html.h2 ~ { };
        };
    };

    assert(content == "<h1></h1><h2></h2>");
}
