Module Heat

  use subs, only: slice_write

    implicit none
    ! pointer to power function for simulation: tophat, gaussian etc
    procedure(getPwrTriangular), pointer :: getPwr => null()

    real              :: pulseCount, repetitionCount, time, laserOn, total_time, repetitionRate_1, energyPerPixel
    real              :: Power, pulselength, delt, realPulseLength, restLength, restCount
    real              :: dx, dy, dz, massVoxel, volumeVoxel
  !  real, allocatable :: coeff(:,:,:), kappa(:,:,:), density(:,:,:), heatcap(:,:,:), WaterContent(:,:,:), Q(:,:,:), alpha(:,:,:)
    logical           :: laser_flag, pulseFlag
    integer           :: loops, pulsesToDo, pulsesDone, loops_left

    private
    public :: power, delt, energyPerPixel, laser_flag, laserOn, loops, pulseCount, pulselength, pulsesToDo, repetitionCount
    public :: repetitionRate_1, time,total_time, initThermalCoeff, heat_sim_3d, Arrhenius
    public :: pulseFlag, realPulseLength, getPwr

    contains

subroutine heat_sim_3D(jmean, temp, numpoints, id, numproc, new_comm, right, left, counter, WriteCount)

        use mpi_f08
        use utils,     only : str
        use thermalConstants!, only : QVapor, getSkinHeatCap, getSkinDensity, getSkinThermalCond
        use iarray, only: coeff,alpha, heatCap, Q, watercontent, density,kappa


        implicit none

        !heat input variables
        real,           intent(IN)    :: jmean(:,:,:)
        integer,        intent(IN)    :: numpoints, right, left, id, numproc,counter
        type(mpi_comm), intent(IN)    :: new_comm
        real,           intent(INOUT) :: temp(0:numpoints+1,0:numpoints+1,0:numpoints+1)
        integer,        intent(INOUT) :: WriteCount

        type(MPI_Status) :: recv_status

        !heat local variables
        real              :: u_xx, u_yy, u_zz, tempIncrease,kappaMinHalf, kappaPlusHalf, energyIncrease
        real              :: heatcapMinHalf, densityPlusHalf, densityMinHalf, heatcapPlusHalf, a, b, d
        real, allocatable :: T0(:,:,:), jtmp(:,:,:), qtmp(:,:,:), tn(:,:,:)
        integer           :: i, j, k, p, size_x, size_y, size_z, xi, yi, zi, xf, yf, zf, N, tag,zsta,zfin

        !calculate size of domain
        !discretizes along z axis
        if(id == 0)then
            !do decomp
            if(mod(numpoints, numproc) /= 0)then
                print('(I2.1,a,I2.1)'),numpoints,' not divisable by : ', numproc
                call mpi_abort(new_comm, 1)
                error stop
            else
                N = numpoints / numproc
            end if
        end if

        tag = 1
        !send N to all processes
        call MPI_Bcast(N, 1, MPI_integer ,0 , new_comm)

        !init grid
        size_x = numpoints
        size_y = numpoints
        size_z = N

        xi = 1
        xf = size_x


        yi = 1
        yf = size_y

        zi = 1
        zf = size_z

        !allocate mesh
        allocate(T0(0:numpoints+1, 0:numpoints+1, zi-1:zf+1))
        allocate(Tn(0:numpoints+1, 0:numpoints+1, zi-1:zf+1))
        allocate(jtmp(numpoints, numpoints, zi:zf))
        allocate(Qtmp(numpoints, numpoints, zi:zf))
        t0 = 0.
        Qtmp = 0.

        !split temp/jmean/Q up over all processes
        if(id == 0)then
            do i = 1, numproc-1
                zsta = (i)*zf
                zfin = zsta + zf + 1
                call mpi_send(temp(:,:,zsta:zfin), size(temp(:,:,zsta:zfin)), mpi_double_precision, i, tag, new_comm)
            end do
            t0(:,:,:) = temp(:,:,0:zf+1)
        else
            call mpi_recv(t0, size(t0), mpi_double_precision, 0, tag, new_comm, recv_status)
        end if
        tn = t0
        jtmp = 0.
        call mpi_scatter(jmean, size(jmean(:,:,zi:zf)), mpi_double_precision, jtmp(:,:,zi:zf), size(jtmp(:,:,zi:zf)), &
                         mpi_double_precision, 0, new_comm)

        call mpi_scatter(Q, size(Q(:,:,zi:zf)), mpi_double_precision, Qtmp(:,:,zi:zf), size(Qtmp(:,:,zi:zf)), &
                 mpi_double_precision, 0, new_comm)


        if(pulselength < delt)then
            if(id == 0)print*,"pulselength smaller than timestep, adjusting..."
            delt = pulselength / 100.
        end if

        loops_left = int(total_time/(real(loops)*delt)) - counter
      !  PRINT*, total_time, loops, delt, counter
        if(id == 0 .and. mod(int(total_time/(real(loops)*delt)) - counter, 100) == 0)then
            !print"(a,F9.5,1x,a,I11,1x,F9.5)","Elapsed Time: ",time, "Loops left: ",loops_left,getPwr(),p
            print*, "Elapsed Time: ",time, "Loops left: ",loops_left,getPwr(),p
        end if

        !time loop
        do p = 1, loops
            !heat sim loops
            do k = zi, zf
                do j = yi, yf
                    do i = xi, xf

                        !!adapted from Finite Differecne Methods in Heat Transfer Chapter 9. M. Ozisik
                    !    kappaPlusHalf = .5d0 * (kappa(i,j,k) + kappa(i,j,k+1))
                    !    kappaMinHalf = .5d0 * (kappa(i,j,k) + kappa(i,j,k-1))

                    !    densityPlusHalf = .5d0 * (density(i,j,k) + density(i,j,k+1))
                    !    densityMinHalf = .5d0 * (density(i,j,k) + density(i,j,k-1))

                    !    heatcapPlusHalf = .5d0 * (heatcap(i,j,k) + heatcap(i,j,k+1))
                    !    heatcapMinHalf = .5d0 * (heatcap(i,j,k) + heatcap(i,j,k-1))

                    !    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dz**2)
                    !    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dz**2)
                    !    b = 0.5d0 * (a + d)

                    !    u_zz = a*t0(i,j,k-1) - 2.d0*b*t0(i,j,k) + d*t0(i,j,k+1)

                    !    if(j+1>yf)then
                    !      kappaPlusHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,yi,k))
                    !      densityPlusHalf = 0.5d0 * (density(i,j,k) + density(i,yi,k))
                    !      heatcapPlusHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,yi,k))

                    !      a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dy**2)
                    !      d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dy**2)
                    !      b = 0.5d0 * (a + d)

                    !      u_yy = a*t0(i,j-1,k) - 2.d0*b*t0(i,j,k) + d*t0(i,yi,k)
                    !    elseif(j-1 < yi)then
                    !      kappaMinHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,yf,k))
                    !      densityMinHalf = 0.5d0 * (density(i,j,k) + density(i,yf,k))
                    !      heatcapMinHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,yf,k))

                    !      a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dy**2)
                    !      d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dy**2)
                    !      b = 0.5d0 * (a + d)

                    !      u_yy = a*t0(i,yf,k) - 2.d0*b*t0(i,j,k) + d*t0(i,j+1,k)
                    !    else
                    !    kappaPlusHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,j+1,k))
                    !    kappaMinHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,j-1,k))

                    !    densityPlusHalf = 0.5d0 * (density(i,j,k) + density(i,j+1,k))
                    !    densityMinHalf = 0.5d0 * (density(i,j,k) + density(i,j-1,k))

                    !    heatcapPlusHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,j+1,k))
                    !    heatcapMinHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,j-1,k))


                    !    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dy**2)
                    !    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dy**2)
                    !    b = 0.5d0 * (a + d)

                    !    u_yy = a*t0(i,j-1,k) - 2.d0*b*t0(i,j,k) + d*t0(i,j+1,k)
                    !  endif

                    !    if(i+1>xf)then
                    !      kappaPlusHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,xi,k))
                    !      densityPlusHalf = 0.5d0 * (density(i,j,k) + density(i,xi,k))
                    !      heatcapPlusHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,xi,k))

                    !      a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dx**2)
                    !      d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dx**2)
                    !      b = 0.5d0 * (a + d)

                    !      u_xx = a*t0(i-1,j,k) - 2.d0*b*t0(i,j,k) + d*t0(xi,j,k)
                    !    elseif(i-1 < xi)then
                    !      kappaMinHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,xf,k))
                    !      densityMinHalf = 0.5d0 * (density(i,j,k) + density(i,xf,k))
                    !      heatcapMinHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,xf,k))

                    !      a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dx**2)
                    !      d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dx**2)
                    !      b = 0.5d0 * (a + d)

                    !      u_xx = a*t0(xf,j,k) - 2.d0*b*t0(i,j,k) + d*t0(i+1,j,k)
                    !    else

                    !    kappaPlusHalf = .5d0 * (kappa(i,j,k) + kappa(i+1,j,k))
                    !    kappaMinHalf = .5d0 * (kappa(i,j,k) + kappa(i-1,j,k))

                    !    densityPlusHalf = .5d0 * (density(i,j,k) + density(i+1,j,k))
                    !    densityMinHalf = .5d0 * (density(i,j,k) + density(i-1,j,k))

                    !    heatcapPlusHalf = .5d0 * (heatcap(i,j,k) + heatcap(i+1,j,k))
                    !    heatcapMinHalf = .5d0 * (heatcap(i,j,k) + heatcap(i-1,j,k))



                    !    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dx**2)
                    !    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dx**2)
                    !    b = 0.5d0 * (a + d)

                    !    u_xx = a*t0(i-1,j,k) - 2.d0*b*t0(i,j,k) + d*t0(i+1,j,k)

                    !  endif

                    !!adapted from Finite Differecne Methods in Heat Transfer Chapter 9. M. Ozisik
                    kappaPlusHalf = .5d0 * (kappa(i,j,k) + kappa(i,j,k+1))
                    kappaMinHalf = .5d0 * (kappa(i,j,k) + kappa(i,j,k-1))

                    densityPlusHalf = .5d0 * (density(i,j,k) + density(i,j,k+1))
                    densityMinHalf = .5d0 * (density(i,j,k) + density(i,j,k-1))

                    heatcapPlusHalf = .5d0 * (heatcap(i,j,k) + heatcap(i,j,k+1))
                    heatcapMinHalf = .5d0 * (heatcap(i,j,k) + heatcap(i,j,k-1))

                    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dz**2)
                    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dz**2)
                    b = 0.5d0 * (a + d)

                    u_zz = a*t0(i,j,k-1) - 2.d0*b*t0(i,j,k) + d*t0(i,j,k+1)


                    kappaPlusHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,j+1,k))
                    kappaMinHalf = 0.5d0 * (kappa(i,j,k) + kappa(i,j-1,k))

                    densityPlusHalf = 0.5d0 * (density(i,j,k) + density(i,j+1,k))
                    densityMinHalf = 0.5d0 * (density(i,j,k) + density(i,j-1,k))

                    heatcapPlusHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,j+1,k))
                    heatcapMinHalf = 0.5d0 * (heatcap(i,j,k) + heatcap(i,j-1,k))

                    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dy**2)
                    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dy**2)
                    b = 0.5d0 * (a + d)

                    u_yy = a*t0(i,j-1,k) - 2.d0*b*t0(i,j,k) + d*t0(i,j+1,k)


                    kappaPlusHalf = .5d0 * (kappa(i,j,k) + kappa(i+1,j,k))
                    kappaMinHalf = .5d0 * (kappa(i,j,k) + kappa(i-1,j,k))

                    densityPlusHalf = .5d0 * (density(i,j,k) + density(i+1,j,k))
                    densityMinHalf = .5d0 * (density(i,j,k) + density(i-1,j,k))

                    heatcapPlusHalf = .5d0 * (heatcap(i,j,k) + heatcap(i+1,j,k))
                    heatcapMinHalf = .5d0 * (heatcap(i,j,k) + heatcap(i-1,j,k))

                    a = 0.5d0 * (kappaMinHalf/(densityMinHalf * heatcapMinHalf)) * (1.d0/dx**2)
                    d = 0.5d0 * (kappaPlusHalf/(densityPlusHalf * heatcapPlusHalf)) * (1.d0/dx**2)
                    b = 0.5d0 * (a + d)

                    u_xx = a*t0(i-1,j,k) - 2.d0*b*t0(i,j,k) + d*t0(i+1,j,k)

                       if(laser_flag .eqv. .true.)then !if laser on -normal
                        tempIncrease = delt * (u_xx + u_yy + u_zz)
                        energyIncrease = laserOn*jtmp(i,j,k)*delt*volumeVoxel + heatcap(i,j,k)*massVoxel*tempIncrease

                        !boil water

                        if(tn(i,j,k) >= 100. + 273. .and. Qtmp(i,j,k) < QVapor)then
                            if(energyIncrease > 0.d0)then
                                Qtmp(i,j,k) = min(Qtmp(i,j,k) + energyIncrease, Qvapor)
                                tn(i,j,k) = 100.d0 + 273.d0
                            else
                                tn(i,j,k) =  tn(i,j,k) + tempIncrease + laserOn*coeff(i,j,k)*jtmp(i,j,k)
                            end if
                        else
                            tn(i,j,k) =  tn(i,j,k) + tempIncrease + laserOn*coeff(i,j,k)*jtmp(i,j,k)
                            !check result is physical

                            if(temp(i,j,k) < 0.d0)then
                                print*,id,i,j,k,t0(i,j,k),loops_left
                                call mpi_abort(new_comm, 1)
                            end if
                        end if

                      else !if laser off -jtmp=0

                        tempIncrease = delt * (u_xx + u_yy + u_zz)
                        energyIncrease = laserOn*0.*delt*volumeVoxel + heatcap(i,j,k)*massVoxel*tempIncrease

                        if(tn(i,j,k) >= 100. + 273. .and. Qtmp(i,j,k) < QVapor)then
                            if(energyIncrease > 0.d0)then
                                Qtmp(i,j,k) = min(Qtmp(i,j,k) + energyIncrease, Qvapor)
                                tn(i,j,k) = 100.d0 + 273.d0
                            else
                                tn(i,j,k) =  tn(i,j,k) + tempIncrease + laserOn*coeff(i,j,k)*0.
                            end if
                        else
                            tn(i,j,k) =  tn(i,j,k) + tempIncrease + laserOn*coeff(i,j,k)*0.
                            !check result is physical

                            if(temp(i,j,k) < 0.d0)then
                                print*,id,i,j,k,t0(i,j,k),loops_left
                                call mpi_abort(new_comm, 1)
                            end if
                        end if
                      endif

                      !create boundary condition to make bottom and right side layer stay above 37 and simulate heating from blood flow.
                      if(temp(N+1,j,k) < 37. + 273)then
                        temp(N+1,j,k)= 37. + 273
                      end if

                      if(temp(i,j,N+1) < 37. + 273)then
                        temp(i,j,N+1)= 37. + 273
                      end if

                      if(temp(i,j,0) >22. + 273)then
                        temp(i,j,0)= 22. + 273
                      end if

                    end do
                end do
            end do
            t0 = tn
            !halo swap
            !send_recv data to right
                call MPI_Sendrecv(t0(:,:,zf), size(t0(:,:,zf)), mpi_double_precision, right, tag, &
                              t0(:,:,zf+1), size(t0(:,:,zf+1)), mpi_double_precision, right, tag, &
                              new_comm, recv_status)

            !send_recv data to left
                call MPI_Sendrecv(t0(:,:,zi), size(t0(:,:,zi)), mpi_double_precision, left, tag, &
                              t0(:,:,zi-1), size(t0(:,:,zi-1)), mpi_double_precision, left, tag, &
                              new_comm, recv_status)


            !if(pulseCount >= realpulseLength .and. laser_flag )then!turn laser off
              !  laser_flag = .false.
              !  laserOn = 0.
              !  pulseCount = 0.
              !  pulsesDone = pulsesDone + 1
              !  repetitionCount = 0.
            !elseif((repetitionCount >= repetitionRate_1) .and. (.not.laser_flag) .and. (pulsesDone < pulsesToDo))then
            !    laser_flag = .true.
            !    laserOn = 1.
            !    pulseCount = 0.
            !    repetitionCount = 0.
            !end if

            if(pulseCount >= realPulseLength)then
              laser_flag= .false.
              laserOn = 0.
              repetitionCount = repetitionCount + delt
              if(repetitionCount >= repetitionRate_1)then
                pulseCount=0.
              end if

           elseif((repetitionCount >= repetitionRate_1) .and. (pulsesDone < pulsesToDo))then
             laser_flag= .true.
             laserOn = 1.
             pulseCount = pulseCount + delt
             if(pulseCount >= pulseLength)then
               repetitionCount = 0.
               pulsesDone = pulsesDone + 1.
             endif

           end if

          !  pulseCount = pulseCount + delt
          !  repetitionCount = repetitionCount + delt
            time = time + delt


            if((WriteCount - delt < time) .and. (time < WriteCount + delt )) then
              if (id==0)then
               print*, 'stuff', WriteCount,delt,time,p, laser_flag, repetitionCount, pulseCount
             endif
         !          do k = zi, zf
         !              do j = yi, yf
         !                 do i = xi, xf

         !                  if(id==0)then

                           !  jmean_slice(:,:,WriteCount)=jmean(:,40,:)
                           !  temp_slice(:,:,WriteCount)=temp(:,40,:)

         !                   if( (j == 40))then

                                 !total_loops/total_sim_time= loops per second
                                 !so for every multiple of loops per second, run slice_write to write out data for every second
                               !  print*, 'yes', WriteCount, delt, time,j

                               !  if(j .eq. 40)then
                               !    print*, 'yesyes'
         !                           call slice_write(i,k,WriteCount,temp)
         !                      endif


         !               endif
             !         endif
         !           end do
         !        end do
         !       end do
                  WriteCount = WriteCount + 1
             end if

        end do

              !collate results
              call mpi_allgather(t0(:,:,zi:zf), size(t0(:,:,zi:zf)), mpi_double_precision, &
                              temp(:,:,zi:zf), size(temp(:,:,zi:zf)), mpi_double_precision, new_comm)

              call mpi_allgather(Qtmp(:,:,zi:zf), size(Qtmp(:,:,zi:zf)), mpi_double_precision, &
                              Q(:,:,zi:zf), size(Q(:,:,zi:zf)), mpi_double_precision, new_comm)





!end do




        deallocate(T0)
        deallocate(Tn)
        deallocate(jtmp)
        deallocate(Qtmp)

    end subroutine heat_sim_3D


    subroutine initThermalCoeff(delt, numpoints, xmax, ymax, zmax, numproc)
    !init all thermal variables

        use thermalConstants
        use constants,    only : nxg, nyg, nzg, spotsPerRow, spotsPerCol, pulsetype
        use memoryModule, only : checkallocate
        use iarray
        use opt_prop


        implicit none

        real,    intent(INOUT) :: delt
        real,    intent(IN)    :: xmax, ymax, zmax
        integer, intent(IN)    :: numpoints, numproc

        real :: densitytmp, alphatmp, kappatmp, heatCaptmp, constd
        integer :: i,j,k


        getSkinDensity = 1046.!average brain density from itis.swiss kg m-3
        getSkinHeatCap = 3630. !average brain heat capacity from itis.swiss J/kg/C
        getSkinThermalCond = 0.51 !average brain thermal conductivity, from itis.swiss, W/m/C
        getWaterDensity = 994. !average water density from itis.swiss kg m-3
        getWaterHeatCap = 4178. !average water heat capacity from itis.swiss J/kg/C
        getWaterThermalCond = 0.6 !average brain thermal conductivity, from itis.swiss, W/m/C

        !calculate node distance for FDM
        dx = (2.d0 * xmax * 1.d-2) / (numpoints + 2.d0)
        dy = (2.d0 * ymax * 1.d-2) / (numpoints + 2.d0)
        dz = (2.d0 * zmax * 1.d-2) / (numpoints + 2.d0)

        !safely allocate memory
    !    call checkallocate(coeff,   [nxg+1, nyg+1, nzg+1], "coeff",   numproc, [0,0,0])
    !    call checkallocate(alpha,   [nxg+1, nyg+1, nzg+1], "alpha",   numproc, [0,0,0])
    !    call checkallocate(kappa,   [nxg+1, nyg+1, nzg+1], "kappa",   numproc, [0,0,0])
    !    call checkallocate(density, [nxg+1, nyg+1, nzg+1], "density", numproc, [0,0,0])
    !    call checkallocate(heatCap, [nxg+1, nyg+1, nzg+1], "heatcap", numproc, [0,0,0])
    !    call checkallocate(Q, [nxg, nyg, nzg], "Q", numproc)
    !    call checkallocate(watercontent, [nxg, nyg, nzg], "watercontent", numproc)

        !get initial thermal variables and set them into arrays
        Q = 0.d0
        skinDensityInit = getSkinDensity!(watercontentInit)
        !WaterContent = watercontentInit
        heatCaptmp =  getSkinHeatCap!(watercontentInit)
        densitytmp  = getSkinDensity!(watercontentInit)
        kappatmp = getSkinThermalCond!(watercontentInit, densitytmp)
        alphatmp = kappatmp / (densitytmp * getSkinHeatCap)!(watercontentInit))

        alpha = alphatmp
      !  alpha(:,:,nzg+1) = airThermalCond(22.d0 + 273.d0, 0) / (airDensity(22.d0 + 273.d0) * airHeatCap)
        alpha(:,:,0) = airThermalCond(22.d0 + 273.d0, 0) / (airDensity(22.d0 + 273.d0) * airHeatCap)

      !  kappa = airThermalCond(22.+273., 0)
      !  kappa(1:nxg,1:nyg,1:nzg) = getSkinThermalCond(watercontentInit, densitytmp)

      !  density = densitytmp
      !  heatcap = heatcaptmp

        constd = (1.d0/dx**2) + (1.d0/dy**2) + (1.d0/dz**2)
        delt   = 1.d0 / (1.d0*alphatmp*constd)

        coeff = 0.d0
        coeff(1:nxg,1:nyg,1:nzg) = alphatmp * delt / kappatmp

        do k = 1, nzg
            do j = 1, nyg
                do i = 1, nxg
                  if(rhokap(i,j,k) > 100.)then !brain tissue
                    density(i,j,k) = getSkinDensity
                    heatCap(i,j,k) = getSkinHeatCap
                    kappa(i,j,k) = getSkinThermalCond
                    coeff(i,j,k) = delt/ (density(i,j,k) * heatcap(i,j,k))
                  else !water
                    density(i,j,k) = getWaterDensity
                    heatCap(i,j,k) = getWaterHeatCap
                    kappa(i,j,k) = getWaterThermalCond
                    coeff(i,j,k) = delt/ (density(i,j,k) * heatcap(i,j,k))
                  endif

                end do
            end do
        end do

        alpha(:,:,0) = airThermalCond(22.d0 + 273.d0, 0) / (airDensity(22.d0 + 273.d0) * airHeatCap)

        kappa = airThermalCond(22.+273., 0)

        !calculate pulse length
        !pulseLength =  (energyPerPixel * 1.d-3 * real(spotsPerRow* spotsPerCol)) / Power!pulselength above avg pwr
        pulseLength =  118. !seconds = fraction length for 9.8 minutes treatment time with 5 fractions


        volumeVoxel = (2.d0*xmax*1.d-2/nxg) * (2.d0*ymax*1.d-2/nyg) * (2.d0*zmax*1.d-2/nzg) !in meters
        massVoxel = densitytmp*volumeVoxel
        QVapor = lw * massVoxel

        !adjust puls length depending on pulse type
        select case(trim(pulsetype))
        case ("tophat")
            getPwr => getPwrTopHat
            realPulseLength = pulseLength !total pulse length
        case ("gaussian")
            getPwr => getPwrGaussian
            realPulseLength = 20000.d0 * pulseLength !total pulse length
        case("triangular")
            getPwr => getPwrTriangular
            realPulseLength = 2.d0 * pulseLength !total pulse length
        case default
            call mpi_finalize()
            error stop "no pulse type"
        end select

    end subroutine initThermalCoeff


!    subroutine setupThermalCoeff(temp, numpoints, ablateTemp)
    !update thermal/optical variables during simulation

!        use constants, only : nxg, nyg, nzg
!        use iarray,    only : rhokap
!        use opt_prop,  only : mu_water, mu_protein
!        use thermalConstants

!        implicit none

    !    integer, intent(IN)    :: numpoints
    !    real,    intent(INOUT) :: temp(0:numpoints+1, 0:numpoints+1, 0:numpoints+1)
    !    real,    intent(IN)    :: ablateTemp

    !    integer :: i, j, k
  !    real :: summ
  !      WaterContent = getWaterContent(Q, watercontent)

  !      do k = 1, nzg
  !          do j = 1, nyg
  !              do i = 1, nxg


  !                if(rhokap(i,j,k) > 100.)then !brain tissue
  !                  density(i,j,k) = getSkinDensity
  !                  heatCap(i,j,k) = getSkinHeatCap
  !                  kappa(i,j,k) = getSkinThermalCond
  !                  coeff(i,j,k) = delt/ (density(i,j,k) * heatcap(i,j,k))
  !                else !water
  !                  density(i,j,k) = getWaterDensity
  !                  heatCap(i,j,k) = getWaterHeatCap
  !                  kappa(i,j,k) = getWaterThermalCond
  !                  coeff(i,j,k) = delt/ (density(i,j,k) * heatcap(i,j,k))
  !                endif


                    !ablate tissue
                !    if(temp(i,j,k) >= ablateTemp + 273.d0)then
                !        rhokap(i,j,k) = 0.d0
                        ! temp(i,j,k) = 273.d0+25.d0
                !    elseif(rhokap(i,j,k) > 0.)then
                !        if(temp(i,j,k) >= 273.+ablateTemp)print*,"error! ablation when no ablation should take place",rhokap(i,j,k)
                !        density(i,j,k) = getSkinDensity(WaterContent(i,j,k))
                !        rhokap(i,j,k) = watercontent(i,j,k) * mu_water + mu_protein
                !        heatCap(i,j,k) = getSkinHeatCap(waterContent(i,j,k))

                !        kappa(i,j,k) = getSkinThermalCond(WaterContent(i,j,k), density(i,j,k))
                !        coeff(i,j,k) = delt/ (density(i,j,k) * heatcap(i,j,k))
                !    end if
                    !remove tissue if surronding tissue has been ablated
                !    summ = 0.d0
                !    summ = rhokap(i,j,k+1) + rhokap(i,j+1,k) + rhokap(i+1,j,k) + rhokap(i,j,k-1) + rhokap(i,j-1,k) + rhokap(i-1,j,k)
                !    if(summ == 0.d0)rhokap(i,j,k)=0.d0
                !    if(rhokap(i,j,k) <= 0.01)then
                !        density(i,j,k) = airDensity(temp(i,j,k))
                !        heatcap(i,j,k) = 1.006d3
                !        rhokap(i,j,k) = 0.
                !        kappa(i,j,k) = airThermalCond(temp(i,j,k), loops_left)
                !        alpha(i,j,k) = kappa(i,j,k) / (density(i,j,k) * heatcap(i,j,k))
                !        coeff(i,j,k) = delt/ (airDensity(temp(i,j,k)) * heatcap(i,j,k))
                !    end if
  !              end do
  !          end do
  !      end do
  !  end subroutine setupThermalCoeff


    !power functions for laser pulse
    real function getPwrGaussian() result (getPwr)

        implicit none

        real :: mu, sig, fact

        fact = (2. * sqrt(2. * log(2.)))
        mu = fact * pulseLength
        sig = pulseLength / fact ! convert FWHM to sigma

        getPwr = power * exp(-(time - mu)**2 / (2.d0*sig**2))

    end function getPwrGaussian


    real function getPwrTopHat() result (getPwr)

        implicit none

        if(.not. laser_flag)then
            getPwr = 0.d0
            return
        else
            getPwr = power
            return
        end if

    end function getPwrTopHat


    real function getPwrTriangular() result (getPwr)

        implicit none

        real :: m, c

        m = power / pulseLength
        c = 2.d0 * power

        if(.not. laser_flag)then
            getPwr = 0.d0
        else
            if(pulseFlag)then
                getPwr = -m * time + c
                if(getPwr < 0.d0)getPwr=0.d0
            else
                if(time >= pulseLength)then
                    pulseFlag=.true.
                    getPwr = -m * time + c
                    if(getPwr < 0.d0)getPwr=0.d0
                else
                    getPwr = m * time
                end if
            end if
        end if

    end function getPwrTriangular


    subroutine Arrhenius(temp, delt, tissue, Threstime, zi, zf, numpoints)
    ! calculate tisue damage
    ! and time thresholds for burns

        use iarray,   only : rhokap

        implicit none

        integer, intent(IN)    :: zi,zf, numpoints
        real,    intent(IN)    :: temp(0:numpoints+1,0:numpoints+1,0:numpoints+1), delt
        real,    intent(INOUT) :: tissue(:,:,:), Threstime(:,:,:,:)

        double precision :: A, dE, R, first, second, third
        integer          :: x,y,z

        A = 3.1d98
        dE = 6.3d5
        R  = 8.314d0

        first = .53d0
        second = 1.d0
        third = 10000.d0

        do z = zi, zf
            do y = 1, numpoints
                do x = 1, numpoints
                    if(temp(x,y,z) >= 43.+273. .and. temp(x,y,z) < 100d0+273d0 .and. rhokap(x,y,z) >= 0.)then
                            tissue(x,y,z) = tissue(x,y,z) + delt*A*exp(-dE/(R*temp(x,y,z)))

                    end if
                    !calculate threshold times for different thermal injuries
                    if(Threstime(x,y,z,1) == 0.d0 .and. tissue(x,y,z) >= first)then
                        Threstime(x,y,z,1) = time
                    elseif(Threstime(x,y,z,2) == 0.d0 .and. tissue(x,y,z) >= second)then
                        Threstime(x,y,z,2) = time
                    elseif(Threstime(x,y,z,3) == 0.d0 .and. tissue(x,y,z) >= third)then
                        Threstime(x,y,z,3) = time
                    end if
                end do
            end do
        end do

    end subroutine  Arrhenius
end Module Heat
