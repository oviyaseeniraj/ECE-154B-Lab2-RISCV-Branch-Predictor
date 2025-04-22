.data
.align 2
result: .word 0

.text
.globl _start
_start:
    li s0, 0          # counter for branch type 1
    li s1, 0          # counter for branch type 2
    li s2, 0          # outer loop counter
    li s3, 32         # outer loop limit
    li s4, 0x12345678 # Secret pattern for aliasing
    li s5, 0          # inner loop counter
    li s6, 4          # inner loop limit

outer_loop:
    # This branch will alias in BTB due to address pattern
    andi t0, s2, 0x1F # Create aliasing (32 entries)
    slli t0, t0, 2    # Word align
    beq t0, x0, target_A
    
    # Complex pattern branch (hard to predict)
    xor t1, s2, s4     # XOR with secret pattern
    andi t1, t1, 0x1F  # Create more aliasing
    bne t1, x0, target_B
    
    # Unpredictable jump pattern
    andi t2, s2, 0x3  # 4 different jump targets
    slli t2, t2, 2
    jalr x0, t2(x0)    # Will alias in BTB
    
target_A:
    addi s0, s0, 1     # Count type 1 branches
    j inner_loop_setup

target_B:
    addi s1, s1, 1     # Count type 2 branches

inner_loop_setup:
    li s5, 0           # Reset inner counter

inner_loop:
    # This branch creates interference in PHT
    andi t3, s5, 0x1   # Alternating pattern
    beq t3, x0, skip_inner
    
    # Nested hard-to-predict branch
    xor t4, s5, s2     # XOR with outer counter
    andi t4, t4, 0x3   # 4 possible outcomes
    bne t4, x0, skip_inner
    
skip_inner:
    addi s5, s5, 1
    bne s5, s6, inner_loop

    addi s2, s2, 1
    bne s2, s3, outer_loop

    # Store results
    la t5, result
    sw s0, 0(t5)       # Store branch type 1 count
    sw s1, 4(t5)       # Store branch type 2 count

    # Exit
    li a7, 93
    ecall

# Jump targets (all alias to same BTB entry)
.align 2
target_0:
    j inner_loop_setup
target_1:
    addi s0, s0, -1    # Mess with counters
    j inner_loop_setup
target_2:
    addi s1, s1, -1
    j inner_loop_setup
target_3:
    addi s0, s0, 2
    j inner_loop_setup