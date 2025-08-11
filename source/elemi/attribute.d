/// Holds the [Attribute] type which can be passed to [elemi.elem|elem] to add attributes to
/// XML and HTML elements.
module elemi.attribute;

///
unittest {
    import elemi.xml;

    // Create new attributes with `attr`
    auto a = attr("key") = "value";
    assert(a == `key="value"`);

    // And pass them to elements
    assert(elem!"div"(a) == `<div key="value"></div>`);

    assert(elem!"div"(
        attr("key") = "value",
        attr("class") = "one two three",
    ) == `<div key="value" class="one two three"></div>`);
}

import std.string;

import elemi.internal;

pure @safe:


/// Represents an XML/HTML attribute. It can be easily created with the [attr] function.
struct Attribute {

    pure:

    /// Name of the attribute.
    string name;

    /// Value assigned to the attribute.
    string value;

    /// Assign a new value to this attribute. Retains the original key.
    /// Params:
    ///     newValue = Value assigned to the attribute. i-strings are supported.
    ///         The value can also be passed as an array of strings, in which case they will be
    ///         joined with a space. That comes handy for CSS classes.
    /// Returns:
    ///     The attribute.
    Attribute opAssign(string newValue) {

        value = newValue;
        return this;

    }

    /// ditto
    Attribute opAssign(string[] newValue) {

        value = newValue.join(" ");
        return this;

    }

    static if (withInterpolation) {
        /// ditto
        Attribute opAssign(Ts...)(InterpolationHeader, Ts values, InterpolationFooter) {
            import std.conv : text;
            value = text(values);
            return this;
        }

        ///
        pure @safe unittest {
            auto a = Attribute("name");
            a = i"1+2 is $(1+2)";
            assert(a == `name="1+2 is 3"`);
        }
    }

    string toString() {

        return format!q{%s="%s"}(name, value.escapeHTML);

    }

    alias toString this;

}

/// Create an XML/HTML attribute.
///
/// Params:
///     name  = Name for the attribute.
///     value = Value for the attribute.
Attribute attr(string name) {

    return Attribute(name);

}

/// ditto
Attribute attr(string name)() {

    return Attribute(name);

}

/// ditto
Attribute attr(string name, string value) {

    return Attribute(name, value);

}

/// ditto
Attribute attr(string name)(string value) {

    return Attribute(name, value);

}

///
pure unittest {
    auto a = attr("key") = "value";
    auto b = attr("key", "value");

    assert(a == `key="value"`);
    assert(a == b);
}

///
pure unittest {
    import elemi.html;

    assert(elem!"div"(
        attr("id") = "name",
        attr("class") = ["hello", "world"],
    ) == `<div id="name" class="hello world"></div>`);
}

///
static if (withInterpolation)
pure unittest {
    import elemi.html;

    assert(elem!"div"(
        attr("class") = i"interpolate-$(123)-<unsafe>"
    ) == `<div class="interpolate-123-&lt;unsafe&gt;"></div>`);
}

/// Returns:
///     True if the specified character is allowed in an attribute name.
bool isAttributeNameCharacter(dchar ch) {
    import std.algorithm : among;
    import std.ascii : isControl;

    return !ch.among('\0', '"', '\'', '>', '/', '=')
        && !ch.isControl;
}

///
unittest {
    assert( 'a'.isAttributeNameCharacter);
    assert( 'A'.isAttributeNameCharacter);
    assert(!'='.isAttributeNameCharacter);
    assert(!'/'.isAttributeNameCharacter);
}
