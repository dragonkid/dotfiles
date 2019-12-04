#!/usr/bin/env zsh

[[ -z $VIRTUALENVWRAPPER_HOOK_DIR ]] && echo 'have no virtualenwrapper...'

# enable virtualenvwrapper_show_workon_options
. /usr/local/bin/virtualenvwrapper.sh


function fix_venv {
    activate=${VIRTUALENVWRAPPER_HOOK_DIR}/${env}/bin/activate
    if [ ! -f "$activate" ]
    then
        echo "environment $env have no activate script..."
        return 1
    fi
    source "$activate"
    if [[ "`python --version 2>&1`" != *'Library not loaded'*  ]]
    then
        return
    fi

    echo 'fixing '$1
    if [[ "$(ls -l `which python`)" == *'python2'* ]]
    then
        cd ${VIRTUALENVWRAPPER_HOOK_DIR}/${env} 2>/dev/null
        gfind . -type l -xtype l -delete && /usr/local/bin/virtualenv -p /usr/local/bin/python2 .
    else
        cd ${VIRTUALENVWRAPPER_HOOK_DIR}/${env} || true
        gfind . -type l -xtype l -delete && /usr/local/bin/virtualenv -p /usr/local/bin/python3 .
    fi
}


for env in $(virtualenvwrapper_show_workon_options);
    do fix_venv $env
done
