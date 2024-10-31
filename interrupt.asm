.data

PCB_BLOCKS: .space 1440 # 144 bytes x 10 Tasks
PCB_STACKS: .space 1000 # (4 bytes x 25 variables) x 10 PCB's
RUNNING: .word 0x00000000
READY: .word 0x00000000
LAST_READY: .word 0x00000000

RUNNING_str: .asciiz "RUNNING: "
READY_str: .asciiz "READY: "
next_str: .asciiz " -> "

ALL_INT_MASK: .word 0x0000ff00
KBD_INT_MASK: .word 0x00010000

RCR: .word 0xffff0000

.text
int_enable:
	mfc0 $t0 , $12
	lw $t1 , ALL_INT_MASK
	not $t1 , $t1
	and $t0 , $t0 , $t1 # disable all int
	lw $t1, KBD_INT_MASK
	or $t0, $t0, $t1
	mtc0 $t0 , $12
	
	# now enable keyboard interrupts
	lw $t0, RCR
	li $t1 , 0x00000002
	sw $t1 0($t0)
	
	jr $ra

.kdata

save_v0 : .word
save_at: .word
save_t0: .word

.ktext 0x80000180

move $k0 , $at
sw $k0 , save_at
sw $v0 , save_v0
sw $t0, save_t0

mfc0 $k0 , $13 # 13 = cause register
srl $t1 , $k0 ,2
andi $t1 , $t1 ,0x1f # extract bits 2?6
bnez $t1 , non_int # not an interrupt
andi $t2 , $k0 ,0x00000100 # is bit 8 set?
bnez $t2 , timer_int
b int_end

non_int:
	mfc0 $k0 , $14
	addiu $k0 , $k0 ,4
	mtc0 $k0 , $14
	b int_end

timer_int:
	jal print_PCB_sequence
	jal save_running_task_registers
	
	lw $t0, RUNNING
	lw $t1, LAST_READY
	sw $t0, 140($t1) # last_ready -> next = run
	
	lw $t0, RUNNING
	sw $t0, LAST_READY # last_ready = run
	
	lw $t0, READY
	sw $t0, RUNNING # run = ready
	
	lw $t0, READY
	lw $t0, 140($t0) # t0 = ready->next
	sw $t0, READY # ready = ready->next
	
	lw $t0, RUNNING
	sw $zero, 140($t0) # run -> next = null
	
	jal print_PCB_sequence
	jal load_next_task_registers
	
int_end:
	lw $v0 , save_v0
	lw $k0 , save_at
	lw $t0, save_t0
	move $at , $k0
	mtc0 $zero , $13
	mfc0 $k0 , $12
	andi $k0 , 0xfffd
	ori $k0 , 0x0001
	mtc0 $k0 , $12
	eret
	
save_running_task_registers:
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	
	lw $t0, RUNNING
	
	sw $at, at($t0)
	sw $v0, v0($t0)
	sw $v1, v1($t0)
	sw $a0, a0($t0)
	sw $a1, a1($t0)
	sw $a2, a2($t0)
	sw $a3, a3($t0)
	#sw $t0, t0($t0)
	sw $t1, t1($t0)
	sw $t2, t2($t0)
	sw $t3, t3($t0)
	sw $t4, t4($t0)
	sw $t5, t5($t0)
	sw $t6, t6($t0)
	sw $t7, t7($t0)
	sw $s0, s0($t0)
	sw $s1, s1($t0)
	sw $s2, s2($t0)
	sw $s3, s3($t0)
	sw $s4, s4($t0)
	sw $s5, s5($t0)
	sw $s6, s6($t0)
	sw $s7, s7($t0)
	sw $t8, t8($t0)
	sw $t9, t9($t0)
	sw $k0, k0($t0)
	sw $k1, k1($t0)
	sw $gp, gp($t0)
	sw $sp, sp($t0)
	sw $fp, fp($t0)
	sw $ra, ra($t0)

	lw $t1, RUNNING

	mfhi $t0
	sw $t0, hi($t1) # hi
	mflo $t0
	sw $t0, lo($t1) # lo
			
	mfc0 $t0, $14
	sw $t0, epc($t1) # epc
	
	lw $t0, 0($sp)
	lw $t1, RUNNING
	sw $t0, t0($t1)
	
	addi $sp, $sp, 4
	
	jr $ra
	
load_next_task_registers:
	lw $t0, RUNNING

	lw $at, at($t0)
	lw $v0, v0($t0)
	lw $v1, v1($t0)
	lw $a0, a0($t0)
	lw $a1, a1($t0)
	lw $a2, a2($t0)
	lw $a3, a3($t0)
	
	lw $t1, epc($t0)
	mtc0 $t1, $14 # load next task's epc
	
	lw $t1, t1($t0)
	lw $t2, t2($t0)
	lw $t3, t3($t0)
	lw $t4, t4($t0)
	lw $t5, t5($t0)
	lw $t6, t6($t0)
	lw $t7, t7($t0)
	lw $s0, s0($t0)
	lw $s1, s1($t0)
	lw $s2, s2($t0)
	lw $s3, s3($t0)
	lw $s4, s4($t0)
	lw $s5, s5($t0)
	lw $s6, s6($t0)
	lw $s7, s7($t0)
	lw $t8, t8($t0)
	lw $t9, t9($t0)
	lw $k0, k0($t0)
	lw $k1, k1($t0)
	lw $gp, gp($t0)
	lw $sp, sp($t0)
	lw $fp, fp($t0)
	
	lw $t0, t0($t0) # finally load t0
	
	jr $ra
	
print_PCB_sequence:
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	
	li $a0, '\n'
	print_char
	
	la $a0, RUNNING_str
	print_string
	
	li $a0, ' '
	print_char
	
	lw $s0, RUNNING
	lw $s1, 140($s0)
	
	move $a0, $s0
	print_int
	
	la $a0, next_str
	print_string
	
	move $a0, $s1
	print_int
	
	li $a0, '\n'
	print_char
	
	la $a0, READY_str
	print_string
	
	li $a0, ' '
	print_char
	print_char
	print_char
	
	lw $s0, READY    # task0
	lw $s1, 140($s0) # task1
	lw $s2, 140($s1) # task2
	lw $s3, 140($s2) # null
	
	move $a0, $s0
	print_int   # task0
	
	la $a0, next_str
	print_string
	
	move $a0, $s1
	print_int   # task1
	
	la $a0, next_str
	print_string
	
	move $a0, $s2
	print_int   # task2
	
	la $a0, next_str
	print_string
	
	move $a0, $s3
	print_int   # null
	
	li $a0, '\n'
	print_char
	print_char
	
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
print_stack_adress:
	lw $a0, 0($sp)
	print_int
	jr $ra
