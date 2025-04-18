module elemi.internal;

import std.conv;
import std.string;
import std.algorithm;

pure @safe:

static if (__traits(compiles, { import core.interpolation; })) {
    public import core.interpolation;
    enum withInterpolation = true;
}
else {
    enum withInterpolation = false;
}

/// Escape HTML elements.
///
/// Package level: input sanitization is done automatically by the library.
package string escapeHTML(const string text) {

    // substitute doesn't work in CTFE for some reason
    if (__ctfe) {

        return text
            .map!(ch => ch.predSwitch(
                '<', "&lt;",
                '>', "&gt;",
                '&', "&amp;",
                '"', "&quot;",
                '\'', "&#39;",
                .text(ch),
            ))
            .join;

    }

    else return text.substitute!(
        `<`, "&lt;",
        `>`, "&gt;",
        `&`, "&amp;",
        `"`, "&quot;",
        `'`, "&#39;",
    ).to!string;

}

/// Serialize attributes
package string serializeAttributes(string[string] attributes) {

    // Generate attribute text
    string attrHTML;
    foreach (key, value; attributes) {

        attrHTML ~= format!` %s="%s"`(key, value.escapeHTML);

    }

    return attrHTML;

}

package string minifyAttributes(string attrHTML) {

    const ret = attrHTML.splitter("\n")
        .map!q{ a.strip }
        .filter!q{ a.length }
        .join(" ");

    return ret.length
        ? " " ~ ret
        : null;

}
