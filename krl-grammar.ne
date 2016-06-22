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

rule -> "rule" __ Identifier _ "{" _
  "select" __ "when" __ EventExpression ";"

  ("pre" _ declaration_block _ ):?

  (RuleActionBlock _):?

  (RulePostlude _):?

"}"

################################################################################
#
# EventExpression
#

EventExpression -> event_exp_within

event_exp_within -> event_exp_or
    | event_exp_within __ "within" __ PositiveInteger __ time_period

event_exp_or -> event_exp_and
    | event_exp_or __ "or" __ event_exp_and

event_exp_and -> event_exp_infix_op
    | event_exp_and __ "and" __ event_exp_infix_op

event_exp_infix_op -> event_exp_fns
    | event_exp_infix_op __ "before" __ event_exp_fns
    | event_exp_infix_op __ "then"   __ event_exp_fns
    | event_exp_infix_op __ "after"  __ event_exp_fns

event_exp_fns -> event_exp_base
    | event_exp_fns __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ ")"
    | event_exp_fns __ "not" __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ ")"
    | "any" __ PositiveInteger _ "(" _ EventExpression_list _ ")"
    | "count" __ PositiveInteger _ "(" _ EventExpression _ ")"
    | "repeat" __ PositiveInteger _ "(" _ EventExpression _ ")"
    | event_exp_fns __  "max" _ "(" _ function_params _ ")"
    | event_exp_fns __  "min" _ "(" _ function_params _ ")"
    | event_exp_fns __  "sum" _ "(" _ function_params _ ")"
    | event_exp_fns __  "avg" _ "(" _ function_params _ ")"
    | event_exp_fns __  "push" _ "(" _ function_params _ ")"

event_exp_base ->
    Identifier __ Identifier
    __
    event_exp_attribute_pairs
    (__ "where" __ Expression):?
    (__ "setting" _ "(" _ function_params _ ")"):?

event_exp_attribute_pairs -> null
    | event_exp_attribute_pair
    | event_exp_attribute_pairs __ event_exp_attribute_pair

event_exp_attribute_pair -> Identifier __ RegExp

EventExpression_list -> EventExpression
    | EventExpression_list _ "," _ EventExpression

time_period -> time_period_enum

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

RuleActionBlock -> ("if" __ Expression __ "then" __ (action_block_type __):?):? RuleActions

action_block_type -> "choose"
    | "every"

#NOTE - there must be at least one action
RuleActions -> RuleAction
    | RuleActions __ RuleAction

RuleAction ->
    (Identifier _ "=>" _):?
    Identifier _ "(" _ Expression_list _ ")"
    (_ "with" __ declaration_list):?

################################################################################
#
# RulePostlude
#

RulePostlude ->
      "always" _ postlude_clause
    | "fired" _ postlude_clause
      (_ "else" _ postlude_clause):?
      (_ "finally" _ postlude_clause):?

postlude_clause -> "{" _ Statement_list _ "}"

################################################################################
#
# Statements
#

Statement ->
      ExpressionStatement
    | Declaration

ExpressionStatement -> Expression

Declaration -> left_side_of_declaration _ "=" _ Expression

# Later we may add destructuring
left_side_of_declaration -> Identifier

Statement_list -> Statement
    | Statement_list _ ";" _ Statement

declaration_block -> "{" _ declaration_list _ "}"

declaration_list -> Declaration
    | declaration_list __ Declaration

################################################################################
#
# Expressions
#

Expression -> exp_conditional

exp_conditional -> exp_or
    | exp_or _ "=>" _ exp_or _ "|" _ exp_conditional

exp_or -> exp_and
    | exp_or _ "||" _ exp_and

exp_and -> exp_comp
    | exp_and _ "&&" _ exp_comp

exp_comp -> exp_sum
    | exp_comp _ "<"    _ exp_sum
    | exp_comp _ ">"    _ exp_sum
    | exp_comp _ "<="   _ exp_sum
    | exp_comp _ ">="   _ exp_sum
    | exp_comp _ "=="   _ exp_sum
    | exp_comp _ "!="   _ exp_sum
    | exp_comp _ "eq"   _ exp_sum
    | exp_comp _ "neq"  _ exp_sum
    | exp_comp _ "like" _ exp_sum
    | exp_comp _ "><"   _ exp_sum
    | exp_comp _ "<=>"  _ exp_sum
    | exp_comp _ "cmp"  _ exp_sum

exp_sum -> exp_product
    | exp_sum _ "+" _ exp_product
    | exp_sum _ "-" _ exp_product

exp_product -> MemberExpression
    | exp_product _ "*" _ MemberExpression
    | exp_product _ "/" _ MemberExpression
    | exp_product _ "%" _ MemberExpression

MemberExpression -> PrimaryExpression
    | MemberExpression _ "[" _ Expression _ "]"
    | MemberExpression _ "{" _ Expression _ "}"
    | MemberExpression _ "." _ Identifier

PrimaryExpression ->
      Identifier
    | Literal
    | Function
    | Application

Literal ->
      String
    | Number
    | Boolean
    | RegExp
    | Chevron
    | Array
    | Map

Expression_list -> null
    | Expression
    | Expression_list _ "," _ Expression

################################################################################
# Functions

Function -> "function" _ "(" _ function_params _ ")" _ "{" _ Statement_list _ "}"

function_params ->
    null
    | Identifier
    | function_params _ "," _ Identifier

Application -> MemberExpression _ "(" _ Expression_list _ ")"

################################################################################
# Literal Datastructures

Array -> "[" _ Expression_list _ "]"

Map -> "{" _ map_kv_pairs _ "}"

map_kv_pairs -> null
    | map_kv_pair
    | map_kv_pairs _ "," _ map_kv_pair

map_kv_pair -> String _ ":" _ Expression

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

_  -> null
__ -> " "
