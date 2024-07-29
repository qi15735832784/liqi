get_ps1()
{
if [ "$?" = "0" ]
then
        export PS1="\[\e[1;32m\][^_^]\[\e[m\][\u@\h \[\e[1;32m\]\w\[\e[m\]]\\$ "
else
        export PS1="\[\e[1;31m\][T_T]\[\e[m\][\[\e[1;31m\]\u\[\e[m\]\[\e[1;34m\]@\[\e[m\]\[\e[1;35m\]\h \[\e[1;31m\]\w\[\e[m\]\[\e[m\]]\\$ \[\e[m\]"
fi
}
PROMPT_COMMAND=get_ps1
