var _ = require('lodash');
var fs = require('fs');

fs.readFile('./grammar.ne', 'utf-8', function(err, ne){
  if(err) throw err;
  ne = ne.replace(/@?\{%[^%]*%\}/g, '');
  ne = ne.split('\n').map(function(line){
    return _.trimEnd(line);
  }).join('\n');

  console.log(ne);
});
