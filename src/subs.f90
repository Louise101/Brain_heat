module subs

implicit none

    contains
        subroutine directory
        !  subroutine defines vars to hold paths to various folders
        !
        !
            use constants, only : cwd, homedir, fileplace, resdir

            implicit none

            !get current working directory

            call get_environment_variable('PWD', cwd)

            ! get 'home' dir from cwd
            homedir = trim(cwd(1:len(trim(cwd))-3))
            ! get data dir
            fileplace = trim(homedir)//'data/'
            ! get res dir
            resdir=trim(homedir)//'res/'

        end subroutine directory

        subroutine zarray
        !   sets all arrays to zero
        !
        !
            use iarray

            implicit none

            jmean = 0.
            jmean_on=0.
            jmean_off=0.
            xface = 0.
            yface = 0.
            zface = 0.
            rhokap = 0.
            albedoar=0.
            jmeanGLOBAL = 0.

          !  rho_full=0.
          !  alb_full=0.


            block_rho=0.
            block_alb=0.
            block_jmean=0.
          !  brain_block=0.
          !  brain_block_a=0.

            jmean_slice=0.
            temp_slice=0.
        end subroutine zarray


        subroutine alloc_array(numproc, id, total_time)
        !  subroutine allocates allocatable arrays
        !
        !
            use iarray
            use constants,       only : nxg, nyg, nzg
            use iso_fortran_env, only : int64
            use memorymodule

            implicit none

            integer , intent(IN) :: numproc, id
            real, intent(in) :: total_time

            integer(int64) :: limit
            integer :: N

            limit = mem_free()

            call checkallocate(xface, [nxg+1], "xface", numproc)
            call checkallocate(yface, [nyg+1], "yface", numproc)
            call checkallocate(zface, [nzg+1], "zface", numproc)

            call checkallocate(block_rho, [nxg,nyg,nzg], "block_rho", numproc)
            call checkallocate(block_alb, [nxg,nyg,nzg], "block_alb", numproc)
            call checkallocate(block_jmean, [nxg,nyg,nzg], "block_jmean", numproc)
            !call checkallocate(brain_block, [nxg, nyg, nzg], "brain_block", numproc)
            !call checkallocate(brain_block_a,[nxg, nyg, nzg], "brain_block_a", numproc)

            !call checkallocate(rho_full, [nxg+1, nyg+1, nzg+1], "rho_full", numproc, [0,0,0])
            !call checkallocate(alb_full, [nxg+1, nyg+1, nzg+1], "alb_full", numproc, [0,0,0])

            call checkallocate(rhokap, [nxg+1, nyg+1, nzg+1], "rhokap", numproc, [0,0,0])
            call checkallocate(albedoar, [nxg+1, nyg+1, nzg+1], "albedo", numproc, [0,0,0])
            call checkallocate(jmean, [nxg, nyg, nzg], "jmean", numproc)
            call checkallocate(jmean_on, [nxg, nyg, nzg], "jmean on", numproc)
            call checkallocate(jmean_off, [nxg, nyg, nzg], "jmean_off", numproc)
            call checkallocate(jmeanGLOBAL, [nxg, nyg, nzg], "jmeanGlobal", numproc)

            call checkallocate(tissue, [nxg, nyg, nzg], "tissue", numproc)
            N = nzg ! points for heat sim
            call checkallocate(temp, [N+1, N+1, N+1], "temp", numproc, [0,0,0])
            call checkallocate(ThresTime, [nxg, nyg, nzg, 3], "ThresTime", numproc)

            call checkallocate(jmean_slice, [nxg, nzg, nint(total_time)], "Jmean_Slice", numproc)
            call checkallocate(temp_slice, [nxg, nzg, nint(total_time)], "Temp_Slice", numproc)

            call checkallocate(coeff,   [nxg+1, nyg+1, nzg+1], "coeff",   numproc, [0,0,0])
            call checkallocate(alpha,   [nxg+1, nyg+1, nzg+1], "alpha",   numproc, [0,0,0])
            call checkallocate(kappa,   [nxg+1, nyg+1, nzg+1], "kappa",   numproc, [0,0,0])
            call checkallocate(density, [nxg+1, nyg+1, nzg+1], "density", numproc, [0,0,0])
            call checkallocate(heatCap, [nxg+1, nyg+1, nzg+1], "heatcap", numproc, [0,0,0])
            call checkallocate(Q, [nxg, nyg, nzg], "Q", numproc)
            call checkallocate(watercontent, [nxg, nyg, nzg], "watercontent", numproc)

            if(id==0)print'(A,1X,F5.2,A)','allocated:',dble(TotalMem)/dble(limit)*100.d0,' % of total RAM'

        end subroutine alloc_array

        subroutine slice_write(i,k,ts,temp)
        !  subroutine allocates allocatable arrays
        !
        !
            use iarray,           only : jmean_slice, jmeanGLOBAL, temp_slice
            use constants,       only : nxg, nyg, nzg


            implicit none

            integer , intent(IN) :: ts,i,k
             real,    intent(IN) :: temp(0:nxg+1,0:nyg+1,0:nzg+1)

          !  print*, jmeanGLOBAL(1,40,1), 'jmean'

            jmean_slice(i,k,ts)=jmeanGLOBAL(i,40,k) !or do we need to run mcrt again when light switches on and off? could find a way around this . . .
            temp_slice(i,k,ts)=temp(i,40,k) - 273.d0

          !  jmean_slice(:,:,ts)=jmean(:,40,:)
          !  temp_slice(:,:,ts)=temp(:,40,:) - 273.d0



        end subroutine slice_write
end module subs
