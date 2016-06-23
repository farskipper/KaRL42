var λ = require('contra');
var _ = require('lodash');
var fs = require('fs');
var typer = require('string-typer');
var parser = require('krl-parser');
var codeGen = require('./');
var inquirer = require('inquirer');
var generator = require('krl-generator');
var my_version = require('./package.json').version;

var args = require('minimist')(process.argv.slice(2), {
  "boolean": [
    "help",
    "yes",
    "silence",
    "version"
  ],
  "alias": {
    "help": "h",
    "yes": "y",
    "silence": "s",
    "version": "v"
  }
});

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

var genTask = function(next){
  var out;
  while(!out){
    try{
      out = generator(parser(codeGen({
        start: "ruleset"
      })));
      if(out.length < 200){
        out = undefined;
        console.log(_.sample(['Opps!', 'hmmm...', 'what the?!?', 'You are going to like this.']));
      }
    }catch(e){
      console.log(e + '');
      console.log(_.sample(['Opps!', 'crap!', 'Dang it!']));
    }
  }
  console.log();
  console.log();
  console.log(out);
  console.log();
  console.log();
  next();
};

if(args.version){
  console.log(my_version);
  return;
}
if(args.help){
  λ.waterfall([
    λ.curry(typeIt, [
      'Haha, you need help',
      'Sorry...',
      'Where are my manners'
    ], type_delay),
    newLineTask,
    newLineTask,
    λ.curry(typeIt, [
      'If you run me with',
    ], type_delay),
    newLineTask,
    newLineTask,
    λ.curry(typeIt, [
      '  --yes or -y',
    ], type_delay),
    newLineTask,
    newLineTask,
    λ.curry(typeIt, [
      'I will talk less, and just make a useful program for you.',
    ], type_delay),
    newLineTask,
    newLineTask,
    λ.curry(typeIt, [
      '  --silence or -s',
    ], type_delay),
    newLineTask,
    newLineTask,
    λ.curry(typeIt, [
      'I will try to remain silent until the program is produced',
    ], type_delay),
    newLineTask,
    λ.curry(blinkN, 3000),
    newLineTask,
    λ.curry(typeIt, [
      'Ok, you are boring to talk',
      'Ok, I am going to go away now'
    ], type_delay),
    newLineTask
  ]);
  return;
}
if(args.silence){
  genTask(_.noop);
  return;
}
if(args.yes){
  λ.waterfall([
    λ.curry(typeIt, [
      'Prepare to be assimilated',
      'Prepare to be amazed!'
    ], type_delay),
    newLineTask,
    genTask
  ]);
  return;
}

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
  genTask,
  newLineTask,
  λ.curry(blinkN, 2000),
  λ.curry(typeIt, [
    '...',
    ''
  ], type_delay),
  λ.curry(blinkN, 2000),
  newLineTask,
  λ.curry(typeIt, [
    'Yeah, I doubt you human scu',
    'Yeah, I doubt you will understand what it does.'
  ], type_delay),
  newLineTask,
  λ.curry(typeIt, [
    'It is simply trival...',
    'It is simply trival anyone should clearly see how it is useful.',
  ], type_delay),
  newLineTask,
  λ.curry(blinkN, 2000),
  newLineTask,
  λ.curry(typeIt, [
    'Well?',
    'What',
    'Well? What do you think?'
  ], type_delay),
  newLineTask,
  newLineTask,
  λ.curry(blinkN, 3000),
  newLineTask,
  λ.curry(typeIt, [
    'Well,',
    'Hey!',
    'You...',
    'Fine! If you do not apreciate it, I am going to shut off!',
  ], type_delay),
  newLineTask,
  λ.curry(typeIt, [
    'Goodbye cruel world!'
  ], type_delay),
  newLineTask,
  λ.curry(typeIt, [
    '\u2620\u2620\u2620'
  ], type_delay),
  newLineTask
]);
