
if ( "$USER" != "root" ) then
   set SRC=/apps/spacks/2025-08-22
   source `ls $SRC/opt/spack/linux-x86_64/lmod-*/lmod/lmod/init/csh | head -1`
   setenv MODULEPATH ${SRC}/share/spack/modules/envs:/apps/rocm/Modulefiles
   module load env
endif

