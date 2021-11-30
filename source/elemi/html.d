module elemi.html;

import elemi.internal;

public {

    import elemi.attribute;
    import elemi.element;

}


pure @safe:


// Magic elem alias
alias elem = elemH;

/// Create a HTML element.
///
/// Params:
///     name = Name of the element.
///     attrHTML = Unsanitized attributes to insert at compile-time.
///     attributes = Attributes for the element as an associative array mapping attribute names to their values.
///     content = Attributes (via `Attribute` and `attr`), children and text of the element.
/// Returns: a Element type, implictly castable to string.
Element elemH(string name, T...)(T args) {

    enum tag = makeHTMLTag(name);

    return elemX!(tag, T)(args);

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

    return isVoidTag(tag) ? tag ~ "/" : tag;

}
