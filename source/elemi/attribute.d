module elemi.attribute;

import std.string;

import elemi.internal;


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
