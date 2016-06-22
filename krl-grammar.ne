@{%

var last = function(arr){
  return arr[arr.length - 1];
};

var lastEndLoc = function(data){
  var nodes = flatten([data]);
  var i, node;
  for(i = nodes.length - 1; i >= 0; i--){
    node = nodes[i];
    if(node && node.loc){
      return node.loc.end;
    }else if(typeof node === "number"){
      return node;
    }
  }
  return -1;
};

var flatten = function(toFlatten){
  var isArray = Object.prototype.toString.call(toFlatten) === '[object Array]';

  if (isArray && toFlatten.length > 0) {
    var head = toFlatten[0];
    var tail = toFlatten.slice(1);

    return flatten(head).concat(flatten(tail));
  } else {
    return [].concat(toFlatten);
  }
};

var get = function(o, path, dflt){
  if(!path || !path.length){
    return dflt;
  }
  var cur = o;
  var i;
  for(i = 0; i < path.length; i++){
    if(!cur){
      return dflt;
    }
    if(cur.hasOwnProperty(path[i])){
      cur = cur[path[i]];
    }else{
      return dflt;
    }
  }
  return cur;
};

var reserved_identifiers = {
  "function": true,
  "true": true,
  "false": true
};

////////////////////////////////////////////////////////////////////////////////
// ast functions
var noop = function(){};
var noopStr = function(){return ""};
var noopArr = function(){return []};
var idAll = function(d){return flatten(d).join('')};
var idArr = function(d){return [d[0]]};
var idEndLoc = function(data, start){return start + flatten(data).join('').length};

var concatArr = function(index){
  return function(data){
    return data[0].concat(data[index]);
  };
};

var getN = function(n){
  return function(data){
    return data[n];
  };
};

var infixEventOp = function(data, start){
  return {
    loc: {start: start, end: data[4].loc.end},
    type: 'EventOperator',
    op: data[2],
    args: [data[0], data[4]]//not all event ops have left/right
  };
};

var complexEventOp = function(op){
  var arg_indices = Array.prototype.slice.call(arguments, 1);
  return function(data, start){
    return {
      loc: {start: start, end: lastEndLoc(data)},
      type: 'EventOperator',
      op: op,
      args: flatten(arg_indices.map(function(i){
        return data[i];
      }))
    };
  };
};

var booleanAST = function(value){
  return function(data, loc){
    var src = data[0];
    return {
      loc: {start: loc, end: loc + src.length},
      type: 'Boolean',
      value: value
    };
  };
};

var infixOp = function(data, start){
  return {
    loc: {start: start, end: data[4].loc.end},
    type: 'InfixOperator',
    op: data[2],
    left: data[0],
    right: data[4]
  };
};

var RulePostlude_by_paths = function(fired_i, notfired_i, always_i){
  return function(data, start){
    return {
      loc: {start: start, end: lastEndLoc(data)},
      type: 'RulePostlude',
      fired: get(data, fired_i, null),
      notfired: get(data, notfired_i, null),
      always: get(data, always_i, null),
    };
  };
};

var MemberExpression_method = function(method){
  return function(data, start){
    return {
      loc: {start: start, end: lastEndLoc(data)},
      type: 'MemberExpression',
      object: data[0],
      property: data[4],
      method: method
    };
  };
};

%}

main -> ruleset

################################################################################
#
# Ruleset
#

ruleset -> "ruleset" __ Identifier _ "{" _
  "meta{author \"KaRL42\"}" _
  ("global" _ declaration_block _):?
  (rule _):+
"}"

################################################################################
#
# Rule
#

rule -> "rule" __ Identifier (__ "is" __ rule_state):? _ "{" _
  "select" __ "when" __ EventExpression ";"

  ("pre" _ declaration_block _ ):?

  (RuleActionBlock _):?

  (RulePostlude _):?

"}" {%
  function(data, loc){
    return {
      loc: {start: loc, end: last(data)},
      type: 'Rule',
      name: data[2],
      rule_state: data[3] ? data[3][3] : "active",
      select_when: data[7] && data[7][4],
      prelude: data[8] ? data[8][2] : [],
      action_block: data[9] && data[9][0],
      postlude: data[10] && data[10][0]
    };
  }
%}

rule_state -> "active" {% id %} | "inactive" {% id %}

################################################################################
#
# EventExpression
#

EventExpression -> event_exp_within {% id %}

event_exp_within -> event_exp_or {% id %}
    | event_exp_within __ "within" __ PositiveInteger __ time_period
      {% complexEventOp("within", 0, 4, 6) %}

event_exp_or -> event_exp_and {% id %}
    | event_exp_or __ "or" __ event_exp_and {% infixEventOp %}

event_exp_and -> event_exp_infix_op {% id %}
    | event_exp_and __ "and" __ event_exp_infix_op {% infixEventOp %}

event_exp_infix_op -> event_exp_fns {% id %}
    | event_exp_infix_op __ "before" __ event_exp_fns {% infixEventOp %}
    | event_exp_infix_op __ "then"   __ event_exp_fns {% infixEventOp %}
    | event_exp_infix_op __ "after"  __ event_exp_fns {% infixEventOp %}

event_exp_fns -> event_exp_base {% id %}
    | event_exp_fns __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ ")"
      {% complexEventOp("between", 0, 6, 10) %}
    | event_exp_fns __ "not" __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ ")"
      {% complexEventOp("not between", 0, 8, 12) %}
    | "any" __ PositiveInteger _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("any", 2, 6) %}
    | "count" __ PositiveInteger _ "(" _ EventExpression _ ")"
      {% complexEventOp("count", 2, 6) %}
    | "repeat" __ PositiveInteger _ "(" _ EventExpression _ ")"
      {% complexEventOp("repeat", 2, 6) %}
    | "and" _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("and", 4) %}
    | "or" _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("or", 4) %}
    | "before" _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("before", 4) %}
    | "then" _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("then", 4) %}
    | "after" _ "(" _ EventExpression_list _ ")"
      {% complexEventOp("after", 4) %}
    | event_exp_fns __  "max" _ "(" _ function_params _ ")"
      {% complexEventOp("max", 0, 6) %}
    | event_exp_fns __  "min" _ "(" _ function_params _ ")"
      {% complexEventOp("min", 0, 6) %}
    | event_exp_fns __  "sum" _ "(" _ function_params _ ")"
      {% complexEventOp("sum", 0, 6) %}
    | event_exp_fns __  "avg" _ "(" _ function_params _ ")"
      {% complexEventOp("avg", 0, 6) %}
    | event_exp_fns __  "push" _ "(" _ function_params _ ")"
      {% complexEventOp("push", 0, 6) %}

event_exp_base -> "(" _ EventExpression _ ")" {% getN(2) %}
  | Identifier __ Identifier
    event_exp_attribute_pairs
    (__ "where" __ Expression):?
    (__ "setting" _ "(" _ function_params _ ")"):? {%
  function(data, start){
    return {
      type: 'EventExpression',
      loc: {start: start, end: lastEndLoc(data)},
      event_domain: data[0],
      event_type: data[2],
      attributes: data[3],
      where: data[4] && data[4][3],
      setting: (data[5] && data[5][5]) || []
    };
  }
%}

event_exp_attribute_pairs -> null {% noopArr %}
    | event_exp_attribute_pair {% idArr %}
    | event_exp_attribute_pairs __ event_exp_attribute_pair {% concatArr(2) %}

event_exp_attribute_pair -> Identifier __ RegExp {%
  function(data, start){
    return {
      loc: {start: start, end: data[2].loc.end},
      type: 'AttributeMatch',
      key: data[0],
      value: data[2]
    };
  }
%}

EventExpression_list -> EventExpression {% idArr %}
    | EventExpression_list _ "," _ EventExpression {% concatArr(4) %}

time_period -> time_period_enum {%
  function(data, start){
    var src = data[0][0];
    return {
      loc: {start: start, end: start + src.length},
      type: 'String',
      value: src
    };
  }
%}

time_period_enum ->
      "years"
    | "months"
    | "weeks"
    | "days"
    | "hours"
    | "minutes"
    | "seconds"
    | "year"
    | "month"
    | "week"
    | "day"
    | "hour"
    | "minute"
    | "second"

################################################################################
#
# RuleActionBlock
#

RuleActionBlock -> ("if" __ Expression __ "then" __ (action_block_type __):?):? RuleActions {%
  function(data, start){
    return {
      loc: {start: start, end: lastEndLoc(data)},
      type: 'RuleActionBlock',
      condition: data[0] && data[0][2],
      block_type: get(data, [0, 6, 0], "every"),
      actions: data[1]
    };
  }
%}

action_block_type -> "choose" {% id %}
    | "every" {% id %}

#NOTE - there must be at least one action
RuleActions -> RuleAction {% idArr %}
    | RuleActions __ RuleAction {% concatArr(2) %}

RuleAction ->
    (Identifier _ "=>" _):?
    Identifier _ "(" _ Expression_list _ ")"
    (_ "with" __ declaration_list):? {%
  function(data, start){
    return {
      loc: {start: start, end: lastEndLoc(data)},
      type: 'RuleAction',
      label: data[0] && data[0][0],
      action: data[1],
      args: data[5],
      "with": data[8] ? data[8][3] : []
    };
  }
%}

################################################################################
#
# RulePostlude
#

RulePostlude ->
      "always" _ postlude_clause {% RulePostlude_by_paths(null, null, [2, 0]) %}
    | "fired" _ postlude_clause
      (_ "else" _ postlude_clause):?
      (_ "finally" _ postlude_clause):?
      {% RulePostlude_by_paths([2, 0], [3, 3, 0], [4, 3, 0]) %}

postlude_clause -> "{" _ Statement_list _ "}" {%
  function(d){
    //we need to keep the location of the close curly
    return [d[2],d[4]];
  }
%}

################################################################################
#
# Statements
#

Statement ->
      ExpressionStatement {% id %}
    | Declaration {% id %}

ExpressionStatement -> Expression {%
  function(data){
    return {
      loc: data[0].loc,
      type: 'ExpressionStatement',
      expression: data[0]
    };
  }
%}

Declaration -> left_side_of_declaration _ "=" _ Expression {%
  function(data, start){
    return {
      loc: {start: data[0].loc.start, end: data[4].loc.end},
      type: 'Declaration',
      op: data[2],
      left: data[0],
      right: data[4]
    };
  }
%}

# Later we may add destructuring
left_side_of_declaration -> Identifier {% id %}

Statement_list -> null {% noopArr %}
    | Statement {% idArr %}
    | Statement_list _ ";" _ Statement {% concatArr(4) %}

declaration_block -> "{" _ "}" {% noopArr %}
    | "{" _ declaration_list _ "}" {% getN(2) %}

declaration_list -> Declaration {% idArr %}
    | declaration_list __ Declaration {% concatArr(2) %}

################################################################################
#
# Expressions
#

Expression -> exp_conditional {% id %}

exp_conditional -> exp_or {% id %}
    | exp_or _ "=>" _ exp_or _ "|" _ exp_conditional {%
  function(data, start){
    return {
      loc: {start: data[0].loc.start, end: data[8].loc.end},
      type: 'ConditionalExpression',
      test: data[0],
      consequent: data[4],
      alternate: data[8]
    };
  }
%}
 
exp_or -> exp_and {% id %}
    | exp_or _ "||" _ exp_and {% infixOp %}
 
exp_and -> exp_comp {% id %}
    | exp_and _ "&&" _ exp_comp {% infixOp %}

exp_comp -> exp_sum {% id %}
    | exp_comp _ "<"    _ exp_sum {% infixOp %}
    | exp_comp _ ">"    _ exp_sum {% infixOp %}
    | exp_comp _ "<="   _ exp_sum {% infixOp %}
    | exp_comp _ ">="   _ exp_sum {% infixOp %}
    | exp_comp _ "=="   _ exp_sum {% infixOp %}
    | exp_comp _ "!="   _ exp_sum {% infixOp %}
    | exp_comp _ "eq"   _ exp_sum {% infixOp %}
    | exp_comp _ "neq"  _ exp_sum {% infixOp %}
    | exp_comp _ "like" _ exp_sum {% infixOp %}
    | exp_comp _ "><"   _ exp_sum {% infixOp %}
    | exp_comp _ "<=>"  _ exp_sum {% infixOp %}
    | exp_comp _ "cmp"  _ exp_sum {% infixOp %}

exp_sum -> exp_product {% id %}
    | exp_sum _ "+" _ exp_product {% infixOp %}
    | exp_sum _ "-" _ exp_product {% infixOp %}

exp_product -> MemberExpression {% id %}
    | exp_product _ "*" _ MemberExpression {% infixOp %}
    | exp_product _ "/" _ MemberExpression {% infixOp %}
    | exp_product _ "%" _ MemberExpression {% infixOp %}

MemberExpression -> PrimaryExpression {% id %}
    | MemberExpression _ "[" _ Expression _ "]"
    | MemberExpression _ "{" _ Expression _ "}"
    | MemberExpression _ "." _ Identifier

PrimaryExpression ->
      Identifier {% id %}
    | Literal {% id %}
    | "(" _ Expression _ ")" {% getN(2) %}
    | Function {% id %}
    | Application {% id %}

Literal ->
      String {% id %}
    | Number {% id %}
    | Boolean {% id %}
    | RegExp {% id %}
    | Chevron {% id %}
    | Array {% id %}
    | Map {% id %}

Expression_list -> null {% noopArr %}
    | Expression {% idArr %}
    | Expression_list _ "," _ Expression {% concatArr(4) %}

################################################################################
# Functions

Function -> "function" _ "(" _ function_params _ ")" _ "{" _ Statement_list _ "}" {%
  function(data, start){
    return {
      loc: {start: start, end: last(data)},
      type: 'Function',
      params: data[4],
      body: data[10]
    };
  }
%}

function_params ->
    null {% noopArr %}
    | Identifier {% idArr %}
    | function_params _ "," _ Identifier {% concatArr(4) %}

Application -> MemberExpression _ "(" _ Expression_list _ ")" {%
  function(data, start){
    return {
      loc: {start: start, end: last(data)},
      type: 'Application',
      callee: data[0],
      args: data[4]
    };
  }
%}

################################################################################
# Literal Datastructures

Array -> "[" _ Expression_list _ "]" {%
  function(data, loc){
    return {
      type: 'Array',
      loc: {start: loc, end: last(data)},
      value: data[2]
    };
  }
%}

Map -> "{" _ map_kv_pairs _ "}" {%
  function(data, loc){
    return {
      loc: {start: loc, end: last(data)},
      type: 'Map',
      value: data[2]
    };
  }
%}

map_kv_pairs -> null {% noopArr %}
    | map_kv_pair {% idArr %}
    | map_kv_pairs _ "," _ map_kv_pair {% concatArr(4) %}

map_kv_pair -> String _ ":" _ Expression {%
  function(data, start){
    return {
      loc: {start: start, end: data[4].loc.end},
      type: 'MapKeyValuePair',
      key: data[0],
      value: data[4]
    };
  }
%}

################################################################################
# Literals

Boolean -> "true"
         | "false"

Identifier -> "overrided"
String -> "overrided"
Chevron -> "overrided"
RegExp -> "overrided"
Number -> "overrided"
PositiveInteger -> "overrided"

################################################################################
# Utils

_  -> " "
__ -> " "
