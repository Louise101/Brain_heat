module sourceph_mod

    implicit none

    contains

        subroutine sourcephCO2(xmax,ymax,zmax,xcell,ycell,zcell,iseed)
        ! get phton entry location for C02 laser

            use constants, only : nxg, nyg, nzg, twopi
            use photon_vars

            implicit none


            integer, intent(OUT)   :: xcell, ycell, zcell
            integer, intent(INOUT) :: iseed
            real,    intent(IN)    :: xmax, ymax, zmax
            real                   :: ran2

            real :: spotSize, theta, r

            spotSize    = 250d-4 !um

            !http://mathworld.wolfram.com/DiskPointPicking.html
            !sample circle uniformly
            !sample radius between [0,r^2]
            r = ran2(iseed) * (spotSize/2.)**2
            theta = ran2(iseed) * twopi
            xp = sqrt(r) * cos(theta)
            yp = sqrt(r) * sin(theta)
            zp = zmax-(1.e-8*(2.*zmax/nzg))

            phi = twopi * ran2(iseed)
            cosp = cos(phi)
            sinp = sin(phi)
            sint = 0.
            cost = -1.

            nxp = sint * cosp
            nyp = sint * sinp
            nzp = cost

            !*************** Linear Grid *************************
            xcell=int(nxg*(xp+xmax)/(2.*xmax))+1
            ycell=int(nyg*(yp+ymax)/(2.*ymax))+1
            zcell=int(nzg*(zp+zmax)/(2.*zmax))+1
            !*****************************************************
        end subroutine sourcephCO2

        subroutine evenDis(xmax,ymax,zmax,xcell, ycell, zcell, iseed)
   	! Emits photons evenly across the top of the grid

   	use constants, only : nxg, nyg, nzg, TWOPI
        use photon_vars

        implicit none

        integer, intent(OUT)   :: xcell, ycell, zcell
        integer, intent(INOUT) :: iseed
        real,    intent(IN)    :: xmax, ymax, zmax
        real                   :: ran2

        real :: theta


        	zp = -zmax + (1.d-5 * (2.d0*zmax/1190))



        	if(ran2(iseed) .gt. 0.5)then
        	xp=-ran2(iseed)*xmax
        	else
        	xp=ran2(iseed)*xmax
        	end if


        	if(ran2(iseed) .gt. 0.5)then
        	yp=-ran2(iseed)*ymax
        	else
        	yp=ran2(iseed)*ymax
        	end if


   		   phi = TWOPI * ran2(iseed)
            cosp = cos(phi)
            sinp = sin(phi)
      !     cost = 1.d0 !direct irradiation
           cost=ran2(iseed) !diffuse irradiation
            sint = sqrt(1. - cost**2)

            nxp = sint * cosp
            nyp = sint * sinp
            nzp = cost

            !*************** Linear Grid *************************
            xcell=int(nxg*(xp+xmax)/(2.*xmax))+1
            ycell=int(nyg*(yp+ymax)/(2.*ymax))+1
            zcell=int(nzg*(zp+zmax)/(2.*zmax))+1
            !*****************************************************



        end subroutine evenDis

        subroutine fibre_lille(xcell, ycell, zcell, iseed, xmax, ymax, zmax)
    ! Emits photons evenly across the top of the grid

        use constants, only : nxg, nyg, nzg, TWOPI, PI
        use photon_vars

        implicit none

        integer, intent(OUT)   :: xcell, ycell, zcell
        integer, intent(INOUT) :: iseed
        real, intent(IN) :: xmax, ymax,zmax

        real :: ran2, theta, dd,d, ranran


            dd=ran2(iseed)*2.5
            d=dd/2.

            ranran=ran2(iseed)

          !  if(ranran .le. 0.5)then
          !  xp=(xmax) -( 4.06)!0-(2.*xmax-4.06)!0.
          !  yp=(ymax) - (2.4) +d!(0.1-d)!-(2.*ymax-2.0)!0.1 -d
          !  zp=zmax-6.37!0-(2.*zmax-6.37)!0.
          !else
          !  xp=(xmax) -( 4.06)!0-(2.*xmax-4.06)!0.
          !  yp=(ymax) - (2.4) -d!(0.1+d)!-(2.*ymax-2.0)!0.1 +d
          !  zp=zmax-6.37!0-(2.*zmax-6.37)!0.
          !endif

          if(ranran .le. 0.5)then !see moving oxygen lab notes for new dimension calcs
          xp=0-1.2!+xmax !(xmax) !-( 1.4)!0-(2.*xmax-4.06)!0.
          yp=0+0.1  !(ymax)! - (0.88) +d!(0.1-d)!-(2.*ymax-2.0)!0.1 -d
          zp=0-0.4+d!zmax!-2.22!0-(2.*zmax-6.37)!0.
        else
          xp=0-1.2!+xmax!(xmax)! -( 1.4)!0-(2.*xmax-4.06)!0.
          yp=0+0.1 !(ymax)! - (0.88) -d!(0.1+d)!-(2.*ymax-2.0)!0.1 +d
          zp=0-0.4-d!zmax!-2.22!0-(2.*zmax-6.37)!0.
        endif



             cost=2.*ran2(iseed)-1.
             sint=(1.-cost*cost)
             if(sint .le. 0.)then
               sint=0.
             else
               sint=sqrt(sint)
             end if

             phi=TWOPI*ran2(iseed)
             cosp=cos(phi)
             sinp=sin(phi)



                nxp = sint * cosp
                nyp = sint * sinp
                nzp = cost


            !*************** Linear Grid *************************
            xcell=int(nxg*(xp+xmax)/(2.*xmax))+1
            ycell=int(nyg*(yp+ymax)/(2.*ymax))+1
            zcell=int(nzg*(zp+zmax)/(2.*zmax))+1
            !*****************************************************



        end subroutine fibre_lille

        real function ranu(a, b, iseed)
        ! return on call a random number and updated iseed
        ! random number is uniformly distributed between a and b
        !  INPUT:
        !        a       real     lower limit of boxcar
        !        b       real     upper limit of boxcar
        !        iseed   integer  seed integer used fot the random number generator
        !  OUTPUT:
        !        ranu    real     uniform random number
        !        iseed   integer  seed used for next call

            implicit none

            real,    intent(IN)    :: a, b
            integer, intent(INOUT) :: iseed
            real :: ran2

            ranu = a + ran2(iseed) * (b - a)
        end function ranu


        real function rang(avg, sigma, iseed)
        ! return on call a random number and updated iseed
        ! random number is from a gaussian distrbution
        ! used the Marsaglia polar method
        !  INPUT:
        !        avg       real     mean of gaussian dist.
        !        sigma     real     var of gaussian dist
        !        iseed     integer  seed integer used fot the random number generator
        !  OUTPUT:
        !        rang    real     gaussian distributed random number
        !        iseed   integer  seed used for next call

            implicit none

            real,    intent(IN)    :: avg, sigma
            integer, intent(INOUT) :: iseed
            real :: u, s, tmp

            s = 1.d0
            do while(s.ge.1.)
                u = ranu(-1.,1.,iseed)
                s = ranu(-1.,1.,iseed)
                s = s**2. + u**2.
            end do
            tmp = u*sqrt(-2.*log(s)/s)

            rang = avg + sigma*tmp

        end function rang

end MODULE sourceph_mod
