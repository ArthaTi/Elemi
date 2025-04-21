module elemi.html;

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

    Tag tag;
    alias tag this;

    this(DocumentOutput output) {
        this.tag = Tag(output, name, isVoidTag);
    }

    this(Tag tag) {
        this.tag = tag;
    }

    HTMLTag attr(Ts...)(Ts args) {
        return HTMLTag(
            tag.attr(args));
    }

    HTMLTag attributed(Ts...)(Ts args) {
        return HTMLTag(
            tag.attributed(args));
    }

    /// Add an `id` attribute to the HTML tag.
    /// Params:
    ///     value = Value to use for the attribute. Supports istrings.
    /// Returns:
    ///     A tag builder.
    HTMLTag id(string value) @safe {
        return attr("id", value);
    }

    static if (withInterpolation) {
        HTMLTag id(Ts...)(InterpolationHeader header, Ts value) @safe {
            return attr("id", header, value);
        }
    }

    /// Add a `class` attribute to a HTML tag.
    /// Params:
    ///     values = Classes to write.
    /// Returns:
    ///     A tag builder.
    HTMLTag classes(string[] values...) @safe {
        beginAttributes();
        pushElementMarkup(` class="`);
        foreach (i, value; values) {
            if (i) pushElementMarkup(" ");
            pushElementText(value);
        }
        pushElementMarkup(`"`);
        return attributed;
    }

    /// Set the "href" attribute for an `<a>` element.
    /// Params:
    ///     value = Value to use for the attribute. Supports istrings.
    /// Returns:
    ///     A tag builder.
    HTMLTag href(string value) @safe {
        return attr("href", value);
    }

    static if (withInterpolation) {
        /// ditto
        HTMLTag href(Ts...)(InterpolationHeader header, Ts value) @safe {
            return attr("href", header, value);
        }
    }

}

/// Write HTML elements to an output range.
/// Params:
///     range = Output range to write the output to. If not given, the builder will return
///         a string.
/// Returns:
///     A struct that accepts an element block `~ (html) { }` and writes the content to the output
///     range.
HTML buildHTML(T)(ref T range)
if (isOutputRange!(T, char))
do {
    return HTML(
        DocumentOutput(fragment => put(range, fragment)));
}

/// Write HTML elements to a string or [Element].
///
/// Returns:
///     A struct that accepts an element block `~ (html) { }` and writes the content to a string.
TextHTML buildHTML() @safe {
    return TextHTML();
}

/// If no arguments are specified, `buildHTML()` will output to a string. Under the hood,
/// it uses an [std.array.Appender].
@safe unittest {
    import std.array;
    string stringOutput = buildHTML() ~ (html) {
        html.p ~ "Hello!";
    };

    Appender!string rangeOutput;
    buildHTML(rangeOutput) ~ (html) {
        html.p ~ "Hello!";
    };
    assert(stringOutput == rangeOutput[]);
}

struct TextHTML {
    import std.array;

    Element opBinary(string op : "~")(void delegate(HTML) @system rhs) const @system {
        Appender!string output;
        rhs(
            HTML(
                DocumentOutput(fragment => output ~= fragment)));
        return elemTrusted(output[]);
    }

    Element opBinary(string op : "~")(void delegate(HTML) @safe rhs) const @safe {
        Appender!string output;
        rhs(
            HTML(
                DocumentOutput(fragment => output ~= fragment)));
        return elemTrusted(output[]);
    }

}

/// A set of HTML tags to build documents with.
struct HTML {

    DocumentOutput documentOutput;

    alias documentOutput this;

    void opBinary(string op : "~", T : string)(T rhs) @safe {
        documentOutput ~ rhs;
    }

    static if (withInterpolation) {
        void opBinary(string op : "~", Ts...)(InterpolationHeader, Ts text) {
            pushElementText(text);
        }
    }

    void opBinary(string op : "~")(void delegate(HTML o) @system rhs) @system {
        rhs(this);
    }

    void opBinary(string op : "~")(void delegate(HTML o) @safe rhs) @safe {
        rhs(this);
    }

    @safe:

    HTMLTag!"a" a() {
        return typeof(return)(this);
    }
    HTMLTag!"abbr" abbr() {
        return typeof(return)(this);
    }
    HTMLTag!"acronym" acronym() {
        return typeof(return)(this);
    }
    HTMLTag!"address" address() {
        return typeof(return)(this);
    }
    HTMLTag!"area" area() {
        return typeof(return)(this);
    }
    HTMLTag!"article" article() {
        return typeof(return)(this);
    }
    HTMLTag!"aside" aside() {
        return typeof(return)(this);
    }
    HTMLTag!"audio" audio() {
        return typeof(return)(this);
    }
    HTMLTag!"b" b() {
        return typeof(return)(this);
    }
    HTMLTag!"base" base() {
        return typeof(return)(this);
    }
    HTMLTag!"bdi" bdi() {
        return typeof(return)(this);
    }
    HTMLTag!"bdo" bdo() {
        return typeof(return)(this);
    }
    HTMLTag!"big" big() {
        return typeof(return)(this);
    }
    HTMLTag!"blockquote" blockquote() {
        return typeof(return)(this);
    }
    HTMLTag!"body" body() {
        return typeof(return)(this);
    }
    HTMLTag!"br" br() {
        return typeof(return)(this);
    }
    HTMLTag!"button" button() {
        return typeof(return)(this);
    }
    HTMLTag!"canvas" canvas() {
        return typeof(return)(this);
    }
    HTMLTag!"caption" caption() {
        return typeof(return)(this);
    }
    HTMLTag!"center" center() {
        return typeof(return)(this);
    }
    HTMLTag!"cite" cite() {
        return typeof(return)(this);
    }
    HTMLTag!"code" code() {
        return typeof(return)(this);
    }
    HTMLTag!"col" col() {
        return typeof(return)(this);
    }
    HTMLTag!"colgroup" colgroup() {
        return typeof(return)(this);
    }
    HTMLTag!"command" command() {
        return typeof(return)(this);
    }
    HTMLTag!"data" data() {
        return typeof(return)(this);
    }
    HTMLTag!"datalist" datalist() {
        return typeof(return)(this);
    }
    HTMLTag!"dd" dd() {
        return typeof(return)(this);
    }
    HTMLTag!"del" del() {
        return typeof(return)(this);
    }
    HTMLTag!"details" details() {
        return typeof(return)(this);
    }
    HTMLTag!"dfn" dfn() {
        return typeof(return)(this);
    }
    HTMLTag!"dialog" dialog() {
        return typeof(return)(this);
    }
    HTMLTag!"dir" dir() {
        return typeof(return)(this);
    }
    HTMLTag!"div" div() {
        return typeof(return)(this);
    }
    HTMLTag!"dl" dl() {
        return typeof(return)(this);
    }
    HTMLTag!"dt" dt() {
        return typeof(return)(this);
    }
    HTMLTag!"em" em() {
        return typeof(return)(this);
    }
    HTMLTag!"embed" embed() {
        return typeof(return)(this);
    }
    HTMLTag!"fencedframe" fencedframe() {
        return typeof(return)(this);
    }
    HTMLTag!"fieldset" fieldset() {
        return typeof(return)(this);
    }
    HTMLTag!"figcaption" figcaption() {
        return typeof(return)(this);
    }
    HTMLTag!"figure" figure() {
        return typeof(return)(this);
    }
    HTMLTag!"font" font() {
        return typeof(return)(this);
    }
    HTMLTag!"footer" footer() {
        return typeof(return)(this);
    }
    HTMLTag!"form" form() {
        return typeof(return)(this);
    }
    HTMLTag!"frame" frame() {
        return typeof(return)(this);
    }
    HTMLTag!"frameset" frameset() {
        return typeof(return)(this);
    }
    HTMLTag!"h1" h1() {
        return typeof(return)(this);
    }
    HTMLTag!"h2" h2() {
        return typeof(return)(this);
    }
    HTMLTag!"h3" h3() {
        return typeof(return)(this);
    }
    HTMLTag!"h4" h4() {
        return typeof(return)(this);
    }
    HTMLTag!"h5" h5() {
        return typeof(return)(this);
    }
    HTMLTag!"h6" h6() {
        return typeof(return)(this);
    }
    HTMLTag!"head" head() {
        return typeof(return)(this);
    }
    HTMLTag!"header" header() {
        return typeof(return)(this);
    }
    HTMLTag!"hgroup" hgroup() {
        return typeof(return)(this);
    }
    HTMLTag!"hr" hr() {
        return typeof(return)(this);
    }
    HTMLTag!"html" html() {
        return typeof(return)(this);
    }
    HTMLTag!"i" i() {
        return typeof(return)(this);
    }
    HTMLTag!"iframe" iframe() {
        return typeof(return)(this);
    }
    HTMLTag!"img" img() {
        return typeof(return)(this);
    }
    HTMLTag!"input" input() {
        return typeof(return)(this);
    }
    HTMLTag!"ins" ins() {
        return typeof(return)(this);
    }
    HTMLTag!"kbd" kbd() {
        return typeof(return)(this);
    }
    HTMLTag!"keygen" keygen() {
        return typeof(return)(this);
    }
    HTMLTag!"label" label() {
        return typeof(return)(this);
    }
    HTMLTag!"legend" legend() {
        return typeof(return)(this);
    }
    HTMLTag!"li" li() {
        return typeof(return)(this);
    }
    HTMLTag!"link" link() {
        return typeof(return)(this);
    }
    HTMLTag!"main" main() {
        return typeof(return)(this);
    }
    HTMLTag!"map" map() {
        return typeof(return)(this);
    }
    HTMLTag!"mark" mark() {
        return typeof(return)(this);
    }
    HTMLTag!"marquee" marquee() {
        return typeof(return)(this);
    }
    HTMLTag!"math" math() {
        return typeof(return)(this);
    }
    HTMLTag!"menu" menu() {
        return typeof(return)(this);
    }
    HTMLTag!"meta" meta() {
        return typeof(return)(this);
    }
    HTMLTag!"meter" meter() {
        return typeof(return)(this);
    }
    HTMLTag!"nav" nav() {
        return typeof(return)(this);
    }
    HTMLTag!"nobr" nobr() {
        return typeof(return)(this);
    }
    HTMLTag!"noembed" noembed() {
        return typeof(return)(this);
    }
    HTMLTag!"noframes" noframes() {
        return typeof(return)(this);
    }
    HTMLTag!"noscript" noscript() {
        return typeof(return)(this);
    }
    HTMLTag!"object" object() {
        return typeof(return)(this);
    }
    HTMLTag!"ol" ol() {
        return typeof(return)(this);
    }
    HTMLTag!"optgroup" optgroup() {
        return typeof(return)(this);
    }
    HTMLTag!"option" option() {
        return typeof(return)(this);
    }
    HTMLTag!"output" output() {
        return typeof(return)(this);
    }
    HTMLTag!"p" p() {
        return typeof(return)(this);
    }
    HTMLTag!"param" param() {
        return typeof(return)(this);
    }
    HTMLTag!"picture" picture() {
        return typeof(return)(this);
    }
    HTMLTag!"plaintext" plaintext() {
        return typeof(return)(this);
    }
    HTMLTag!"pre" pre() {
        return typeof(return)(this);
    }
    HTMLTag!"progress" progress() {
        return typeof(return)(this);
    }
    HTMLTag!"q" q() {
        return typeof(return)(this);
    }
    HTMLTag!"rb" rb() {
        return typeof(return)(this);
    }
    HTMLTag!"rp" rp() {
        return typeof(return)(this);
    }
    HTMLTag!"rt" rt() {
        return typeof(return)(this);
    }
    HTMLTag!"rtc" rtc() {
        return typeof(return)(this);
    }
    HTMLTag!"ruby" ruby() {
        return typeof(return)(this);
    }
    HTMLTag!"s" s() {
        return typeof(return)(this);
    }
    HTMLTag!"samp" samp() {
        return typeof(return)(this);
    }
    HTMLTag!"script" script() {
        return typeof(return)(this);
    }
    HTMLTag!"search" search() {
        return typeof(return)(this);
    }
    HTMLTag!"section" section() {
        return typeof(return)(this);
    }
    HTMLTag!"select" select() {
        return typeof(return)(this);
    }
    HTMLTag!"slot" slot() {
        return typeof(return)(this);
    }
    HTMLTag!"small" small() {
        return typeof(return)(this);
    }
    HTMLTag!"source" source() {
        return typeof(return)(this);
    }
    HTMLTag!"span" span() {
        return typeof(return)(this);
    }
    HTMLTag!"strike" strike() {
        return typeof(return)(this);
    }
    HTMLTag!"strong" strong() {
        return typeof(return)(this);
    }
    HTMLTag!"style" style() {
        return typeof(return)(this);
    }
    HTMLTag!"sub" sub() {
        return typeof(return)(this);
    }
    HTMLTag!"summary" summary() {
        return typeof(return)(this);
    }
    HTMLTag!"sup" sup() {
        return typeof(return)(this);
    }
    HTMLTag!"svg" svg() {
        return typeof(return)(this);
    }
    HTMLTag!"table" table() {
        return typeof(return)(this);
    }
    HTMLTag!"tbody" tbody() {
        return typeof(return)(this);
    }
    HTMLTag!"td" td() {
        return typeof(return)(this);
    }
    HTMLTag!"template" template_() {
        return typeof(return)(this);
    }
    HTMLTag!"textarea" textarea() {
        return typeof(return)(this);
    }
    HTMLTag!"tfoot" tfoot() {
        return typeof(return)(this);
    }
    HTMLTag!"th" th() {
        return typeof(return)(this);
    }
    HTMLTag!"thead" thead() {
        return typeof(return)(this);
    }
    HTMLTag!"time" time() {
        return typeof(return)(this);
    }
    HTMLTag!"title" title() {
        return typeof(return)(this);
    }
    HTMLTag!"tr" tr() {
        return typeof(return)(this);
    }
    HTMLTag!"track" track() {
        return typeof(return)(this);
    }
    HTMLTag!"tt" tt() {
        return typeof(return)(this);
    }
    HTMLTag!"u" u() {
        return typeof(return)(this);
    }
    HTMLTag!"ul" ul() {
        return typeof(return)(this);
    }
    HTMLTag!"var" var() {
        return typeof(return)(this);
    }
    HTMLTag!"video" video() {
        return typeof(return)(this);
    }
    HTMLTag!"wbr" wbr() {
        return typeof(return)(this);
    }
    HTMLTag!"xmp" xmp() {
        return typeof(return)(this);
    }

}
