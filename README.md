Chef-mode is an Emacs minor mode to make editing
[Opscode Chef](http://www.opscode.com/chef/)
[repositories](http://docs.opscode.com/essentials_repository.html)
easier.

It defines a minor mode, chef-mode, and a corresponding
global-chef-mode, with three keybindings:

* C-c C-c (M-x chef-knife-dwim) - when editing part of chef repository
(cookbook, data bag item, node/role/environment definition), uploads
that part to the Chef Server by calling appropriate knife command
* C-c C-k (M-x knife) - runs a user-specified knife command
* C-c C-d (M-x chef-resource-lookup) - When the cursur is on a
  resource command it opens a browser with the resource doc from the
  wiki. When the cursor is anywhere else it opens the main resource
  api page.

The library detects bundler and, if Gemfile is present on top-level of
the Chef repository, runs 'bundle exec knife' instead of plain
'knife'.

If `chef-use-rvm` is non-nil, it talks with
[rvm.el](https://github.com/senny/rvm.el) to use proper Ruby and
gemset.
