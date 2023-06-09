program mcpolar

use mpi_f08

!shared data
use constants
use photon_vars
use iarray
use opt_prop

!subroutines
use subs
use gridset_mod
use sourceph_mod
use inttau2
use ch_opt
use stokes_mod
use writer_mod
use Heat, only : power, delt, energyPerPixel, laser_flag, laserOn, loops, pulseCount, pulsesToDo,pulseFlag,getPWr,&
                 repetitionCount, repetitionRate_1, time, total_time, initThermalCoeff, heat_sim_3d, arrhenius&
                 ,realpulseLength, pulseLength
use utils
use memoryModule, only : checkallocate

implicit none

integer           :: nphotons ,iseed, j, xcell, ycell, zcell, N, counter, u, w, e, WriteCount
integer           :: i,jj,k
logical           :: tflag
double precision  :: nscatt
real              :: xmax, ymax, zmax, delta, start, finish, ablateTemp,ran,ran2
real              :: aa, bb, cc, bal_area

! mpi variables
type(mpi_comm)   :: comm, new_comm
integer          :: right, left, id, numproc, dims(2), ndims, tag
logical          :: periods(1), reorder

!start MPI
call MPI_init()
comm = MPI_COMM_WORLD
call MPI_Comm_size(comm, numproc)


!setup topology variables
tag     = 1
dims    = 0
periods = .false.
reorder = .true.
ndims   = 1

!create cartesian topology on cpu
call mpi_dims_create(numproc, ndims, dims)
call mpi_cart_create(comm, ndims, dims, periods, reorder, new_comm)
call mpi_comm_rank(new_comm, id)

!set directory paths
call directory

!**** Read in parameters from the file input.params
open(newunit=u,file=trim(resdir)//'input.params',status='old')
   read(u,*) nphotons
   read(u,*) xmax
   read(u,*) ymax
   read(u,*) zmax
   read(u,*) n1
   read(u,*) n2
   read(u,*) total_time
   read(u,*) loops
   read(u,*) repetitionRate_1
   read(u,*) power
   read(u,*) energyPerPixel
   read(u,*) ablateTemp
   read(u,*) pulsesToDo
   read(u, *) pulsetype
   close(u)





!allocate and set arrays to 0
call alloc_array(numproc, id, total_time)
call zarray

N = nzg ! points for heat sim

tissue = 0.d0
ThresTime = 0.d0!

time            = 0.
pulseCount      = 0.
repetitionCount = 120. !starts at full count so laser turns on
WriteCount      = 1.
laserOn         = 1.
laser_flag      = .TRUE.
pulseFlag       = .FALSE.

counter = 0

!get neighbours
call mpi_cart_shift(new_comm, 0, 1, left, right)

!**** Read in parameters from the file input.params
!open(newunit=u,file=trim(resdir)//'input.params',status='old')
!   read(u,*) nphotons
!   read(u,*) xmax
!   read(u,*) ymax
!   read(u,*) zmax
!   read(u,*) n1
!   read(u,*) n2
!   read(u,*) total_time
!   read(u,*) loops
!   read(u,*) repetitionRate_1
!   read(u,*) power
!   read(u,*) energyPerPixel
!   read(u,*) ablateTemp
!   read(u,*) pulsesToDo
!   read(u, *) pulsetype
!   close(u)

   !allocate and set arrays to 0
   !call alloc_array(numproc, id, total_time)
   !call zarray


! input optical properties for block of brain
   open(newunit=u,file='block_rho.txt',status='old')!status='old')
   !open(newunit=u,file='grey_matter_cut.txt',status='old')
   read(u,*,end=102) block_rho
   102 close(u)

   open(newunit=u,file='block_alb.txt',status='old')!status='old')
   !open(newunit=u,file='grey_matter_cut.txt',status='old')
   read(u,*,end=103) block_alb
   103 close(u)

   open(newunit=u,file='block_jmean.txt',status='old')!status='old')
   !open(newunit=u,file='grey_matter_cut.txt',status='old')
   read(u,*,end=104) block_jmean
   104 close(u)

   !open(newunit=u,file='brain_block.txt',status='old')!status='old')
   !open(newunit=u,file='grey_matter_cut.txt',status='old')
   !read(u,*,end=104) brain_block
   !104 close(u)

   !open(newunit=u,file='brain_block_a.txt',status='old')!status='old')
   !open(newunit=u,file='grey_matter_cut.txt',status='old')
   !read(u,*,end=105) brain_block_a
   !105 close(u)

   !open(newunit=u,file='brain_block_a.txt',status='old')!status='old')
  ! open(newunit=u,file='rho_full.txt',status='old')
  ! read(u,*,end=105) rho_full
  ! 105 close(u)

   !open(newunit=u,file='alb_full.txt',status='old')
   !read(u,*,end=106) alb_full
   !106 close(u)


! set seed for rnd generator. id to change seed for each process
iseed = -95648324 + id
iseed = -abs(iseed)  ! Random number seed must be negative for ran2


call init_opt1

if(id == 0)then
   print*, ''
   print*,'# of photons to run',nphotons*numproc
end if

!***** Set up density grid *******************************************
call gridset(xmax, ymax, zmax, id)
!***** Set small distance for use in optical depth integration routines
!***** for roundoff effects when crossing cell walls
delta  = 1.e-8*(2.*zmax/nzg)
nscatt = 0

!barrier to ensure correct timingd
call MPI_Barrier(MPI_COMM_WORLD)
call cpu_time(start)

!loop over photons
print*,'Photons now running on core: ',id


!temp          = 5.d0 + 273.d0
!temp(N+1,:,:) = 5.+273.  ! side face
!temp(0,:,:)   = 5.+273.    ! side face
!temp(:,0,:)   = 5.+273. ! front face
!temp(:,N+1,:) = 5.+273.  ! back face
!temp(:,:,0)   = 25.+273.  ! bottom face
!temp(:,:,N+1) = 25.+273.  ! top face

temp          = 22.d0 + 273.d0
temp(N+1,:,:) = 37.+273.  ! side face
!temp(0,:,:)   = 37.+273.    ! side face
!temp(:,0,:)   = 37.+273. ! front face
!temp(:,N+1,:) = 37.+273.  ! back face
!temp(:,:,0:10)   = 22.+273.  ! bottom face
temp(:,:,N+1) = 37.+273.  ! top face


do i= 1,nxg
  do jj= 1, nyg
    do k= 1,nzg
      if(block_rho(i,jj,k) > 100.)then
        temp(i,jj,k)=37.+273.
      else
        temp(i,jj,k)=22.+273.
      endif
    end do
  end do
end do
call initThermalCoeff(delt, N, xmax, ymax, zmax, numproc)
!override total_time if set too low for laser to finish 1 pulse
if(trim(pulsetype) == "gaussian")then
    !gives total time as a gaussian pulse with max as half total time
    total_time = 2. * pulseLength * (2. * sqrt(2. * log(2.)))
    realpulselength = total_time
elseif(int(total_time/delt) <= int(realpulseLength/delt))then
   total_time = delt * (realpulselength/delt + 2000.)
end if

if(id == 0)then
   print*,"Energy,      total loops,  realpulse length,    delt,            laser on,   total sim time"
   print'(F8.1,1x,I10.5,9x,F5.3,16x,E11.5,1x,I10.5,5x,F7.3)',energyPerPixel,int(total_time/delt),realpulselength,delt,&
                                                            int(realpulselength/delt),total_time
end if

!do while(time <= total_time)
   if(laser_flag)then

      do j = 1, nphotons

         tflag=.FALSE.

         ! if(mod(j,1000000) == 0)then
         !    print *, str(j)//' scattered photons completed on core: '//str(id)
         ! end if

      !***** Release photon *******************************
         !call sourcephCO2(xmax,ymax,zmax,xcell,ycell,zcell,iseed)
         call fibre_lille(xcell, ycell, zcell, iseed, xmax, ymax, zmax)

      !****** Find scattering/absorb location
         call tauint1(xmax,ymax,zmax,xcell,ycell,zcell,tflag,iseed,delta)

      !******** Photon scatters in grid until it exits (tflag=TRUE)
         do while(tflag.eqv..FALSE.)
             tflag = .true.
            exit

        !    do while(tflag.eqv..FALSE.)

        !       ran = ran2(iseed)

        !       if(ran < albedoar(xcell,ycell,zcell))then!interacts with tissue
        !             call stokes(iseed)
                    ! nscatt = nscatt + 1
        !          else !is absorbed and releases a fluorescence photon at 705nm - add 1 to fluoes list and store starting position.
                   !store position of absorption in array size N (can remove zeros from end later from where photons escape grid)
        !             tflag=.true.
        !             exit
        !       end if
         end do
      end do      ! end loop over j photons


      aa=7./2.
      bb=4./2.
      cc=4./2.

      bal_area= 4.*3.14*(((aa*bb)**1.6 + (aa*cc)**1.6 + (bb*cc)**1.6)/3.)**(1./1.6)

      !reduce jmean from all processess
      call MPI_allREDUCE(jmean, jmeanGLOBAL, (nxg*nyg*nzg),MPI_DOUBLE_PRECISION, MPI_SUM,new_comm)
      !jmeanGLOBAL = jmeanGLOBAL * ((getPwr()/81.d0)/(nphotons*numproc*(2.*xmax*1.d-2/nxg)*(2.*ymax*1.d-2/nyg)*(2.*zmax*1.d-2/nzg)))
    !  jmeanGLOBAL = jmeanGLOBAL * (((getPwr()* 2*xmax*2*ymax)/bal_area)/&
      !jmeanGLOBAL = jmeanGLOBAL * ((getPwr())/&
    !  (nphotons*numproc*(2.*xmax*1.d-2/nxg)*(2.*ymax*1.d-2/nyg)*(2.*zmax*1.d-2/nzg)))
    jmeanGLOBAL=block_jmean * 10 ! convert from mW/cm2 to W/m2
   end if



   !do heat simulation
   call heat_sim_3d(jmeanGLOBAL, temp, N, id, numproc, new_comm, right, left, counter, WriteCount)

   !call arrhenius(temp, delt, tissue, ThresTime, 1, N, N)
   !update thermal/optical properties
   !call setupThermalCoeff(temp, N, ablateTemp)

   counter = counter + 1
   jmean = 0.
!end do

  ! call checkallocate(ThresTimeGLOBAL, [nxg, nyg, nzg, 3], "ThresTimeGLOBAL", numproc)
  ! ThresTimeGLOBAL = 0.d0
  ! call MPI_REDUCE(ThresTime, ThresTimeGLOBAL, nxg*nyg*nzg*3, MPI_DOUBLE_PRECISION, mpi_min, 0, new_comm)

   !write out results
   if(id == 0)then
      !delete damage info about ablation crater
      !as no tissue left to damage!
  !    do q = 1, nxg
  !       do w = 1, nyg
  !          do e = 1, nzg
  !             if(rhokap(q,w,e) <= 0.1)then
  !                tissue(q,w,e) = -1.d0
  !             end if
  !          end do
!         end do
!      end do
      call writer(ablateTemp, temp, tissue, xmax, ymax, zmax, ThresTimeGlobal)
   end if

call cpu_time(finish)
if(finish-start.ge.60.)then
    print*,str(floor((finish-start)/60.)+mod(finish-start,60.)/100.,5)//' mins'
else
    print*, 'time taken ~',floor(finish-start/60.),'s'
end if

call MPI_Finalize()
end program mcpolar
