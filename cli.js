var λ = require('contra');
var _ = require('lodash');
var fs = require('fs');
var typer = require('string-typer');
var inquirer = require('inquirer');

var logo_lines = [
  " _   __     ______ _       ___  _____",
  "| | / /     | ___ \\ |     /   |/ __  \\",
  "| |/ /  __ _| |_/ / |    / /| |`' / /",
  "|    \\ / _` |    /| |   / /_| |  / /",
  "| |\\  \\ (_| | |\\ \\| |___\\___  |./ /___",
  "\\_| \\_/\\__,_\\_| \\_\\_____/   |_/\\_____/"
];

var typeIt = function(lines, options, callback){
  var i = 0;
  var next = function(){
    if(i >= lines.length){
      callback();
      return;
    }
    var opts = {
      min: options.min || 10,
      max: options.max || 100
    };
    if(i > 0){
      opts.initial = lines[i - 1];
    }
    typer(lines[i], opts, onTyped);
    i++;
  };
  var onTyped = function(typed, done){
    process.stdout.clearLine();
    process.stdout.cursorTo(0);
    process.stdout.write(typed);
    if(done){
      next();
    }
  };
  next();
};

var typeLogo = function(callback){
  λ.each.series(logo_lines, function(line, next){
    typer(line, {min: 1, max: 5}, function(typed, done){
      process.stdout.clearLine();
      process.stdout.cursorTo(0);
      process.stdout.write(typed);
      if(done){
        process.stdout.write('\n');
        next();
      }
    });
  }, callback);
};

var blinkN = function(time, done){
  var start = _.now();
  var is_on = true;
  var blink = function(){
    if(time <= (_.now() - start)){
      process.stdout.write('\x1b[?25h');
      done();
      return;
    }
    if(is_on){
      process.stdout.write('\x1b[?25l');
    }else{
      process.stdout.write('\x1b[?25h');
    }
    is_on = !is_on;
    setTimeout(blink, 200);
  };
  blink();
};

var newLineTask = function(done){
  process.stdout.write('\n');
  done();
};

var type_delay = {min: 10, max: 100};

var promptTask = function(desc){
  return function(callback){
    typeIt([
      '  ' + desc.message
    ], type_delay, function(){
      process.stdout.clearLine();
      process.stdout.cursorTo(0);
      inquirer['prompt']([_.assign({}, desc, {
        name: 'val'
      })]).then(function(resp){
        callback(undefined, resp.val);
      });
    });
  };
};

λ.waterfall([
  λ.curry(typeIt, [
    'hello, myname',
    'hello, my name is:'
  ], type_delay),
  newLineTask,
  λ.curry(typeLogo),
  λ.curry(blinkN, 1200),
  newLineTask,
  λ.curry(blinkN, 100),
  newLineTask,
  promptTask({
    type: 'confirm',
    message: 'Would you like me to write you program?'
  }),
  function(resp, next){
    if(resp){
      typeIt([
        'Great!'
      ], type_delay, next);
    }else{
      typeIt([
        'What!',
        'Excuse me',
        'I just',
        'Well, too bad! you',
        'Well, too bad! I will write you one anyways.',
      ], type_delay, next);
    }
  },
  newLineTask,
  newLineTask,
  promptTask({
    type: 'input',
    message: 'Describe the program you would like me to write:'
  }),
  function(input, next){
    next();
  },
  λ.curry(typeIt, [
    'thinking...',
    'thinking',
    'thinking...',
    'thinking',
    'thinking...',
    'Hmmm...',
    'Hmmm',
    'Hmmm...',
    'Hmmm',
    'Hmmm...',
    'Ok. I do not understand you.'
  ], type_delay),
  newLineTask,
  λ.curry(typeIt, [
    'So I am just going to write a much better program'
  ], type_delay),
  newLineTask,
  newLineTask,
  function(next){
    console.log('wat?');
  }
]);