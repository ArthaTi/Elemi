/// Wrappers allow defining custom HTML/XML structures that take children as content.
module elemi.wrapper;

/// Wrappers make it possible to place children inside chunks of premade HTML or XML code.
@safe unittest {
    import elemi;

    auto divWrapper = buildWrapper() ~ (content) {
        HTML.span ~ { },
        HTML.div ~ {
            content();
        };
    };
    auto text = buildDocument() ~ {
        divWrapper ~ {
            HTML ~ "My text";
        };
    };
    assert(text == "<span></span><div>My text</div>");

}

/// Wrappers are especially useful when created in a function.
@safe unittest {
    import elemi;

    Wrapper section(string title) {
        return buildWrapper() ~ (content) {
            HTML.div ~ {
                HTML.h1 ~ title;
                content();
            };
        };
    }

    auto text = buildDocument() ~ {
        section("Title") ~ {
            HTML.p ~ "Content";
        };
    };

    assert(text == "<div><h1>Title</h1><p>Content</p></div>");

}

import elemi.generator;

static if (__traits(compiles, { import core.attribute : mustuse; })) {
    import core.attribute : mustuse;
}
else {
    alias mustuse = AliasSeq!();
}

///
WrapperBuilder buildWrapper() @safe {
    return WrapperBuilder();
}

///
@mustuse
struct WrapperBuilder {

    Wrapper opBinary(string op : "~")(void delegate(Wrapper.Generator) @safe build) @safe {
        return Wrapper(build);
    }

    SystemWrapper opBinary(string op : "~")(void delegate(Wrapper.Generator) build) @safe {
        return SystemWrapper(build);
    }

}

///
@mustuse
struct Wrapper {

    alias Generator = void delegate() @safe;

    void delegate(Generator) @safe generator;

    void opBinary(string op : "~")(void delegate() @safe build) @safe {
        generator(build);
    }

    void opBinary(string op : "~")(void delegate() @system build) @system {
        Generator trustedBuild = () @trusted => build();
        generator(trustedBuild);
    }

}

@mustuse
struct SystemWrapper {

    alias Generator = void delegate() @safe;

    void delegate(Generator) generator;

    void opBinary(string op : "~")(void delegate() @system build) @system {
        Generator trustedBuild = () @trusted => build();
        generator(trustedBuild);
    }

}

@("Wrappers can be used with @system")
@system unittest {
    import elemi.html;

    auto safeWrapper = buildWrapper() ~ (content) @safe {
        HTML.h1 ~ { };
        content();
    };

    auto content = buildDocument() ~ () @system {
        safeWrapper ~ () @safe {
            HTML.h2 ~ { };
        };
    };

    assert(content == "<h1></h1><h2></h2>");
}

@("Wrappers themselves can be system")
@system unittest {
    import elemi.html;

    auto systemWrapper = buildWrapper() ~ (content) @system {
        HTML.h1 ~ { };
        content();
    };

    auto content = buildDocument() ~ {
        systemWrapper ~ () @safe {
            HTML.h2 ~ { };
        };
    };

    assert(content == "<h1></h1><h2></h2>");
}
