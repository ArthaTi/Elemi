module elemi.html;

import std.meta;
import std.traits;

import elemi.xml;
import elemi.internal;

public {

    import elemi.attribute;
    import elemi.element;

}


pure @safe:


// Magic elem alias
alias elem = elemH;
alias add = addH;

/// Create a HTML element.
///
/// Params:
///     name = Name of the element.
///     attrHTML = Unsanitized attributes to insert at compile-time.
///     attributes = Attributes for the element as an associative array mapping attribute names to their values.
///     content = Attributes (via `Attribute` and `attr`), children and text of the element.
/// Returns: a Element type, implictly castable to string.
template elemH(string name, Ts...) {

    Element elemH(T...)(T args) {

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

Element addH(Ts...)(Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

template addH(Ts...)
if (Ts.length != 0) {

    Element addH(Args...)(ref Element parent, Args args) pure {

        parent ~= elemH!Ts(args);
        return parent;

    }

    Element addH(Args...)(Element parent, Args args) pure {

        parent ~= elemH!Ts(args);
        return parent;

    }

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

/// If the given tag is a void tag, make it a self-closing.
private string makeHTMLTag(string tag) {

    assert(tag.length && tag[$-1] != '/', "Self-closing tags are applied automatically when working with html, please"
        ~ " remove the slash.");

    return isVoidTag(tag) ? tag ~ "/" : tag;

}
