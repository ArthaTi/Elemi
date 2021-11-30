/// Additonal tests, with no global imports.
module elemi.tests;

// Of course, in practice, you should never mix elemH and elemX in the same document. We do this here to simplify the
// tests.

unittest {

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

unittest {

    import elemi.html;

    assert(
        elem!"div"(
            elem!"br",
            elem!"input",
        )
            .add!"br",
    );

}

unittest {

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
