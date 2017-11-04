Coqoune
=======

Implementation of means of working with Coq using the kakoune text editor.

Installing
----------

This was tested with `coqtop 8.7.0` and `kakoune` with commit hash
`39e63cf518074564992614c117d9e40a9011c425`.

After installing Coq, ensure that `coqtop` is in your `$PATH`.

Put `coqtop_daemon.py` and `show_goal.py` to your home directory, put
`coqoune.kak` and `coq.kak` to the directory from which your setup of kakoune
reads its plugins. By default it's `/usr/local/share/kakoune/rc/extra` but the
location can differ depending on your operating system and package manager.

Using
-----

Start `tmux`. Inside, start `kak`. Launch Coq with `:coq-init`. Then use
`:coq-next` to prove the next statement that isn't yet proven or
`:coq-to-cursor` to prove everything up to the position of your cursor.
