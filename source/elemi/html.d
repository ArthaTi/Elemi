module elemi.html;

import std.meta;
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

/// Create a HTML element.
///
/// Params:
///     name = Name of the element.
/// Returns: a Element type, implicitly castable to string.
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

    Element addH(Args...)(ref Element parent, Args args) {

        parent ~= elemH!Ts(args);
        return parent;

    }

    Element addH(Args...)(Element parent, Args args) {

        parent ~= elemH!Ts(args);
        return parent;

    }

}

/// Check if the given tag is a HTML5 self-closing tag.
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

/// Generic HTML tag.
struct HTMLTag(string name) {
    enum isVoidTag = name == "area"
        || name == "base"
        || name == "br"
        || name == "col"
        || name == "command"
        || name == "embed"
        || name == "hr"
        || name == "img"
        || name == "input"
        || name == "keygen"
        || name == "link"
        || name == "meta"
        || name == "param"
        || name == "source"
        || name == "track"
        || name == "wbr";

    auto tag = Tag(name, isVoidTag);
    alias tag this;
}

/// Add an `id` attribute to an HTML tag.
/// Params:
///     tag   = Tag builder for the target tag.
///     value = Value to use for the attribute. Supports istrings.
/// Returns:
///     A tag builder.
Tag id(string name)(HTMLTag!name tag, string value) @safe {
    return tag.attr("id", value);
}

static if (withInterpolation) {
    Tag id(string name, Ts...)(HTMLTag!name tag, InterpolationHeader header, Ts value) @safe {
        return tag.attr("id", header, value);
    }
}

/// Add a `class` attribute to a HTML tag.
/// Params:
///     tag    = Tag builder for the target tag.
///     values = Classes to write.
/// Returns:
///     A tag builder.
Tag classes(string name)(HTMLTag!name tag, string[] values...) @safe {
    tag.beginAttributes();
    pushElementMarkup(` class="`);
    foreach (i, value; values) {
        if (i) pushElementMarkup(" ");
        pushElementText(value);
    }
    pushElementMarkup(`"`);
    return tag.attributed;
}

/// Set the "href" attribute for an `<a>` element.
/// Params:
///     tag   = Tag builder for the target tag.
///     value = Value to use for the attribute. Supports istrings.
/// Returns:
///     A tag builder.
Tag href(HTMLTag!"a" tag, string value) @safe {
    return tag.attr("href", value);
}

static if (withInterpolation) {
    /// ditto
    Tag href(Ts...)(HTMLTag!"a" tag, InterpolationHeader header, Ts value) @safe {
        return tag.attr("href", header, value);
    }
}

/// A set of HTML tags to build documents with.
struct HTML {

    alias blankTag this;

    enum blankTag = Tag.init;

    enum {
        a           = HTMLTag!"a"(),
        abbr        = HTMLTag!"abbr"(),
        acronym     = HTMLTag!"acronym"(),
        address     = HTMLTag!"address"(),
        area        = HTMLTag!"area"(),
        article     = HTMLTag!"article"(),
        aside       = HTMLTag!"aside"(),
        audio       = HTMLTag!"audio"(),
        b           = HTMLTag!"b"(),
        base        = HTMLTag!"base"(),
        bdi         = HTMLTag!"bdi"(),
        bdo         = HTMLTag!"bdo"(),
        big         = HTMLTag!"big"(),
        blockquote  = HTMLTag!"blockquote"(),
        body        = HTMLTag!"body"(),
        br          = HTMLTag!"br"(),
        button      = HTMLTag!"button"(),
        canvas      = HTMLTag!"canvas"(),
        caption     = HTMLTag!"caption"(),
        center      = HTMLTag!"center"(),
        cite        = HTMLTag!"cite"(),
        code        = HTMLTag!"code"(),
        col         = HTMLTag!"col"(),
        colgroup    = HTMLTag!"colgroup"(),
        command     = HTMLTag!"command"(),
        data        = HTMLTag!"data"(),
        datalist    = HTMLTag!"datalist"(),
        dd          = HTMLTag!"dd"(),
        del         = HTMLTag!"del"(),
        details     = HTMLTag!"details"(),
        dfn         = HTMLTag!"dfn"(),
        dialog      = HTMLTag!"dialog"(),
        dir         = HTMLTag!"dir"(),
        div         = HTMLTag!"div"(),
        dl          = HTMLTag!"dl"(),
        dt          = HTMLTag!"dt"(),
        em          = HTMLTag!"em"(),
        embed       = HTMLTag!"embed"(),
        fencedframe = HTMLTag!"fencedframe"(),
        fieldset    = HTMLTag!"fieldset"(),
        figcaption  = HTMLTag!"figcaption"(),
        figure      = HTMLTag!"figure"(),
        font        = HTMLTag!"font"(),
        footer      = HTMLTag!"footer"(),
        form        = HTMLTag!"form"(),
        frame       = HTMLTag!"frame"(),
        frameset    = HTMLTag!"frameset"(),
        h1          = HTMLTag!"h1"(),
        h2          = HTMLTag!"h2"(),
        h3          = HTMLTag!"h3"(),
        h4          = HTMLTag!"h4"(),
        h5          = HTMLTag!"h5"(),
        h6          = HTMLTag!"h6"(),
        head        = HTMLTag!"head"(),
        header      = HTMLTag!"header"(),
        hgroup      = HTMLTag!"hgroup"(),
        hr          = HTMLTag!"hr"(),
        html        = HTMLTag!"html"(),
        i           = HTMLTag!"i"(),
        iframe      = HTMLTag!"iframe"(),
        img         = HTMLTag!"img"(),
        input       = HTMLTag!"input"(),
        ins         = HTMLTag!"ins"(),
        kbd         = HTMLTag!"kbd"(),
        keygen      = HTMLTag!"keygen"(),
        label       = HTMLTag!"label"(),
        legend      = HTMLTag!"legend"(),
        li          = HTMLTag!"li"(),
        link        = HTMLTag!"link"(),
        main        = HTMLTag!"main"(),
        map         = HTMLTag!"map"(),
        mark        = HTMLTag!"mark"(),
        marquee     = HTMLTag!"marquee"(),
        math        = HTMLTag!"math"(),
        menu        = HTMLTag!"menu"(),
        meta        = HTMLTag!"meta"(),
        meter       = HTMLTag!"meter"(),
        nav         = HTMLTag!"nav"(),
        nobr        = HTMLTag!"nobr"(),
        noembed     = HTMLTag!"noembed"(),
        noframes    = HTMLTag!"noframes"(),
        noscript    = HTMLTag!"noscript"(),
        object      = HTMLTag!"object"(),
        ol          = HTMLTag!"ol"(),
        optgroup    = HTMLTag!"optgroup"(),
        option      = HTMLTag!"option"(),
        output      = HTMLTag!"output"(),
        p           = HTMLTag!"p"(),
        param       = HTMLTag!"param"(),
        picture     = HTMLTag!"picture"(),
        plaintext   = HTMLTag!"plaintext"(),
        pre         = HTMLTag!"pre"(),
        progress    = HTMLTag!"progress"(),
        q           = HTMLTag!"q"(),
        rb          = HTMLTag!"rb"(),
        rp          = HTMLTag!"rp"(),
        rt          = HTMLTag!"rt"(),
        rtc         = HTMLTag!"rtc"(),
        ruby        = HTMLTag!"ruby"(),
        s           = HTMLTag!"s"(),
        samp        = HTMLTag!"samp"(),
        script      = HTMLTag!"script"(),
        search      = HTMLTag!"search"(),
        section     = HTMLTag!"section"(),
        select      = HTMLTag!"select"(),
        slot        = HTMLTag!"slot"(),
        small       = HTMLTag!"small"(),
        source      = HTMLTag!"source"(),
        span        = HTMLTag!"span"(),
        strike      = HTMLTag!"strike"(),
        strong      = HTMLTag!"strong"(),
        style       = HTMLTag!"style"(),
        sub         = HTMLTag!"sub"(),
        summary     = HTMLTag!"summary"(),
        sup         = HTMLTag!"sup"(),
        svg         = HTMLTag!"svg"(),
        table       = HTMLTag!"table"(),
        tbody       = HTMLTag!"tbody"(),
        td          = HTMLTag!"td"(),
        template_   = HTMLTag!"template"(),
        textarea    = HTMLTag!"textarea"(),
        tfoot       = HTMLTag!"tfoot"(),
        th          = HTMLTag!"th"(),
        thead       = HTMLTag!"thead"(),
        time        = HTMLTag!"time"(),
        title       = HTMLTag!"title"(),
        tr          = HTMLTag!"tr"(),
        track       = HTMLTag!"track"(),
        tt          = HTMLTag!"tt"(),
        u           = HTMLTag!"u"(),
        ul          = HTMLTag!"ul"(),
        var         = HTMLTag!"var"(),
        video       = HTMLTag!"video"(),
        wbr         = HTMLTag!"wbr"(),
        xmp         = HTMLTag!"xmp"(),
    }

}
