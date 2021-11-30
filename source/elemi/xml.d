module elemi.xml;

import elemi.internal;

public {

    import elemi.attribute;
    import elemi.element;

}


pure @safe:


// Magic elem alias
alias elem = elemX;

/// Create an XML element.
///
/// Params:
///     name = Name of the element.
///     attrHTML = Unsanitized attributes to insert at compile-time.
///     attributes = Attributes for the element as an associative array mapping attribute names to their values.
///     content = Attributes (via `Attribute` and `attr`), children and text of the element.
/// Returns: a Element type, implictly castable to string.
Element elemX(string name, string[string] attributes, Ts...)(Ts content) {

    // Overload 1: attributes from a CTFE hash map

    enum attrHTML = attributes.serializeAttributes;

    auto element = Element.make!name;
    element.attributes = attrHTML;
    element ~= content;

    return element;

}

/// ditto
Element elemX(string name, string attrHTML = null, T...)(string[string] attributes, T content) {

    // Overload 2: attributes from a CTFE attribute string and from a runtime hash map

    enum attrHTML = minifyAttributes(attrHTML)
        ~ attributes.serializeAttributes;

    auto element = Element.make!name;
    element.attributes = attrHTML;
    element ~= content;

    return element;

}

/// ditto
Element elemX(string name, string attrHTML = null, T...)(T content)
if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

    // Overload 3: attributes from a CTFE attribute string

    enum attrHTML = minifyAttributes(attrHTML);

    auto element = Element.make!name;
    element.attributes = attrHTML;
    element ~= content;

    return element;

}
