module gridset_mod

   implicit none

   contains
      subroutine gridset(xmax,ymax,zmax,id)

         use constants, only : nxg,nyg,nzg
         use iarray!, only    : rhokap, xface, yface, zface, rhokap, block_rho, block_alb, albedoar
         use opt_prop, only  : kapppa
         use ch_opt

         implicit none

         integer :: i, j, k, id
         real    :: xmax, ymax, zmax, x, y, z

         if(id == 0)then
            print*, ' '
            print *, 'Setting up density grid....'
         end if
         !**********  Linear Cartesian grid. Set up grid faces ****************
         do i = 1, nxg+1
            xface(i) = (i-1) * 2. * xmax/nxg
         end do
         do i = 1, nyg+1
            yface(i) = (i-1) * 2. * ymax/nyg
         end do
         do i = 1, nzg+1
            zface(i) = (i-1) * 2. * zmax/nzg
         end do
         call init_opt1
         !**************  Loop through x, y, and z to set up grid density and refractive index grid.  ****
         rhokap = 0.
         do i = 1, nxg
           x = xface(i) - xmax + xmax/nxg
            do j = 1, nyg
              y = yface(j) - ymax + ymax/nyg
               do k = 1, nzg
                  !x = xface(i) - xmax + xmax/nxg
                  !y = yface(j) - ymax + ymax/nyg
                  z = zface(k) - zmax + zmax/nzg
                  !set density
                  !rhokap(i,j,k) = kappa
                  rhokap(i,j,k)= block_rho(i,j,k)
                  albedoar(i,j,k)=block_alb(i,j,k)
               end do
            end do
         end do
      end subroutine gridset
end module gridset_mod
