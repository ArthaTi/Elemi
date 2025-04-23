/// This module defines the old HTML syntax for Elemi.
///
/// For the new syntax, see [elemi.generator](elemi.generator.html).
///
/// HTML generation in Elemi is based on Elemi's [XML generator](elemi.xml.html). Practically
/// speaking, the HTML layer just auto-detects
/// [void elements](https://developer.mozilla.org/en-US/docs/Glossary/Void_element).
/// As a consequence, Elemi-generated HTML documents are also valid XHTML or XML.
///
/// $(B Elemi can be learned by [#examples|example]!)
module elemi.html;

/// The `elem` template is your key to Elemi's HTML generation. It can be used to create elements,
/// specify attributes, and add contents.
pure @safe unittest {
    auto e = elem!"p"("Hello, World!");
    // The template argument ("p" above) specifies element type

    assert(e == "<p>Hello, World!</p>");
}

/// You can nest other elements, text — mix and match.
pure @safe unittest {
    auto e = elem!"p"(
        "Hello, ",
        elem!"strong"("World"),
        "!",
    );

    assert(e == "<p>Hello, <strong>World</strong>!</p>");
}

/// Add attributes with `attr`:
pure @safe unittest {
    auto e = elem!"input"(
        attr("type") = "text",
        attr("name") = "name",
        attr("placeholder") = "Your name…",
    );

    assert(e == `<input type="text" name="name" placeholder="Your name…"/>`);
}

/// Elemi is designed to work with dynamic content, so it escapes all input automatically.
///
/// Warning: [javascript](https://developer.mozilla.org/en-US/docs/Web/URI/Reference/Schemes/javascript)
/// schema URLs are $(B NOT) escaped! If you want your users to specify link targets, make sure
/// to block all `javascript:` links.
pure @safe unittest {
    auto e = elem!"div"(
        attr("data-text") = `No jail">break`,
        "<script>alert('Fooled!')</script>",
    );

    assert(e == `<div data-text="No jail&quot;&gt;break">`
        ~ `&lt;script&gt;`
        ~ `alert(&#39;Fooled!&#39;)`
        ~ `&lt;/script&gt;`
        ~ `</div>`);
}

/// Append attributes, children, text, at runtime.
pure @safe unittest {
    auto e = elem!"div"();
    e ~= attr("class") = "one";
    e ~= elem!"span"("Two");
    e ~= "Three";

    assert(e == `<div class="one">`
        ~ `<span>Two</span>`
        ~ `Three`
        ~ `</div>`);
}

/// If you need to group a few elements together, you can do it with `elems`.
pure @safe unittest {
    auto child = elems(
        "Hello, ",
        elemX!"strong"("World"),
    );
    auto parent = elem!"div"(
        child,
    );

    assert(child == "Hello, <strong>World</strong>");
    assert(parent == "<div>Hello, <strong>World</strong></div>");
}

/// If combined with a fresh compiler, Elemi also supports interpolated strings.
static if (withInterpolation)
pure @safe unittest{
    auto e = elem!"div"(
        attr("data-expression") = i"1+2 = $(1+2)",
        i"1+2 is $(1+2)",
    );

    assert(e == `<div data-expression="1+2 = 3">1+2 is 3</div>`);
}

import std.meta;
import std.range;
import std.traits;

import elemi.xml;
import elemi.internal;
import elemi.generator;

public {

    import elemi.attribute;
    import elemi.element;

}

// Magic elem alias
alias elem = elemH;
alias add = addH;

/// Create a HTML element. This template wraps `elemX`, implementing support for HTML void tags.
///
/// Examples for this module [elemi.html](elemi.html.html) cover its most important features.
///
/// Params:
///     name = Name of the element.
///     Ts   = Compile-time arguments to pass to `elemX`. Discouraged.
///     args = Arguments to pass to `elemX`. Mix and match any from this list: $(LIST
///         * Pass an [Element] created by this function to add as a child.
///         * Any [Attribute] given will be added to the element's attribute list.
///         * Text content can be specified with a [string].
///     )
/// Returns:
///     An [Element] instance, which can implicitly be casted to string.
template elemH(string name, Ts...) {

    Element elemH(Args...)(Args args) {

        enum tag = makeHTMLTag(name);

        return elemX!(tag, Ts)(args);

    }

}

/// Add a new node as a child of this node.
/// Returns: This node, to allow chaining.
Element addH(Ts...)(ref Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

/// ditto
Element addH(Ts...)(Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

/// ditto
template addH(Ts...)
if (Ts.length != 0) {

    Element addH(Args...)(ref Element parent, Args args) {

        parent ~= elemH!Ts(args);
        return parent;

    }

    Element addH(Args...)(Element parent, Args args) {

        parent ~= elemH!Ts(args);
        return parent;

    }

}

/// A [void element](https://developer.mozilla.org/en-US/docs/Glossary/Void_element) in HTML
/// accepts no children, and has no closing tag. Contrast for example, the self-closing `<input/>`
/// with the usual `<div></div>` — no `</input>` tag follows.
///
/// Correctly generating or omitting end tags is obligatory for HTML5.
///
/// Returns:
///     True, if the given tag name represents a HTML5 self-closing tag.
bool isVoidTag(string tag) pure @safe {

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

/// If the given tag is a void tag, make it a self-closing.
private string makeHTMLTag(string tag) pure @safe {

    assert(tag.length && tag[$-1] != '/', "Self-closing tags are applied automatically when working with html, please"
        ~ " remove the slash.");

    return isVoidTag(tag) ? tag ~ "/" : tag;

}
