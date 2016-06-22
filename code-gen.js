/*
Thanks nearley-unparse
https://github.com/Hardmath123/nearley/blob/master/bin/nearley-unparse.js
*/
var randexp = require('randexp');
var grammar = new require('./krl-grammar.js');

module.exports = function(){
  var stack = [grammar.ParserStart];
  var rules = grammar.ParserRules;

  var output = '';

  while(stack.length > 0){
    var currentname = stack.pop();
    if(typeof(currentname) === 'string'){
      var goodrules = grammar.ParserRules.filter(function(x) {
        return x.name === currentname;
      });
      if(goodrules.length > 0){
        var chosen = goodrules[
          Math.floor(Math.random()*goodrules.length)
        ];
        for(var i=chosen.symbols.length-1; i>=0; i--){
          stack.push(chosen.symbols[i]);
        }
      }else{
        throw new Error("Nothing matches rule: "+currentname+"!");
      }
    }else if(currentname.test){
      var c = new randexp(currentname).gen();
      output += c;
      continue;
    }else if(currentname.literal){
      var c = currentname.literal;
      output += c;
      continue;
    }
  }

  return output;
};
console.log(module.exports());
