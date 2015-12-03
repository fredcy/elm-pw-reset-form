(function () {

    var formId = "resetform";
    var form = document.getElementById(formId);
    if (form == null) {
        console.log("ERROR: form with id " + formId + " not found");
        return;
    }
    form.style.display = "none";
    
    function getValue(selector) {
        var elmt = document.querySelector(selector);
        if (elmt == null) {
            console.log("ERROR: cannot find element " + selector);
            return "FAKE:" + selector;
        }
        return elmt.value;
    }
    var formInfo = {
        action: form.action,
        formkey: getValue("input[name=_formkey]"),
        formname: getValue("input[name=_formname]")
    };

    // Scrape the flash message and any error messages sent by the server. (kluge)
    var status = { flash: [], errors: [] };
    var flashElmts = document.getElementsByClassName("flash");
    for (var i = 0; i < flashElmts.length; i++) {
        status.flash.push(flashElmts[i].innerHTML)
        flashElmts[i].style.display = "none";
        flashElmts[i].innerHTML = "";
    }
    var errorElmts = document.getElementsByClassName("error");
    for (var i = 0; i < errorElmts.length; i++) {
        status.errors.push(errorElmts[i].innerHTML);
    }

    var div = document.getElementById("elm");
    var app = Elm.embed(Elm.Reset, div, { pwStrength: 0, formInfo: formInfo, status: status });

    // Site-specific vocabulary: words treated as extra dictionary.
    var other_inputs = ["imsa", "titan", "imsa.edu", "imsaedu", "illinoismath"];

    app.ports.pwChanges.subscribe(function(pwValue) {
        var result = zxcvbn(pwValue, other_inputs);
        //window.console.log("zxcvbn", result);
        app.ports.pwStrength.send(result.score);
        return result.score;
    });

    app.ports.focus.subscribe(function(selector) {
        //window.console.log("focus", selector);
        setTimeout(function() {
            var nodes = document.querySelectorAll(selector);
            if (nodes.length === 0)
                console.log("Cannot focus on " + selector + " -- not found");
            else if (nodes.length > 1)
                console.log("Warning, " + nodes.length + " elements match " + selector);
            else if (document.activeElement !== nodes[0]) {
                nodes[0].focus()
            }
        }, 50);
    });
})();

