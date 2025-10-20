
if [ $USER != "root" ]; then
   SRC=/apps/spacks/2025-08-22
   source `ls $SRC/opt/spack/linux-x86_64/lmod-*/lmod/lmod/init/bash | head -1`
   export MODULEPATH=$SRC/share/spack/modules/envs:/apps/rocm/Modulefiles
   module load env
fi

