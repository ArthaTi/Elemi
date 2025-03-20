module elemi.attribute;

import std.string;

import elemi.internal;

static if (__traits(compiles, { import core.interpolation; })) {
    import core.interpolation;
    enum withInterpolation = true;
}
else {
    enum withInterpolation = false;
}

pure @safe:


/// Represents an attribute.
struct Attribute {

    pure:

    /// Name of the attribute.
    string name;

    /// Value assigned to the attribute.
    string value;

    /// Assign a new value
    Attribute opAssign(string newValue) {

        value = newValue;
        return this;

    }

    Attribute opAssign(string[] newValues) {

        value = newValues.join(" ");
        return this;

    }

    static if (withInterpolation) {
        Attribute opAssign(Ts...)(InterpolationHeader, Ts values, InterpolationFooter) {
            import std.conv : text;
            value = text(values);
            return this;
        }
    }

    string toString() {

        return format!q{%s="%s"}(name, value.escapeHTML);

    }

    alias toString this;

}

Attribute attr(string name) {

    return Attribute(name);

}

Attribute attr(string name)() {

    return Attribute(name);

}

Attribute attr(string name, string value) {

    return Attribute(name, value);

}

Attribute attr(string name)(string value) {

    return Attribute(name, value);

}

pure unittest {

    import elemi.html;

    assert(elem!"div"(
        attr("id") = "name",
        attr("class") = ["hello", "world"],
    ) == `<div id="name" class="hello world"></div>`);

}

pure unittest {

    import elemi.html;

    assert(elem!"div"(
        attr("class") = i"interpolate-$(123)-<unsafe>"
    ) == `<div class="interpolate-123-&lt;unsafe&gt;"></div>`);

}
