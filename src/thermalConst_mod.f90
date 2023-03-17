module thermalConstants

    implicit none

    real, parameter :: airHeatCap=1.006d3, tempAir=25.d0+273.d0, tempAir4=tempAir**4, lw=2256.d3
    real, parameter :: waterContentInit=.75, proteinContent=1.d0-waterContentInit
    real            :: skinDensityInit, QVapor

    contains

        real function airThermalCond(T, i)
        !data taken from engineeringtoolbox.com and fitted in gnuplot
        !temp input in kelvin
            implicit none

            real, intent(IN) :: T!in Kelvin
            real, parameter  :: a=-0.188521, b=0.000367259, c=0.212453
            integer :: i

            if(t < 0.)then
                print*,i,'loop #'
                error stop "Negative temp in kelvin"
            end if
            airThermalCond = a * exp(-b * (T - 273.15d0)) + c
        end function airThermalCond


        real function airDensity(T)
        !values taken from wikipedia
        !temp input in kelvin
            implicit none

            real, intent(IN) :: T !in kelvin
            real, parameter  :: pressue1ATM=101.325d3, Rspec=287.058d0

            airDensity = pressue1ATM / (Rspec * T)

        end function airDensity


        elemental real function getWaterContent(Qcurrent, watercurrent)

            implicit none

            real, intent(IN) :: Qcurrent, watercurrent

            getWaterContent = max(min(min(waterContentInit - waterContentInit * (Qcurrent / QVapor), waterContentInit), &
                                  watercurrent), 0.0)

        end function getWaterContent

        subroutine therm_set
     !
     !  subroutine to set tissue optical properties 10.6um
     !
         !use opt_prop

        implicit none
        real :: getSkinDensity, getSkinHeatCap, getSkinThermalCond, getWaterDensity,getWaterHeatCap,getWaterThermalCond

      getSkinDensity = 1046!average brain density from itis.swiss kg m-3
      getSkinHeatCap = 3630 !average brain heat capacity from itis.swiss J/kg/C
      getSkinThermalCond = 0.51 !average brain thermal conductivity, from itis.swiss, W/m/C
      getWaterDensity = 994 !average water density from itis.swiss kg m-3
      getWaterHeatCap = 4178 !average water heat capacity from itis.swiss J/kg/C
      getWaterThermalCond = 0.6 !average brain thermal conductivity, from itis.swiss, W/m/C


      end subroutine therm_set

      !  real function getSkinDensity!(waterContent)
        !get dsensity of skin based upon water content. In Kg m-3

          !  implicit none

          !  real, intent(IN) :: waterContent

          !  getSkinDensity = 1000.d0 / (waterContent + 0.649d0*proteinContent) !new function with protein
            !getSkinDensity = 1046 !average brain density from itis.swiss kg m-3

      !  end function getSkinDensity


      !  real function getSkinHeatCap!(waterContent)
        !get heat capacity for skin. In J Kg-1 K-1

          !  implicit none

          !  real, intent(IN) :: waterContent

            !getSkinHeatCap = 1000.d0*(4.2*waterContent + 1.09d0*proteinContent) !new function with protein
            !getSkinHeatCap = 3630 !average brain heat capacity from itis.swiss J/kg/C

      !  end function getSkinHeatCap


      !  real function getSkinThermalCond!(waterContent, currentDensity)
        !get thermal conductivity for skin. In W m-1 K-1

          !  implicit none

          !  real, intent(IN) :: waterContent, currentDensity

            !getSkinThermalCond = currentDensity * (6.28d-4*waterContent + 1.17d-4*proteinContent)!new function with protein
          !getSkinThermalCond = 0.51 !average brain thermal conductivity, from itis.swiss, W/m/C

      !  end function getSkinThermalCond

      !  real function getWaterDensity
        !get dsensity of skin based upon water content. In Kg m-3

          !  implicit none


          !  getSkinDensity = 1000.d0 / (waterContent + 0.649d0*proteinContent) !new function with protein
          !  getWaterDensity = 994 !average water density from itis.swiss kg m-3

      !  end function getWaterDensity


      !  real function getWaterHeatCap
        !get heat capacity for skin. In J Kg-1 K-1

          !  implicit none


            !getSkinHeatCap = 1000.d0*(4.2*waterContent + 1.09d0*proteinContent) !new function with protein
          !  getWaterHeatCap = 4178 !average water heat capacity from itis.swiss J/kg/C

      !  end function getWaterHeatCap


      !  real function getWaterThermalCond
        !get thermal conductivity for skin. In W m-1 K-1

        !    implicit none

            !getSkinThermalCond = currentDensity * (6.28d-4*waterContent + 1.17d-4*proteinContent)!new function with protein
          !s  getWaterThermalCond = 0.6 !average brain thermal conductivity, from itis.swiss, W/m/C

      !  end function getWaterThermalCond
end module thermalConstants
