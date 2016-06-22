/*
Thanks nearley-unparse
https://github.com/Hardmath123/nearley/blob/master/bin/nearley-unparse.js
*/
var _ = require('lodash');
var randexp = require('randexp');
var grammar = new require('./krl-grammar.js');
var phonetic = new require('phonetic');

var gen = {
  'Identifier': function(){
    return phonetic.generate();
  },
  'String': function(){
    return JSON.stringify(phonetic.generate());
  },
  'Chevron': function(){
    return '<<blah>>';
  },
  'RegExp': function(){
    return 're#(.*)#';
  },
  'Number': function(){
    return _.random(-100, 100, true) + '';
  },
  'PositiveInteger': function(){
    return _.random(0, 100) + '';
  }
};

module.exports = function(){
  var stack = [grammar.ParserStart];
  var output = '';
  var stop_recusive_rules = false;

  var selectRule = function(currentname){
    var rules = grammar.ParserRules.filter(function(x) {
      return x.name === currentname;
    });
    if(rules.length === 0){
      throw new Error("Nothing matches rule: "+currentname+"!");
    }
    if(stop_recusive_rules){
      rules = _.filter(rules, function(rule){
        return !_.includes(rule.symbols, currentname);
      });
    }
    return _.sample(rules);
  };

  var count = 0;

  while(stack.length > 0){
    count++;
    if(!stop_recusive_rules && count > 200){
      stop_recusive_rules = true;
    }
    var currentname = stack.pop();
    if(typeof currentname === 'string'){
      _.each(selectRule(currentname).symbols, function(symbol){
        stack.push(symbol);
      });
    }else if(gen[currentname]){
      stack.push({literal: gen[currentname]()});
    }else if(currentname.test){
      output += new randexp(currentname).gen();
    }else if(currentname.literal){
      output = currentname.literal + output;
    }
  }

  return output;
};
console.log(module.exports());
