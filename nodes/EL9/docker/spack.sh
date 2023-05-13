if [[ ! $USER = "root" ]]; then
   . /apps/spacks/current/share/spack/setup-env.sh
   export MODULEPATH=`ls -d /apps/spacks/current/share/spack/modules/linux-*/`
fi

