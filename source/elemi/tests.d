/// Additonal tests, with no global imports.
module elemi.tests;

// Of course, in practice, you should never mix elemH and elemX in the same document. We do this here to simplify the
// tests.

pure @safe unittest {

    import elemi.xml;
    import elemi.html : elemH, addH;

    assert(elem!"div/" == "<div/>");
    assert(elem!"input" == "<input></input>");

    assert(
        elem!"meta"
            .add!"br"("This is not HTML")
            .addH!"br"
        == "<meta><br>This is not HTML</br><br/></meta>"
    );

}

pure @safe unittest {

    import elemi.html;

    assert(
        elem!"div"(
            elem!"br",
            elem!"input",
        )
            .add!"br",
    );

}

pure @safe unittest {

    import elemi;

    assert(
        elem!"div"(
            elem!"br",
            elemX!"br"("I don't care about HTML limitations!"),
            elemX!"div /",
        )
        == "<div><br/><br>I don&#39;t care about HTML limitations!</br><div/></div>"
    );

}

// Impure ranges
version (unittest) int impure;
@safe unittest {

    import elemi;
    import std.conv, std.range, std.algorithm;

    auto range = [1, 2, 3]
        .tee!(item => impure += item)
        .map!(item => elem!"number"(item.to!string));

    assert(elemH!"list"(range) == "<list><number>1</number><number>2</number><number>3</number></list>");
    assert(elemX!"list"(range) == elemH!"list"(range));
    assert(impure == 6*3);

    bool ran;

    () pure {

        assert(!__traits(compiles, elem!"list"(range)));
        assert( __traits(compiles, elem!"list"("1")));

        assert(!__traits(compiles, elemX!"list"(range)));
        assert( __traits(compiles, elemX!"list"("1")));

        ran = true;

    }();

    // Just to make sure
    assert(ran);

}

// @system ranges
@system unittest {

    import elemi;
    import std.conv, std.range, std.algorithm;

    int value;

    void increment() @system {

        value++;

    }

    auto range = [1, 2, 3]
        .tee!(item => increment)
        .map!(item => elem!"number"(item.to!string));

    assert(elemH!"list"(range) == "<list><number>1</number><number>2</number><number>3</number></list>");
    assert(elemX!"list"(range) == elemH!"list"(range));
    assert(value == 3*3);

    bool ran;

    () @safe {

        assert(!__traits(compiles, elem!"list"(range)));
        assert( __traits(compiles, elem!"list"("1")));

        assert(!__traits(compiles, elemX!"list"(range)));
        assert( __traits(compiles, elemX!"list"("1")));

        ran = true;

    }();

    assert(ran);

}

/// CTFE usage
unittest {

    import elemi;

    enum document = elem!"p"("<stuff>");

    assert(cast(string) document == cast(string) elem!"p"("<stuff>"));

}
