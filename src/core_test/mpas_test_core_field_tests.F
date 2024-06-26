! Copyright (c) 2013,  Los Alamos National Security, LLC (LANS)
! and the University Corporation for Atmospheric Research (UCAR).
!
! Unless noted otherwise source code is licensed under the BSD license.
! Additional copyright and license information can be found in the LICENSE file
! distributed with this code, or at http://mpas-dev.github.com/license.html
!

!#define HALO_EXCH_DEBUG

module test_core_field_tests

   use mpas_derived_types
   use mpas_pool_routines
   use mpas_field_routines
   use mpas_dmpar
   use mpas_threading
   use mpas_log
   use mpas_timer
   use mpas_attlist

   implicit none
   private

   public :: test_core_test_fields

   contains

   !***********************************************************************
   !
   !  routine test_core_test_fields
   !
   !> \brief   MPAS Test Core field tests routine
   !> \author  Doug Jacobsen
   !> \date    04/26/2016
   !> \details 
   !>  This routine performs tests related to field types.
   !
   !-----------------------------------------------------------------------
   subroutine test_core_test_fields(domain, threadErrs, err)!{{{

      type (domain_type), intent(inout) :: domain
      integer, dimension(:), intent(out) :: threadErrs
      integer, intent(out) :: err

      integer :: threadNum
      integer :: iErr

      err = 0

      threadNum = mpas_threading_get_thread_num()

      call mpas_timer_start('field tests')
      if ( threadNum == 0 ) then
         call mpas_log_write(' - Performing attribute list tests')
      end if
      call test_core_attribute_list_test(domain, threadErrs, iErr)
      call mpas_threading_barrier()
      if ( threadNum == 0 ) then
         call mpas_log_write('    -- Return code: $i', intArgs=(/iErr/))
         err = ior(err, iErr)
      end if

      call mpas_timer_stop('field tests')

   end subroutine test_core_test_fields!}}}

   !***********************************************************************
   !
   !  routine test_core_attribute_list_test
   !
   !> \brief   MPAS Test Core attribute list tests routine
   !> \author  Doug Jacobsen
   !> \date    04/26/2016
   !> \details 
   !>  This routine performs tests of attribute lists.
   !
   !-----------------------------------------------------------------------
   subroutine test_core_attribute_list_test(domain, threadErrs, ierr)!{{{
      type (domain_type), intent(inout) :: domain
      integer, dimension(:), intent(out) :: threadErrs
      integer, intent(out) :: ierr

      type ( att_list_type ), pointer :: srcList, destList
      integer :: srcInt, destInt, modifyInt
      integer, dimension(:), pointer :: srcIntA, destIntA, modifyIntA
      real (kind=RKIND) :: srcReal, destReal, modifyReal
      real (kind=RKIND), dimension(:), pointer :: srcRealA, destRealA
      real (kind=RKIND), dimension(:), pointer :: modifyRealA
      character (len=StrKIND) :: srcText, destText, modifyText

      integer :: threadNum

      iErr = 0
      threadErrs = 0

      threadNum = mpas_threading_get_thread_num() + 1

      if ( threadNum == 1 ) then
         allocate(srcList)
         nullify(destList)

         nullify(srcList % next)
         srcList % attName = ''
         srcList % attType = -1

         allocate(srcIntA(3))
         allocate(srcRealA(5))

         srcInt = 3
         srcIntA(:) = 4
         srcReal = 5.0_RKIND
         srcRealA(:) = 6.0_RKIND
         srcText = 'testingString'

         call mpas_add_att(srcList, 'testInt', srcInt)
         call mpas_add_att(srcList, 'testIntA', srcIntA)
         call mpas_add_att(srcList, 'testReal', srcReal)
         call mpas_add_att(srcList, 'testRealA', srcRealA)
         call mpas_add_att(srcList, 'testText', srcText)

         call mpas_duplicate_attlist(srcList, destList)

         call mpas_get_att(destList, 'testInt', destInt)
         call mpas_get_att(destList, 'testIntA', destIntA)
         call mpas_get_att(destList, 'testReal', destReal)
         call mpas_get_att(destList, 'testRealA', destRealA)
         call mpas_get_att(destList, 'testText', destText)

         destIntA(:) = destIntA(:) - srcIntA(:)
         destRealA(:) = destRealA(:) - srcRealA(:)

         if ( srcInt /= destInt ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('      Duplicate int does not match', MPAS_LOG_ERR)
         end if

         if ( sum(destIntA) /= 0 ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Duplicate int array does not match', MPAS_LOG_ERR)
         end if

         if ( srcReal /= destReal ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Duplicate real does not match', MPAS_LOG_ERR)
         end if

         if ( sum(destRealA) /= 0.0_RKIND ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Duplicate real array does not match', MPAS_LOG_ERR)
         end if

         if ( trim(srcText) /= trim(destText) ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('      Duplicate string does not match', MPAS_LOG_ERR)
         end if

         deallocate(destIntA)
         deallocate(destRealA)
         allocate(modifyIntA(3))
         allocate(modifyRealA(5))

         modifyInt = 2
         modifyIntA(:) = 2
         modifyReal = 2.0_RKIND
         modifyRealA(:) = 2.0_RKIND
         modifyText = 'Modified'

         call mpas_modify_att(srcList, 'testInt', modifyInt)
         call mpas_modify_att(srcList, 'testIntA', modifyIntA)
         call mpas_modify_att(srcList, 'testReal', modifyReal)
         call mpas_modify_att(srcList, 'testRealA', modifyRealA)
         call mpas_modify_att(srcList, 'testText', modifyText)

         call mpas_get_att(srcList, 'testInt', destInt)
         call mpas_get_att(srcList, 'testIntA', destIntA)
         call mpas_get_att(srcList, 'testReal', destReal)
         call mpas_get_att(srcList, 'testRealA', destRealA)
         call mpas_get_att(srcList, 'testText', destText)

         if ( destInt /= modifyInt ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Int not modified correctly', MPAS_LOG_ERR)
         end if

         if (sum(destIntA) /= sum(modifyIntA)) then  
            threadErrs( threadNum ) = 1
            call mpas_log_write('     IntA not modified correctly', MPAS_LOG_ERR)
         end if

         if ( destReal /= modifyReal ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Real not modified correctly', MPAS_LOG_ERR)
         end if

         if ( sum(destRealA) /= sum(modifyRealA) ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     RealA not modified correctly', MPAS_LOG_ERR)
         end if

         if ( trim(destText) /= trim(modifyText)  ) then
            threadErrs( threadNum ) = 1
            call mpas_log_write('     Text not modified correctly', MPAS_LOG_ERR)
         end if

         call mpas_deallocate_attlist(srcList)
         call mpas_deallocate_attlist(destList)
        
         deallocate(destIntA)
         deallocate(destRealA)
         deallocate(modifyRealA)
         deallocate(modifyIntA)
         deallocate(srcIntA)
         deallocate(srcRealA)
      end if

      call mpas_threading_barrier()

      if ( sum(threadErrs) /= 0 ) then
         iErr = 1
      end if

   end subroutine test_core_attribute_list_test!}}}

end module test_core_field_tests
