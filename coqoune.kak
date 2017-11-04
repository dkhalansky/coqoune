# https://coq.inria.fr/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Sorry, Verilog! *.v is ours.
hook global BufCreate .*\.v %{
    set buffer filetype coq
}

# Variables
# ‾‾‾‾‾‾‾‾‾

decl -docstring "Port of coqtop" int coqtop_port 0
decl -docstring "Location of coqtop.py" str coqtop_daemon %sh{echo ~/coqtop_daemon.py}
decl -docstring "Location of show_goal.py" str coq_show   %sh{echo ~/show_goal.py}
decl -hidden -docstring "Last checked position" range-specs coq_proven
decl -hidden -docstring "Last checked position" range-specs coq_error
decl -hidden -docstring "Previously proven contents" str-list coq_sentences
decl -hidden -docstring "Contents to be proven" str-list coq_sentences_new
decl -hidden -docstring "Timestamp of the last check" int coq_last_checked

# Hidden commands
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

def -hidden coq-update-info %[
    %sh{
        res=$(echo 'goals()' | ncat localhost ${kak_opt_coqtop_port})
        str=$(python ${kak_opt_coq_show} "$res" | tr '\n' '\r' | sed 's/\r/<ret>/g')
        echo "exec -buffer *coq_goals* '%da$str<ret><esc>'"
    }
]

def -hidden coq-launch %[
    set current coq_proven 0:
    set current coq_sentences ""
    %sh{
        tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/coqoune.XXXXXXXX")
        port_file=${tmpdir}/port_file
        touch ${port_file}
        err=${tmpdir}/err
        mkfifo "$err"
        (python ${kak_opt_coqtop_daemon} "$port_file" "$err") \
            > /dev/null 2> /dev/null < /dev/null &
        while [ -z "$(cat "$port_file")" ]; do :; done
        port=$(cat $port_file)
        echo "set current coqtop_port $port"
        rm "$port_file"
        echo "eval -try-client '$kak_opt_toolsclient' %{
                eval -draft %{
                    edit! -fifo ${err} -debug -scroll *coqtop-output*
                }
                hook -group fifo buffer BufCloseFifo .* %{
                    nop %sh{ rm -r ${tmpdir} }
                    remove-hooks buffer fifo
                }
            }"
    }
]

def -hidden coq-go-to-next-dot %[
    %sh{
        last_char=$(echo "${kak_selection}" | tr -d '\n' | tail -c 1)
        printf ".*+-\n" | grep -q "$last_char" || echo 'exec "f.;"'
    }
]

def -hidden coq-make-three-panels %[
    %sh{
        cmd() { echo "edit -scratch *coq_$1*; set buffer filetype coq_$1"; }
        tmux=${kak_client_env_TMUX:-$TMUX}
        vert_new="${tmux:+tmux-new-vertical}"
        vert_new="${vert_new:-new}"
        echo "new $(cmd goals)"
        echo "$vert_new $(cmd errors)"
    }
]

def -hidden coq-select-sentences %[
    exec 's[^.]*\.|[*+-]\s*<ret>S\A\s*<ret>S\A[*+-]\s*<ret><a-K>\A\s\z<ret>'
]

def -hidden coq-apply-diff %[
    exec ';'
    reg o "%val{selection_desc}"
    exec 'Gg'
    coq-select-sentences
    set current coq_sentences_new "%val{selections}"
    %sh{
        old=$(printf "%s\n" ${kak_opt_coq_sentences}     | sed 's/\\:/#!/g')
        new=$(printf "%s\n" ${kak_opt_coq_sentences_new} | sed 's/\\:/#!/g')
        nsl="${kak_selections_desc}:"
        old="${old}:"
        new="${new}:"
        differ=0
        i=0
        while [ -n "${old%:}" ]; do
            if [ "$differ" = 0 -a "${new%%:*}" != "${old%%:*}" ]; then
                differ=1
                i=1
            elif [ "$differ" = 1 ]; then
                i=$((i+1))
            else
                nsl="${nsl#*:}"
                new="${new#*:}"
            fi
            old="${old#*:}"
        done
        if [ "$differ" = 1 -a "$i" != 0 ]; then
            echo "rewind($i)" |
                ncat localhost ${kak_opt_coqtop_port} \
                    > /dev/null 2> /dev/null
        fi
        if [ -n "$nsl" ]; then
            echo "select ${nsl%:}"
            echo "eval -itersel %{
                coq-advance
                nop %sh{echo 'goals()' | ncat localhost ${kak_opt_coqtop_port}}
            }"
        fi
    }
    select %reg{o}
    exec 'Gg'
    coq-select-sentences
    %sh{
        nsl=:"${kak_selections_desc}"
        last_removed=""
        error_str=""
        while echo 'goals()' | ncat localhost ${kak_opt_coqtop_port} | grep '^Err' > /dev/null; do
            [ -n "$error_str" ] || error_str=$(echo 'goals()' |
                ncat localhost ${kak_opt_coqtop_port} |
                sed 's;.*<pp>\(.*\)</pp>.*;\1;g' )
            echo 'rewind()' | ncat localhost ${kak_opt_coqtop_port} > /dev/null
            last_removed="${nsl##*:}"
            nsl="${nsl%:*}"
        done

        echo "exec -buffer *coq_errors* '%da$error_str<ret><esc>'"

        nsln=${nsl##*:}
        if [ -z "$nsln" ]; then
            proven=""
            echo "set current coq_sentences ''"
        else
            proven=1.1,${nsln%,*}"|Information"
            echo "select '${nsl#:}'"
            echo "set current coq_sentences %val{selections}"
        fi
        echo "set current coq_proven '${kak_timestamp}:$proven'"

        if [ -n "$last_removed" ]; then
            echo "set current coq_error '${kak_timestamp}:$last_removed|Error'"
        else
            echo "set current coq_error '${kak_timestamp}'"
        fi
    }
    coq-update-info
]

def -hidden coq-invalidate %[
    coq-go-to-last-proven
    coq-select-sentences
    set current coq_sentences_new "%val{selections}"
    %sh{
        old=$(printf "%s\n" "${kak_opt_coq_sentences}"     | sed 's/\\:/#!/g')
        new=$(printf "%s\n" "${kak_opt_coq_sentences_new}" | sed 's/\\:/#!/g')
        dsc=${kak_selections_desc}:
        osl=""
        old="${old}:"
        new="${new}:"
        differ=0
        i=0
        while [ -n "${old%:}" ]; do
            if [ "$differ" = 0 -a "${new%%:*}" != "${old%%:*}" ]; then
                differ=1
                i=1
            elif [ "$differ" = 1 ]; then
                i=$((i+1))
            else
                osl="${osl:+$osl:}${dsc%%:*}"
                new="${new#*:}"
                dsc="${dsc#*:}"
            fi
            old="${old#*:}"
        done
        if [ "$differ" = 1 -a "$i" != 0 ]; then
            echo "rewind($i)" |
                ncat localhost ${kak_opt_coqtop_port} \
                    > /dev/null 2> /dev/null
            if [ -n "$osl" ]; then
                proven="1.1,${osl##*,}|Information"
                echo "select $osl"
                echo "set current coq_proven '${kak_timestamp}:$proven'"
                echo "set current coq_sentences %val{selections}"
            else
                echo "set current coq_proven '${kak_timestamp}:'"
                echo "set current coq_sentences ''"
            fi
        fi
    }
    coq-update-info
]

def -hidden coq-advance %[
    nop %sh{
        query=$(printf 'advance("""%s""")\n' "${kak_selection}")
        echo "$query" | ncat localhost ${kak_opt_coqtop_port}
    }
]

def -hidden coq-go-to-last-proven %[
    %sh{
        sel="${kak_opt_coq_proven}"
        sel="${sel#*:}"
        sel="${sel%|*}"
        echo "select $sel"
    }
]

def -hidden coq-go-to-next-unproven %[
    %sh{
        sel="${kak_opt_coq_proven}"
        sel=${sel#*:}
        sel=${sel%|*}
        if [ -n "$sel" ]; then
            echo "select $sel"
            echo "try %{ exec e }"
        else
            echo "exec gg"
        fi
    }
]

# Commands
# ‾‾‾‾‾‾‾‾

def coq-init %[
    addhl buffer ranges coq_proven
    addhl buffer ranges coq_error
    hook window NormalIdle .* %{
        %sh{
            if [ "${kak_opt_coq_last_checked}" != "${kak_timestamp}" ]; then
                echo "try %{ eval -draft -save-regs '' coq-invalidate }"
            fi
        }
        set current coq_last_checked %val{timestamp}
    }
    coq-make-three-panels
    coq-launch
]

def coq-to-cursor %[
    eval -draft -save-regs '' %{
        coq-go-to-next-dot
        coq-apply-diff
    }
]

def coq-next %[
    eval -draft -save-regs '' %{
        coq-go-to-next-unproven
        coq-go-to-next-dot
        coq-to-cursor
    }
]
