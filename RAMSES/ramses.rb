unless defined? Ramses
  require './../lib/makefile.rb'

  # Generating RAMSES makefile, namelists and patches
  class Ramses
    def initialize(ndim, patch, ngroups=4)
      @mk = {
        nvector: { default: 32, rt: 64 },
        ndim: ndim,
        npre: 8, # Floating-point precision
        # # of vars of Hyperbolic solver (hydro: >=NDIM+2, mhd: >=8, rhd: >=5)
        nvar: { hydro: ndim + 2, mdh: 8, rhd: 5 },
        nener: 0, # # of energy vars used in hydro or mhd solver
        solver: { hydro: 'hydro', mhd: 'mhd', rhd: 'rhd' },
        patch: patch,
        grackle: false,
        exe: 'ramses',
        nions: 3, # Ionisation species, HII, HeII, and HeIII
        ngroups: ngroups # Number of photon groups
      }

      @ngroups = ngroups
    end

    def makefile(path, type, solver)
      m = Makefile.new

      m.set 'F90', 'mpif90 -frecord-marker=4 -O3 -ffree-line-length-none -g -fbacktrace'
      m.set 'FFLAGS', '-x f95-cpp-input $(DEFINES)'

      m.define 'NVECTOR', @mk[:nvector][type]
      m.define 'NDIM', @mk[:ndim]
      m.define 'NPRE', @mk[:npre]
      m.define 'NENER', @mk[:nener]
      m.define 'SOLVER', @mk[:solver][solver]
      m.define 'grackle', 1 if @mk[:grackle]

      if type == :rt
        m.define 'RT', 1 if type == :rt
        m.define 'NIONS', @mk[:nions]
        m.define 'NGROUPS', @mk[:ngroups]
        m.define 'NVAR', @mk[:nvar][solver] + @mk[:nions]
      else
        m.define 'NVAR', @mk[:nvar][solver]
      end

      m.set 'GRACKLE', @mk[:grackle] if @mk[:grackle]
      m.set 'PATCH', @mk[:patch]
      m.set 'EXEC', @mk[:exe]

      m.set 'GITBRANCH', '$(shell git rev-parse --abbrev-ref HEAD)'
      m.set 'GITHASH', "$(shell git log --pretty=format:'%H' -n 1)"
      m.set 'GITREPO', '$(shell git config --get remote.origin.url)'
      m.set 'BUILDDATE', "$(shell date +\"%D-%T\")"

      m.set 'MOD', 'mod'
      m.set 'LIBMPI', '-L/usr/lib -lmpi'

      if @mk[:grackle]
        m.set 'LIBS_GRACKLE', 'L$(HOME)/.local/lib -lgrackle -lhdf5 -lz -lgfortran -ldl'
        m.set 'LIBS_OBJ', '-I$(HOME)/.local/include -DCONFIG_BFLOAT_8 -DH5_USE_16_API -fPIC'
      end

      m.set 'LIBS', '$(LIBMPI) $(LIBS_GRACKLE)'
      m.set 'VPATH', '$(shell [ -z $(PATCH) ] || find $(PATCH) -type d):' \
        '../$(SOLVER):../aton:../hydro:../pm:../poisson:../amr:../io:../rt'

      m.set 'AMROBJ', _ls_obj('amr')
      m.set 'EXTRAOBJ', 'dump_utils.o write_makefile.o write_patch.o'
      m.set 'PMOBJ', _ls_obj('pm')
      m.set 'POISSONOBJ', _ls_obj('poisson')
      m.set 'HYDROOBJ', _ls_obj('hydro')
      m.set 'RTOBJ', _ls_obj('rt') if type == :rt

      # MODOBJ are just pre-required objects for compiling other source codes
      m.set 'MODOBJ', 'amr_parameters.o amr_commons.o random.o ' \
        'pm_parameters.o pm_commons.o poisson_parameters.o dump_utils.o ' \
        'poisson_commons.o hydro_parameters.o hydro_commons.o cooling_module.o ' \
        'bisection.o sparse_mat.o clfind_commons.o gadgetreadfile.o ' \
        'write_makefile.o write_patch.o write_gitinfo.o'
      if type == :rt
        m.extend 'MODOBJ', 'rt_parameters.o rt_hydro_commons.o coolrates_' \
          'module.o rt_spectra.o rt_cooling_module.o rt_flux_module.o'
      end
      m.extend 'MODOBJ', 'grackle_parameters.o' if @mk[:grackle]

      m.set 'AMRLIB', '$(AMROBJ) $(HYDROOBJ) $(PMOBJ) $(POISSONOBJ) $(EXTRAOBJ)'
      m.extend 'AMRLIB', '$(RTOBJ)' if type == :rt

      m.set 'ATON_MODOBJ', 'timing.o radiation_commons.o rad_step.o'
      m.set 'ATON_OBJ', _ls_obj('aton')
      m.extend 'ATON_OBJ', '../aton/atonlib/libaton.a'

      m.plain 'sinclude $(PATCH)/Makefile'

      m.rule 'ramses', '$(MODOBJ) $(AMRLIB) ramses.o',
        '$(F90) $(AMRLIB) -o $(EXEC)$(NDIM)d $(LIBS)',
        'rm write_makefile.f90 write_patch.f90'

      m.rule 'ramses_aton', '$(MODOBJ) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) ramses.o', \
        '$(F90) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) -o $(EXEC)$(NDIM)d $(LIBS) $(LIBCUDA)', \
        'rm write_makefile.f90 write_patch.f90'

      m.rule 'write_gitinfo.o', 'FORCE',
        "$(F90) $(FFLAGS) -DPATCH=\'\"$(PATCH)\"\' " \
        "-DGITBRANCH=\'\"$(GITBRANCH)\"\' -DGITHASH=\'\"$(GITHASH)\"\' " \
        "-DGITREPO=\'\"$(GITREPO)\"\' -DBUILDDATE=\'\"$(BUILDDATE)\"\' " \
        "-c ../amr/write_gitinfo.f90 -o $@"

      m.rule 'write_makefile.o', 'FORCE',
        '../utils/scripts/cr_write_makefile.sh $(MAKEFILE_LIST)',
        '$(F90) $(FFLAGS) -c write_makefile.f90 -o $@'

      m.rule 'write_patch.o', 'FORCE', \
        '../utils/scripts/cr_write_patch.sh $(PATCH)',
        '$(F90) $(FFLAGS) -c write_patch.f90 -o $@'

      m.rule '%.o', '%.F', '$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)'
      m.rule '%.o', '%.f90', '$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)'
      m.rule 'FORCE', '', ''
      m.rule 'clean', '', 'rm -f *.o *.$(MOD)'

      m.write(path)
    end

    def _ls_obj(dir)
      `cd #{Path.dev}/#{RAMSES}/#{dir} && ls *.f90`.gsub!("f90\n", 'o ')
    end
  end
end
