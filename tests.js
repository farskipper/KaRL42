var _ = require("lodash");
var parser = require("krl-parser");
var codeGen = require("./");
var generator = require("krl-generator");

var n_tests = 10000;

_.each(_.range(1, n_tests), function(n){
    if(n % 100 === 0){
        console.log("TEST #", n, "/", n_tests);
    }
    var gsrc = codeGen({
        start: "Ruleset"
    });
    var ast;
    try{
        ast = parser(gsrc);
    }catch(e){
        console.error("TEST #", n, "/", n_tests);
        console.error(gsrc);
        if(/Parsing Ambiguity/.test(e + "")){
            console.error();
            console.error(e + "");
            process.exit(1);
            return;
        }else{
            throw e;
        }
    }

    var src;
    try{
        src = generator(ast);
    }catch(e){
        console.error("GENERATOR FAILED");
        throw e;
    }
});
console.log("PASSED!");
