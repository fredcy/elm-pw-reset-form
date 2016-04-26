(function () {
    // Find the legacy form so we can scape data from it and hide it.
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

    var div = document.getElementById("elm");
    var app = Elm.Reset.embed(div, formInfo);

    if (typeof zxcvbn !== 'undefined') {
	// Listen for changes to password value and send back evaluations.
	app.ports.pwChanges.subscribe(function(pwValue) {
            var result = zxcvbn(pwValue);
            app.ports.pwStrength.send(result.score);
	});
    } else {
	console.log("ERROR: zxcvbn not defined; See Makefile");
    }

    // Listen for focus requests.
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

