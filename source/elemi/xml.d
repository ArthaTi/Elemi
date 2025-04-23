/// This module defines the old Elemi syntax for generating XML code.
///
/// See [#examples|examples] for more information.
module elemi.xml;

/// Elemi allows creating XML elements using the `elemX` template.
pure @safe unittest {
    auto element = elemX!"paragraph"("Hello, World!");

    assert(element == "<paragraph>Hello, World!</paragraph>");
}

/// Elements can be nested.
pure @safe unittest {
    auto element = elemX!"book"(
        elemX!"title"("Programming in D"),
        elemX!"author"("Ali Çehreli"),
        elemX!"link"("https://www.ddili.org/ders/d.en/index.html"),
    );

    assert(element == `<book>`
        ~ `<title>Programming in D</title>`
        ~ `<author>Ali Çehreli</author>`
        ~ `<link>https://www.ddili.org/ders/d.en/index.html</link>`
        ~ `</book>`);
}

/// Text and XML content can be mixed together. Special XML characters are always escaped.
pure @safe unittest {
    auto element = elemX!"paragraph"(
        "<injection />",
        elemX!"bold"("Can't get through me!"),
    );

    assert(element == `<paragraph>`
        ~ `&lt;injection /&gt;`
        ~ `<bold>Can&#39;t get through me!</bold>`
        ~ `</paragraph>`);
}

/// Attributes can be added using `attr` at the beginning of your element.
pure @safe unittest {
    auto book = elemX!"website"(
        attr("title") = "D Programming Language",
        attr("url") = "https://dlang.org",
        "D is a general-purpose programming language with static typing, ",
        "systems-level access, and C-like syntax. With the D Programming ",
        "Language, write fast, read fast, and run fast."
    );

    assert(book == `<website `
        ~ `title="D Programming Language" `
        ~ `url="https://dlang.org">`
        ~ `D is a general-purpose programming language with static typing, `
        ~ `systems-level access, and C-like syntax. With the D Programming `
        ~ `Language, write fast, read fast, and run fast.`
        ~ `</website>`);
}

/// You can create self-closing tags if you follow the name with a slash.
pure @safe unittest {
    auto element = elemX!"void/"();
    assert(element == "<void/>");
}

/// The `elem` shorthand defaults to HTML mode, but if you import `elemi.xml` directly,
/// XML mode will be used.
pure @safe unittest {
    {
        import elemi : elem;
        auto e = elem!"input"();
        assert(e == "<input/>");
        // <input> is a self-closing void tag
    }
    {
        import elemi.xml : elem;
        auto e = elem!"input"();
        assert(e == "<input></input>");
    }
}

/// If you need to add children dynamically, you can append them.
pure @safe unittest {
    Element element = elemX!"parent"();

    // Append elements
    foreach (content; ["one", "two", "three"]) {
        element ~= elemX!"child"(content);
    }

    // Append attributes
    element ~= attr("id") = "example";

    assert(element == `<parent id="example">`
        ~ `<child>one</child>`
        ~ `<child>two</child>`
        ~ `<child>three</child>`
        ~ `</parent>`);
}

/// If you need to group a few elements together, you can do it with `elems`.
pure @safe unittest {
    auto child = elems(
        "Hello, ",
        elemX!"strong"("World"),
    );
    auto parent = elemX!"div"(
        child,
    );

    assert(child == "Hello, <strong>World</strong>");
    assert(parent == "<div>Hello, <strong>World</strong></div>");
}

/// If combined with a fresh compiler, Elemi also supports interpolated strings.
static if (withInterpolation)
pure @safe unittest{
    auto e = elemX!"item"(
        attr("expression") = i"1+2 = $(1+2)",
        i"1+2 is $(1+2)",
    );

    assert(e == `<item expression="1+2 = 3">1+2 is 3</item>`);
}

/// `elemX` also supports DTD declarations like DOCTYPE, XML declarations, and even preprocessor
/// tags.
pure @safe unittest {
    assert(elemX!"!DOCTYPE"("html") == `<!DOCTYPE html>`);
    assert(elemX!"?xml"(
        attr("version") = "1.0",
        attr("encoding") = "UTF-8") == `<?xml version="1.0" encoding="UTF-8" ?>`);
    assert(elemX!"?php"(`$var = "<div></div>";`) == `<?php $var = "<div></div>"; ?>`);
    assert(elemX!"?="(`$var`) == `<?= $var ?>`);
}

import std.meta;
import std.traits;

import elemi.internal;

public {

    import elemi.attribute;
    import elemi.element;

}

/// A shorthand for `elemX`. Available if importing `elemi.xml`.
///
/// Note that importing both `elemi` and `elemi.xml`, or `elemi.html` and `elemi.xml` may raise
/// conflicts. Import whichever is more suitable.
///
/// See [elemX] for more information.
alias elem = elemX;
alias add = addX;

/// Create an XML element.
///
/// `elemX` builds the element with attributes and child content given as arguments. Their kind
/// is distinguished by their type — child element should be passed as [Element], attributes
/// as [Attribute] and text content as [string].
///
/// * You can pass the result of `elemX` to another `elemX` call to create child nodes:
///   `elemX!"parent"(elemX!"child"())`.
/// * Use [attr] to specify attributes: `elemX!"element"(attr("key") = "value")`.
/// * Pass a string to specify text content: `elemX!"text"("Hello")`.
///
/// `elemX` also provides the option to specify attributes from an associative array
/// or source: `elemX!"element"(["key": "value"])` or `elemX!("element", `key="value"`)`
/// but these are considered legacy and should be avoided in new code.
///
/// Params:
///     name    = Name of the element.
///     attrXML = Optional, legacy; unsanitized attributes to insert at compile-time.
///     attributes = Optional, legacy; attributes for the element as an associative array mapping
///         attribute names to their values.
///     content = Attributes ([Attribute]),
///         children elements ([Element])
///         and text of the element, as a string.
/// Returns:
///     An [Element] type, implicitly castable to string.
///     Instances of Element can be safely placed
Element elemX(string name, string[string] attributes, Ts...)(Ts content) {

    // Overload 1: attributes from a CTFE hash map

    enum attrHTML = attributes.serializeAttributes;

    auto element = Element.make!name;
    element.attributes = attrHTML;
    element ~= content;

    return element;

}

/// ditto
Element elemX(string name, string attrXML = null, T...)(string[string] attributes, T content) {

    // Overload 2: attributes from a CTFE attribute string and from a runtime hash map

    enum attrXML = minifyAttributes(attrXML);

    auto element = Element.make!name;
    element.attributes = attrXML
        ~ attributes.serializeAttributes;
    element ~= content;

    return element;

}

/// ditto
Element elemX(string name, string attrXML = null, T...)(T content)
if (!T.length || (!is(T[0] == typeof(null)) && !is(T[0] == string[string]))) {

    // Overload 3: attributes from a CTFE attribute string

    enum attrXML = minifyAttributes(attrXML);

    auto element = Element.make!name;
    element.attributes = attrXML;
    element ~= content;

    return element;

}

///
pure @safe unittest {

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


/// Add a new node as a child.
///
/// This overload is considered legacy; you should use the apprend `~=` operator instead.
///
/// Params:
///     parent = Parent node.
/// Returns:
///     This node, to allow chaining.
Element addX(Ts...)(ref Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

/// ditto
Element addX(Ts...)(Element parent, Ts args)
if (allSatisfy!(isType, Ts)) {

    parent ~= args;
    return parent;

}

/// ditto
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
pure @safe unittest {

    auto document = elem!"xml"
        .addX!"text"("Hello")
        .addX!"text"("World!");

    assert(document == "<xml><text>Hello</text><text>World!</text></xml>");

}

pure @safe unittest {

    assert(elem!"xml".add("<XSS>") == "<xml>&lt;XSS&gt;</xml>");
    assert(elem!"xml".addX!"span"("<XSS>") == "<xml><span>&lt;XSS&gt;</span></xml>");

}

pure @safe unittest {

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
pure @safe unittest {

    enum Foo = elem!("p")("<unsafe>code</unsafe>");

}

pure @safe unittest {

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
    assert(Element.XMLDeclaration1_0 == `<?xml version="1.0" encoding="UTF-8" ?>`);
    assert(Element.XMLDeclaration1_1 == `<?xml version="1.1" encoding="UTF-8" ?>`);
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
