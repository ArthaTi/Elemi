module elemi.xml;

import std.meta;
import std.traits;

import elemi.internal;

public {

    import elemi.attribute;
    import elemi.element;

}


pure @safe:


// Magic elem alias
alias elem = elemX;
alias add = addX;

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

    enum attrHTML = minifyAttributes(attrHTML);

    auto element = Element.make!name;
    element.attributes = attrHTML
        ~ attributes.serializeAttributes;
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

///
unittest {

    enum xml = elemX!"xml"(
        elemX!"heading"("This is my sample document!"),
        elemX!("spacing /", q{ height="1em" }),
        elemX!"spacing /"(["height": "1em"]),
        elemX!"empty",
        elemX!"br",
        elemX!"container"
            .addX!"paragraph"("Foo")
            .addX!"paragraph"("Bar"),
    );

    assert(xml == "<xml>" ~ (
            "<heading>This is my sample document!</heading>"
            ~ `<spacing height="1em"/>`
            ~ `<spacing height="1em"/>`
            ~ `<empty></empty>`
            ~ `<br></br>`
            ~ "<container>" ~ (
                "<paragraph>Foo</paragraph>"
                ~ "<paragraph>Bar</paragraph>"
            ) ~ "</container>"
        ) ~ "</xml>");

}


/// Add a new node as a child of this node.
/// Returns: This node, to allow chaining.
Element addX(Ts...)(ref Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

Element addX(Ts...)(Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

template addX(Ts...)
if (Ts.length != 0) {

    Element addX(Args...)(ref Element parent, Args args) {

        parent ~= elemX!Ts(args);
        return parent;

    }

    Element addX(Args...)(Element parent, Args args) {

        parent ~= elemX!Ts(args);
        return parent;

    }

}

///
unittest {

    auto document = elem!"xml"
        .addX!"text"("Hello")
        .addX!"text"("World!");

    assert(document == "<xml><text>Hello</text><text>World!</text></xml>");

}

unittest {

    assert(elem!"xml".add("<XSS>") == "<xml>&lt;XSS&gt;</xml>");
    assert(elem!"xml".addX!"span"("<XSS>") == "<xml><span>&lt;XSS&gt;</span></xml>");

}

unittest {

    assert(elemX!"br" == "<br></br>");
    assert(elemX!"br " == "<br ></br >");
    assert(elemX!"br /" == "<br/>");
    assert(elemX!"br/" == "<br/>");

    assert(elemX!"myFancyTag" == "<myFancyTag></myFancyTag>");
    assert(elemX!"myFancyTag /" == "<myFancyTag/>");
    assert(elemX!"myFancyTäg /" == "<myFancyTäg/>");

    assert(elemX!"?br" == "<?br ?>");
    assert(elemX!"!br" == "<!br>");

    assert(elemX!"?br" == "<?br ?>");
    assert(elemX!("?br", "foo") == "<?br foo ?>");
    assert(elemX!"?br"(attr("foo", "bar")) == `<?br foo="bar" ?>`);

}

// Issue #1
unittest {

    enum Foo = elem!("p")("<unsafe>code</unsafe>");

}

unittest {

    assert(elemX!"p" == "<p></p>");
    assert(elemX!"p /" == "<p/>");
    assert(elemX!("!DOCTYPE", "html") == "<!DOCTYPE html>");
    assert(Element.HTMLDoctype == "<!DOCTYPE html>");
    assert(elemX!("!ATTLIST", "pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"!ATTLIST"("pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"!ATTLIST".add("pre (preserve) #FIXED 'preserve'") == "<!ATTLIST pre (preserve) #FIXED 'preserve'>");
    assert(elemX!"?xml" == "<?xml ?>");
    assert(elemX!("?xml", q{ version="1.1" encoding="UTF-8" }) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml"(`version="1.1" encoding="UTF-8"`) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml".add(`version="1.1" encoding="UTF-8"`) == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(Element.XMLDeclaration == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?xml"(["version": "1.1"]).addTrusted(`encoding="UTF-8"`)
        == `<?xml version="1.1" encoding="UTF-8" ?>`);
    assert(elemX!"?php" == "<?php ?>");
    assert(elemX!"?php"(`echo "Hello, World!";`) == `<?php echo "Hello, World!"; ?>`);
    assert(elemX!"?="(`"Hello, World!"`) == `<?= "Hello, World!" ?>`);
    // ↑ I will not special-case this to remove spaces.

    auto php = elemX!"?php";
    php.add(`$target = "World!";`);
    php.add(`echo "Hello, " . $target;`);
    assert(php == `<?php $target = "World!";echo "Hello, " . $target; ?>`);

    assert(elemX!("?xml", "test").add("foo") == "<?xml test foo ?>");
    assert(elemX!("!XML", "test").add("foo") == "<!XML test foo>");

}
