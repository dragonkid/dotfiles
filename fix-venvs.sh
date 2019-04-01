#!/usr/bin/env zsh

[[ -z $VIRTUALENVWRAPPER_HOOK_DIR ]] && echo 'have no virtualenwrapper...'

# enable virtualenvwrapper_show_workon_options
. /usr/local/bin/virtualenvwrapper.sh


function fix_venv {
    echo 'fixing '$1
    activate=${VIRTUALENVWRAPPER_HOOK_DIR}/${env}/bin/activate
    if [ ! -f "$activate" ]
    then
        echo "environment $env have no activate script..."
        return 1
    fi
    source "$activate"
    if [ $(python --version) = $(python2 --version) ]
    then
        cd ${VIRTUALENVWRAPPER_HOOK_DIR}/${env} && gfind . -type l -xtype l -delete
        virtualenv -p python2 .
    else
        cd ${VIRTUALENVWRAPPER_HOOK_DIR}/${env} && gfind . -type l -xtype l -delete
        virtualenv .
    fi
}


for env in $(virtualenvwrapper_show_workon_options);
    do fix_venv $env
done
