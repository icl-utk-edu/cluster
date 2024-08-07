if [[ ! $USER = "root" ]]; then
   . /apps/spacks/current/share/spack/setup-env.sh
   export MODULEPATH=/apps/rocm/Modulefiles:$MODULEPATH
fi

