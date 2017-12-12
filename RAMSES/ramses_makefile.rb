def ramses_makefile(file, type, solver)
  File.open(file, "w") do |f|
    f.write("DEFINES = -DNVECTOR=#{@params[:nvector][type]}\n")
    f.write("DEFINES += -DNDIM=#{@params[:ndim]}\n")
    f.write("DEFINES += -DNPRE=#{@params[:npre]}\n")

    if type == :rt
      f.write("DEFINES += -DNIONS=#{@params[:nions]}\n")
      f.write("DEFINES += -DNGROUPS=#{@params[:ngroups]}\n")
      f.write("DEFINES += -DNVAR=#{@params[:nvar][solver] + @params[:nions]}\n")
    else
      f.write("DEFINES += -DNVAR=#{@params[:nvar][solver]}\n")
    end

    f.write("DEFINES += -DNENER=#{@params[:nener]}\n")
    f.write("DEFINES += -DSOLVER=#{@params[:solver][solver]}\n\n")

    f.write("DEFINES += -Dgrackle\n\n") if @params[:grackle]

    f.write("DEFINES += -DRT\n\n") if type == :rt

    f.write("NDIM = #{RAMSES_NDIM}\n")
    f.write("SOLVER = @params[:solver][solver]\n")
    f.write("PATCH = #{@params[:patch]}\n")
    f.write("GRACKLE = #{@params[:grackle]}\n") if type == :default
    f.write("EXEC = #{@params[:exe]}\n\n")

    f.write("GITBRANCH = $(shell git rev-parse --abbrev-ref HEAD)\n")
    f.write("GITHASH = $(shell git log --pretty=format:'%H' -n 1)\n")
    f.write("GITREPO = $(shell git config --get remote.origin.url)\n")
    f.write("BUILDDATE = $(shell date +\"%D-%T\")\n\n")

    # Compiler options
    f.write("F90 = mpif90 -frecord-marker=4 -O3 -ffree-line-length-none -g -fbacktrace\n")
    f.write("FFLAGS = -x f95-cpp-input $(DEFINES)\n\n")

    # Libraries
    f.write("MOD = mod\n\n")

    f.write("LIBMPI = -L/usr/lib -lmpi\n")

    if @params[:grackle]
      f.write("LIBS_GRACKLE = -L$(HOME)/.local/lib -lgrackle -lhdf5 -lz " \
        "-lgfortran -ldl\n")
      f.write("LIBS_OBJ = -I$(HOME)/.local/include -DCONFIG_BFLOAT_8 " \
        "-DH5_USE_16_API -fPIC\n")
    end

    f.write("LIBS = $(LIBMPI) $(LIBS_GRACKLE)\n\n")

    f.write("VPATH = $(shell [ -z $(PATCH) ] || find $(PATCH) -type d):" \
      "../$(SOLVER):../aton:../hydro:../pm:../poisson:../amr:../io\n\n")

    f.write("VPATH +=../rt\n\n") if type == :rt

    f.write("MODOBJ = amr_parameters.o amr_commons.o random.o " \
      "pm_parameters.o pm_commons.o poisson_parameters.o " \
      "dump_utils.o\n")

    f.write("MODOBJ += grackle_parameters.o\n") if @params[:grackle]

    f.write("MODOBJ += poisson_commons.o hydro_parameters.o " \
      "hydro_commons.o cooling_module.o bisection.o sparse_mat.o " \
      "clfind_commons.o gadgetreadfile.o write_makefile.o " \
      "write_patch.o write_gitinfo.o\n\n")

    if type == :rt
      f.write("MODOBJ += rt_parameters.o rt_hydro_commons.o " \
        "coolrates_module.o rt_spectra.o rt_cooling_module.o " \
        "rt_flux_module.o\n\n")
    end

    f.write("AMROBJ = read_params.o init_amr.o init_time.o init_refine.o " \
      "adaptive_loop.o amr_step.o update_time.o output_amr.o " \
      "flag_utils.o physical_boundaries.o virtual_boundaries.o " \
      "refine_utils.o nbors_utils.o hilbert.o load_balance.o title.o " \
      "sort.o cooling_fine.o units.o light_cone.o movie.o\n\n")

    f.write("PMOBJ = init_part.o output_part.o rho_fine.o synchro_fine.o " \
      "move_fine.o newdt_fine.o particle_tree.o add_list.o " \
      "remove_list.o star_formation.o sink_particle.o feedback.o " \
      "clump_finder.o clump_merger.o flag_formation_sites.o " \
      "init_sink.o output_sink.o\n\n")

    f.write("POISSONOBJ = init_poisson.o phi_fine_cg.o interpol_phi.o " \
      "force_fine.o multigrid_coarse.o multigrid_fine_commons.o " \
      "multigrid_fine_fine.o multigrid_fine_coarse.o gravana.o " \
      "boundary_potential.o rho_ana.o output_poisson.o\n\n")

    f.write("HYDROOBJ = init_hydro.o init_flow_fine.o write_screen.o " \
      "output_hydro.o courant_fine.o godunov_fine.o uplmde.o " \
      "umuscl.o interpol_hydro.o godunov_utils.o condinit.o " \
      "hydro_flag.o hydro_boundary.o boundana.o read_hydro_params.o " \
      "synchro_hydro_fine.o\n\n")

    if type == :rt
      f.write("RTOBJ = rt_init_hydro.o rt_init_xion.o rt_init.o " \
        "rt_init_flow_fine.o rt_output_hydro.o rt_godunov_fine.o " \
        "rt_interpol_hydro.o rt_godunov_utils.o rt_condinit.o " \
        "rt_hydro_flag.o rt_hydro_boundary.o rt_boundana.o " \
        "rt_read_hydro_params.o rt_units.o\n\n")
    end

    f.write("sinclude $(PATCH)/Makefile\n\n")

    f.write("AMRLIB = $(AMROBJ) $(HYDROOBJ) $(PMOBJ) $(POISSONOBJ)\n")
    f.write("AMRLIB += $(RTOBJ)\n\n") if type == :rt

    f.write("ATON_MODOBJ = timing.o radiation_commons.o rad_step.o\n")
    f.write("ATON_OBJ = observe.o init_radiation.o rad_init.o " \
      "rad_boundary.o rad_stars.o rad_backup.o " \
      "../aton/atonlib/libaton.a\n\n")

    f.write("ramses:	$(MODOBJ) $(AMRLIB) ramses.o\n")
    f.write("	$(F90) $(MODOBJ) $(AMRLIB) ramses.o -o $(EXEC)$(NDIM)d $(LIBS)\n")
    f.write("	rm write_makefile.f90 write_patch.f90\n\n")

    f.write("ramses_aton: $(MODOBJ) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) ramses.o\n")
    f.write("	$(F90) $(MODOBJ) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) " \
      "ramses.o -o $(EXEC)$(NDIM)d $(LIBS) $(LIBCUDA)\n")
    f.write("	rm write_makefile.f90 write_patch.f90\n\n")

    f.write("write_gitinfo.o: FORCE\n")
    f.write("	$(F90) $(FFLAGS) -DPATCH=\'\"$(PATCH)\"\' " \
      "-DGITBRANCH=\'\"$(GITBRANCH)\"\' -DGITHASH=\'\"$(GITHASH)\"\' " \
      "-DGITREPO=\'\"$(GITREPO)\"\' -DBUILDDATE=\'\"$(BUILDDATE)\"\' " \
      "-c ../amr/write_gitinfo.f90 -o $@\n\n")

    f.write("write_makefile.o: FORCE\n")
    f.write("	../utils/scripts/cr_write_makefile.sh $(MAKEFILE_LIST)\n")
    f.write("	$(F90) $(FFLAGS) -c write_makefile.f90 -o $@\n\n")

    f.write("write_patch.o: FORCE\n")
    f.write("	../utils/scripts/cr_write_patch.sh $(PATCH)\n")
    f.write("	$(F90) $(FFLAGS) -c write_patch.f90 -o $@\n\n")

    f.write("%.o:%.F\n")
    f.write("	$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)\n\n")

    f.write("%.o:%.f90\n")
    f.write("	$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)\n\n")

    f.write("FORCE:\n\n")

    f.write("clean:\n")
    f.write("	rm -f *.o *.$(MOD)\n")
  end
end
