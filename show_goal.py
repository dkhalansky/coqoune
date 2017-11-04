import sys

from collections import deque, namedtuple

Ok = namedtuple('Ok', ['val', 'msg'])
Err = namedtuple('Err', ['err'])

Inl = namedtuple('Inl', ['val'])
Inr = namedtuple('Inr', ['val'])

StateId = namedtuple('StateId', ['id'])
Option = namedtuple('Option', ['val'])

OptionState = namedtuple('OptionState', ['sync', 'depr', 'name', 'value'])
OptionValue = namedtuple('OptionValue', ['val'])

Status = namedtuple('Status', ['path', 'proofname', 'allproofs', 'proofnum'])

Goals = namedtuple('Goals', ['fg', 'bg', 'shelved', 'given_up'])
Goal = namedtuple('Goal', ['id', 'hyp', 'ccl'])
Evar = namedtuple('Evar', ['info'])


def goals_to_string(goals):
    global info_msg
    str_out = ""

    response = goals

    if response.msg is not None:
        info_msg = response.msg


    if response.val.val is None:
        str_out += 'No goals.'
        return

    goals = response.val.val

    sub_goals = goals.fg

    unfocus_goals = goals.bg

    nb_subgoals = len(sub_goals)


    if nb_subgoals == 0:
        nb_unfocusgoals = 0
        for unfocus_goal in enumerate(unfocus_goals):
            if unfocus_goal[1][1]:
                nb_unfocusgoals += 1

        if nb_unfocusgoals == 0:
            str_out += "No more subgoals."

        else:
            str_out += "This subproof is complete, but there are some unfocused goals:\n\n"

            for idx, unfocus_goal in enumerate(unfocus_goals):
                if unfocus_goal[1] != []:
                    id = 0
                    hyps = unfocus_goal[1][0].hyp
                    ccl = unfocus_goal[1][0].ccl
                    str_out += "______________________________________( " + str(id + 1) + " / " + str(nb_unfocusgoals) + " )\n"
                    id += 1
                    lines = list(map(lambda s: s.encode('utf-8'), ccl.split('\n')))
                    for line in lines:
                        str_out += line.decode('utf-8') + '\n'

    else:
        plural_opt = '' if nb_subgoals == 1 else 's'
        str_out += str(nb_subgoals) + ' subgoal' + str(plural_opt) + '\n'

        for idx, sub_goal in enumerate(sub_goals):
            _id = sub_goal.id
            hyps = sub_goal.hyp
            ccl = sub_goal.ccl
            if idx == 0:
                # we print the environment only for the current subgoal
                for hyp in hyps:
                    lst = list(map(lambda s: s.encode('utf-8'), hyp.split('\n')))
                    for ls in lst:
                        str_out += ls.decode('utf-8') + '\n'

            str_out += "______________________________________( " + str(idx + 1) + " / " + str(nb_subgoals) + " )\n"
            lines = list(map(lambda s: s.encode('utf-8'), ccl.split('\n')))
            for line in lines:
                str_out += line.decode('utf-8') + '\n'

    return str_out

a = eval(sys.argv[1])
print(goals_to_string(a))
