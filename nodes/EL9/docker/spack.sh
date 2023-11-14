if [[ ! $USER = "root" ]]; then
   . /apps/spacks/current/share/spack/setup-env.sh
   #export MODULEPATH=`ls -d /apps/spacks/current/share/spack/modules/linux-*/`
   # The previous export is probably not needed and will cause problems when 
   # multiple OS versions are installed into the same spack instance.
fi

