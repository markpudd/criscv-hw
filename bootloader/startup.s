.section .init, "ax"
.global _fstart

_fstart:
    # 1. Clear out relaxation side-effects so the linker assigns gp correctly
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop


        .equ    PORT,        0xffffff00
        .equ    TOGGLES,     5
        .equ    DELAY_ITERS, 625000
        .equ    MASK,        0xff
     # 2. Initialise your stack pointer
       
 /* li s0, 0x00004000
         li   a5,0  
         li   a4,1
         sw	zero,-8(s0)
         sw	a4,-4(s0)



         lw	a5,-4(s0)
         sw	a5,-16(s0)
         #li      a5, 0  
         addi	a5,a5,99
         sw	a5,-4(s0)
         lw	a5,-4(s0)
         addi	a5,a5,2
         sw	a5,-4(s0)
         lw	a5,-4(s0)
         sw	zero,-12(s0)

         li s0,0x00004000
         sw	a5,-128(s0)*/
         li      t1, 1  
reset_run:
        li      t0, PORT            # addi t0, zero, -256  (fits in imm12)
          # shadow copy of the port value
        #lb	t1,-4(s0)
        li      t2, TOGGLES         # toggles remaining
 

toggle_loop:
        sb      t1, 0(t0) 
        xori    t1, t1, MASK        # flip all 8 bits
          # drive the port
 
        li      t3, DELAY_ITERS
delay:
        addi    t3, t3, -1
     
        bnez    t3, delay
 
        addi    t2, t2, -1
       
        bnez    t2, toggle_loop
 



  #jal ra, reset_run  
    # 2. Initialise your stack pointer
  li sp, 0x00AFFFFC
 # li sp,0x00004000
  # 3. Jump to C function
    jal ra, main          # Ensure this matches your exact C function name!
