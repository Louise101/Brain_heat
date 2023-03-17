MODULE iarray
!
!  Contains all array var names.
!
    implicit none
    save

    real, allocatable :: xface(:),yface(:),zface(:)
    real, allocatable :: rhokap(:,:,:), albedoar(:,:,:)
    real, allocatable :: jmean(:,:,:),jmeanGLOBAL(:,:,:)
    real, allocatable :: jmean_on(:,:,:), jmean_off(:,:,:)
    real, allocatable :: temp(:,:,:), tissue(:,:,:)
    real, allocatable :: ThresTime(:,:,:,:), ThresTimeGLOBAL(:,:,:,:)
    real, allocatable:: block_rho(:,:,:), block_alb(:,:,:), block_jmean(:,:,:)!, brain_block(:,:,:), brain_block_a(:,:,:)
    !real, allocatable:: rho_full(:,:,:), alb_full(:,:,:)

    real, allocatable:: jmean_slice(:,:,:), temp_slice(:,:,:)

    real, allocatable:: coeff(:,:,:),alpha(:,:,:),density(:,:,:), kappa(:,:,:)
    real, allocatable:: heatCap(:,:,:), Q(:,:,:), watercontent(:,:,:)

end MODULE iarray
