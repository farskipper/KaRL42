/*
Thanks nearley-unparse
https://github.com/Hardmath123/nearley/blob/master/bin/nearley-unparse.js
*/
var _ = require('lodash');
var randexp = require('randexp');
var grammar = new require('krl-parser/src/grammar.js');
var phonetic = new require('phonetic');

var gen = {
  '_': function(){
    return _.sample([' ', '']);
  },
  '__': function(){
    return ' ';
  },
  '_semi': function(){
    return _.sample([';', '']);
  },
  '__semi': function(){
    return ';';
  },
  'Identifier': function(){
    return phonetic.generate();
  },
  'Keyword': function(){
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

var isParenRule = function(rule){
  if(_.size(rule && rule.symbols) !== 5){
    return false;
  }
  var s = rule.symbols;
  if(!s[0] || s[0].literal !== "("){
    return false;
  }
  if(s[1] !== "_"){
    return false;
  }
  if(s[3] !== "_"){
    return false;
  }
  if(!s[4] || s[4].literal !== ")"){
    return false;
  }
  return true;
};

module.exports = function(start){
  var stack = [start || grammar.ParserStart];
  var output = '';
  var stop_recusive_rules = false;

  var selectRule = function(currentname){
    var rules = grammar.ParserRules.filter(function(x) {
      return x.name === currentname;
    });
    if(rules.length === 0){
      throw new Error("Nothing matches rule: "+currentname+"!");
    }
    return _.sample(_.filter(rules, function(rule){
      if(isParenRule(rule)){
        return false;
      }
      if(stop_recusive_rules || stack.length > 25){
        return !_.includes(rule.symbols, currentname);
      }
      return true;
    }));
  };

  var count = 0;

  while(stack.length > 0){
    count++;
    if(!stop_recusive_rules && count > 500){
      stop_recusive_rules = true;
    }
    var currentname = stack.pop();
    if(gen[currentname]){
      stack.push({literal: gen[currentname]()});
    }else if(typeof currentname === 'string'){
      _.each(selectRule(currentname).symbols, function(symbol){
        stack.push(symbol);
      });
    }else if(currentname.test){
      output += new randexp(currentname).gen();
    }else if(currentname.literal){
      output = currentname.literal + output;
    }
  }

  return output;
};
