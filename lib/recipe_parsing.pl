% Parsing ingredients from markdown recipe files into a knowledge base.

:- module(recipe_parsing, [parse_recipe/1, parse_recipe/2]).
:- asserta(user:file_search_path(library, 'packs/markdown/prolog')).
:- use_module(library(md/md_parse)).

parse_recipe(Path) :-
  open("/dev/stdout", append, Stream),
  parse_recipe(Stream, Path),
  close(Stream).

parse_recipe(Stream, Path) :-
  (
    md_parse_file(Path, Blocks),
    parse_name(Name, Blocks),
    parse_portions(Portions, Blocks),
    parse_ingredients(Ingredients, Blocks)
  ) ->
  (
    write_fact(Stream, portions(Name, Portions)),
    maplist(write_ingredient(Stream, Name), Ingredients),
    format(Stream, "~n", [])
  );
  (
    format("Failed to parse ~w~n", [Path])
  ).

write_ingredient(Stream, Name, Ingredient) :-
  write_fact(Stream, contains(Name, Ingredient)).

write_fact(Stream, Term) :-
  format(Stream, '~q.~n', Term).

parse_name(Name, Blocks) :-
  member(h1(Name), Blocks).

% This rule makes the following assumptions about the recipe markdown:
%
% - The markdown contains a single unordered list.
% - All the items in that list are separate ingredients.
parse_ingredients(Ingredients, Blocks) :-
  member(ul(LiIngredients), Blocks),
  maplist(unwrap, LiIngredients, IngredientStrings),
  maplist(parse_ingredient, IngredientStrings, Ingredients).

parse_portions(Portions, Blocks) :-
  member(p([\[PortionsLine]]), Blocks),
  sub_string(PortionsLine, _, _, _, PortionsWord),
  number_string(Portions, PortionsWord).
parse_portions(1, _).

unwrap(Html, Contents) :-
  Html = li(Wrapped) ->
  unwrap(Wrapped, Contents);
  Html = p(Wrapped) ->
  unwrap(Wrapped, Contents);
  Html = \Wrapped ->
  unwrap(Wrapped, Contents);
  maplist(unwrap, Html, Results) ->
  atomics_to_string(Results, '', Contents);
  Html = Contents.

:- begin_tests(parse_ingredient).

test(with_unit) :-
  parse_ingredient("200 g fluffy bits, thinly sliced", ingredient(200, g, "fluffy bits")).

test(with_unit_attached) :-
  parse_ingredient("200g fluffy bits, thinly sliced", ingredient(200, g, "fluffy bits")).

test(without_unit) :-
  parse_ingredient("200 fluffy bits, thinly sliced", ingredient(200, "fluffy bits")).

test(without_quantity) :-
  parse_ingredient("fluffy bits, thinly sliced", ingredient("fluffy bits")).

:- end_tests(parse_ingredient).

parse_ingredient(String, I) :-
  (
    split_string(String, " ", "", [QuantityWord, UnitWord | IngredientWords]),
    atom_string(Unit, UnitWord),
    unit(Unit)
  ) ->
  (
    number_string(Quantity, QuantityWord),
    atomics_to_string(IngredientWords, ' ', DirtyIngredient),
    up_to_comma(DirtyIngredient, Ingredient),
    I = ingredient(Quantity, Unit, Ingredient)
  );
  (
    split_string(String, " ", "", [QuantityWord | IngredientWords]),
    quantity_with_unit(QuantityWord, Quantity, Unit)
  ) ->
  (
    atomics_to_string(IngredientWords, ' ', DirtyIngredient),
    up_to_comma(DirtyIngredient, Ingredient),
    I = ingredient(Quantity, Unit, Ingredient)
  );
  (
    split_string(String, " ", "", [QuantityWord | IngredientWords]),
    number_string(Quantity, QuantityWord)
  ) ->
  (
    atomics_to_string(IngredientWords, ' ', DirtyIngredient),
    up_to_comma(DirtyIngredient, Ingredient),
    I = ingredient(Quantity, Ingredient)
  );
  (
    up_to_comma(String, Ingredient),
    I = ingredient(Ingredient)
  ).

% Provide the part of the sentence up to the first comma.
up_to_comma(Sentence, UpToComma) :-
  split_string(Sentence, ",", "", [UpToComma|_]) ->
    true;
    Sentence = UpToComma.

quantity_with_unit(String, Quantity, Unit) :-
  string_concat(QuantityString, UnitString, String),
  atom_string(Unit, UnitString),
  unit(Unit),
  number_string(Quantity, QuantityString).

unit(g).
unit(kg).
