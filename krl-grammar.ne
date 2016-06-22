main -> ruleset

################################################################################
#
# Ruleset
#

ruleset_list -> ruleset
    | ruleset_list _ ";" _ ruleset

ruleset -> "ruleset" __ Identifier _ "{" _
  "meta{author \"KaRL42\"}" _
  ("global" _ declaration_block _):?
  (rule _):+
loc_close_curly

ruleset_meta_block -> "{" _ "}"
    | "{" _ ruleset_meta_prop_list _ "}"

ruleset_meta_prop_list -> ruleset_meta_prop
    | ruleset_meta_prop_list __ ruleset_meta_prop

ruleset_meta_prop -> Keyword __ Expression

Keyword -> [a-zA-Z_$] [a-zA-Z0-9_$]:*

################################################################################
#
# Rule
#

rule -> "rule" __ Identifier (__ "is" __ rule_state):? _ "{" _
  (RuleSelect _semi):?

  RuleBody

loc_close_curly

rule_state -> "active"  | "inactive"

RuleBody -> null
    | RulePrelude _

    | RuleActionBlock _

    | RulePrelude _ RuleActionBlock _

    | RulePostlude _

    | RulePrelude _ RulePostlude _

    | RuleActionBlock __ RulePostlude _

    | RulePrelude _ RuleActionBlock __ RulePostlude _


RuleSelect -> "select" __ "when" __ EventExpression

RulePrelude -> "pre" _ declaration_block

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
    | event_exp_fns __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ loc_close_paren

    | event_exp_fns __ "not" __ "between" _ "(" _ EventExpression _ "," _ EventExpression _ loc_close_paren

    | "any" __ PositiveInteger _ "(" _ EventExpression_list _ loc_close_paren

    | "count" __ PositiveInteger _ "(" _ EventExpression _ loc_close_paren

    | "repeat" __ PositiveInteger _ "(" _ EventExpression _ loc_close_paren

    | event_exp_fns __  "max" _ "(" _ function_params _ loc_close_paren

    | event_exp_fns __  "min" _ "(" _ function_params _ loc_close_paren

    | event_exp_fns __  "sum" _ "(" _ function_params _ loc_close_paren

    | event_exp_fns __  "avg" _ "(" _ function_params _ loc_close_paren

    | event_exp_fns __  "push" _ "(" _ function_params _ loc_close_paren


event_exp_base -> "(" _ EventExpression _ ")"
  | Identifier __ Identifier
    (__ event_exp_attribute_pairs):?
    (__ "where" __ event_exp_where):?
    (__ "setting" _ "(" _ function_params _ loc_close_paren):?

event_exp_attribute_pairs -> event_exp_attribute_pair
    | event_exp_attribute_pairs __ event_exp_attribute_pair

event_exp_attribute_pair -> Identifier __ RegExp

event_exp_where -> Expression

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
    Identifier _ "(" _ Expression_list _ loc_close_paren
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


postlude_clause -> "{" _ Statement_list _ loc_close_curly

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

Statement_list -> null
    | Statement
    | Statement_list _ ";" _ Statement

declaration_block -> "{" _ "}"
    | "{" _ declaration_list _ "}"

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
    | exp_comp _  "<"    _ exp_sum
    | exp_comp _  ">"    _ exp_sum
    | exp_comp _  "<="   _ exp_sum
    | exp_comp _  ">="   _ exp_sum
    | exp_comp _  "=="   _ exp_sum
    | exp_comp _  "!="   _ exp_sum
    | exp_comp __ "eq"   __ exp_sum
    | exp_comp __ "neq"  __ exp_sum
    | exp_comp __ "like" __ exp_sum
    | exp_comp __ "><"   __ exp_sum
    | exp_comp __ "<=>"  __ exp_sum
    | exp_comp __ "cmp"  __ exp_sum

exp_sum -> exp_product
    | exp_sum _ "+" _ exp_product
    | exp_sum _ "-" _ exp_product

exp_product -> MemberExpression
    | exp_product _ "*" _ MemberExpression
    | exp_product _ "/" _ MemberExpression
    | exp_product _ "%" _ MemberExpression

MemberExpression -> PrimaryExpression
    | MemberExpression _ "[" _ Expression _ loc_close_square

    | MemberExpression _ "{" _ Expression _ loc_close_curly

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

Function -> "function" _ "(" _ function_params _ ")" _ "{" _ Statement_list _ loc_close_curly

function_params ->
    null
    | Identifier
    | function_params _ "," _ Identifier

Application -> MemberExpression _ "(" _ Expression_list _ loc_close_paren

################################################################################
# Literal Datastructures

Array -> "[" _ Expression_list _ loc_close_square

Map -> "{" _ map_kv_pairs _ loc_close_curly

map_kv_pairs -> null
    | map_kv_pair
    | map_kv_pairs _ "," _ map_kv_pair

map_kv_pair -> String _ ":" _ Expression

################################################################################
# Literals

Identifier -> [a-zA-Z_$] [a-zA-Z0-9_$]:*

Boolean -> "true"
         | "false"

PositiveInteger -> [0-9]:+

Number -> number

number ->
    float
    | "+" float
    | "-" float

float ->
    int
    | "." int
    | int "." int

int -> [0-9]:+

RegExp -> "re#" regexp_pattern "#" regexp_modifiers

regexp_pattern ->
    null
    | regexp_pattern regexp_pattern_char

regexp_pattern_char ->
  [^\\#]
  | "\\" [^]

regexp_modifiers -> regexp_modifiers_chars

regexp_modifiers_chars -> null
    | "i" | "g" | "ig" | "gi"

Chevron -> "<<" chevron_body loc_close_chevron

chevron_body ->
    chevron_string_node
    | chevron_body beesting chevron_string_node

beesting -> "#{" _ Expression _ "}"

chevron_string_node -> chevron_string

chevron_string ->
    null
    | chevron_string chevron_char

chevron_char ->
    [^>#]
    | "#" [^{]
    | ">" [^>]

String -> "\"" string "\""

string -> null
    | string stringchar

stringchar ->
      [^\\"]
    | "\\" [^]

################################################################################
# Utils

# Chars that return their end location
loc_close_curly -> "}"
loc_close_square -> "]"
loc_close_paren -> ")"
loc_close_chevron -> ">>"

# Whitespace and Semi-colons
_  -> null
__ -> " "

##optional space and/or semi-colon
_semi -> ";"

##required space and/or semi-colon
__semi -> ";"
#if you must have semi-colon, use ";" directly
