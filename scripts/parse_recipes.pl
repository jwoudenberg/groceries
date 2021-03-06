#!/usr/bin/env swipl

:- set_prolog_flag(verbose, silent).
:- set_test_options([load(never)]).
:- initialization(main).
:- use_module(lib/recipe_parsing).

main :-
  current_prolog_flag(argv, Argv),
  open('recipes.pl', write, Stream),
  format(Stream, ":- module(recipes, [portions/2, contains/2]).~n", []),
  format(Stream, ":- style_check(-discontiguous).~n~n", []),
  maplist(parse_recipe(Stream), Argv),
  close(Stream),
  halt.
main :-
  halt(1).
