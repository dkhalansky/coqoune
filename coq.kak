# https://coq.inria.fr/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*\.v %{
    set buffer filetype coq
}

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/ regions -default code coq \
    string    "'"    "'"   '' \
    comment   \(\*\*r   \*\)    '' \
    comment   \(\*\*    \*\)    '' \
    comment   \(\*      \*\)    ''

add-highlighter shared/coq/string fill string
add-highlighter shared/coq/comment fill string


add-highlighter shared/coq/code regex %{\b(Declare|Type|Canonical|Structure|Cd|Coercion|Derive|Drop|Existential)\b} 0:value
add-highlighter shared/coq/code regex %{\b(Scheme|Back|Combined)\b} 0:value
add-highlighter shared/coq/code regex %{\b(Show|About|Print)\b} 0:value
add-highlighter shared/coq/code regex %{\b(Export|Import)\b} 0:value
add-highlighter shared/coq/code regex %{\b(Implicits|Script|Tree|Conjectures|Intros|Existentials|forall)\b} 0:value
add-highlighter shared/coq/code regex %{\b(Theorem|Proof|Qed|Defined|Save)\b} 0:value

# Declare Type Canonical Structure Cd Coercion Derive Drop Existential
# Functional Scheme Back Combined
# Show About Print
# Export Import
# Implicits Script Tree Conjectures Intros Existentials forall
# Proof Qed Defined Save 


#add-highlighter shared/coq/code regex %{\b()\b} 0:type


add-highlighter shared/coq/code regex %{\b(positive)\b} 0:keyword


#add-highlighter shared/coq/code regex %{\b()\b} 0:attribute


# Commands
# ‾‾‾‾‾‾‾‾

# no one

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# only one line - its ok
# hook -group coq-highlight global WinSetOption filetype=coq %{ add-highlighter window ref coq }

# all is ok
# read https://github.com/mawww/kakoune/wiki/Lint

hook -group coq-highlight global WinSetOption filetype=coq %{ add-highlighter window ref coq }
hook -group coq-highlight global WinSetOption filetype=(?!coq).* %{ remove-highlighter window/coq }

hook global WinSetOption filetype=(?!coq).* %{
    remove-hooks window coq-hooks
    remove-hooks window coq-indent
}
