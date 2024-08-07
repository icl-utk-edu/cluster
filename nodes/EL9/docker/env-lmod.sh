if [[ ! $USER = "root" ]]; then
   . /apps/spacks/current/opt/spack/*/*/lmod-*/lmod/lmod/init/profile
   export MODULEPATH=/apps/rocm/Modulefiles:/apps/spacks/current/share/spack/lmod/linux-rocky9-x86_64/Core
fi

