.data

RUNNING_str: .asciiz "RUNNING: "
READY_str: .asciiz "READY: "
next_str: .asciiz " -> "

new_task_str: .asciiz "New task!"
sleep_str: .asciiz "Going to sleep!"
test_str: .asciiz "Able to use the digital lab sim counter!"

ALL_INT_MASK: .word 0x0000ff00
KBD_INT_MASK: .word 0x00010000
TIMER_INT_MASK: .word 0x00000400

RCR: .word 0xffff0000
COUNTER_INT_ENABLE: .word 0xFFFF0013

.text
int_enable:
	mfc0 $t0 , $12
	lw $t1 , ALL_INT_MASK
	not $t1 , $t1
	and $t0 , $t0 , $t1 # disable all int
	lw $t1, KBD_INT_MASK
	or $t0, $t0, $t1
	#lw $t1, TIMER_INT_MASK
	#or $t0, $t0, $t1
	mtc0 $t0 , $12
	
	# now enable keyboard interrupts
	lw $t0, RCR
	li $t1 , 0x00000002
	sw $t1 0($t0)
	
	#li $t0, 1
	#sb $t0, COUNTER_INT_ENABLE
	
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
andi $t2, $k0, 0x00000400 # check for timer interrupt from digital lab sim
#bnez $t2, test_int
andi $t2, $t1, 13
bnez $t2, trap_int
bnez $t1 , non_int # not an interrupt
#beq $t1, 13, trap_stuff
andi $t2 , $k0 ,0x00000100 # is bit 8 set?
bnez $t2 , timer_int
b int_end

non_int:
	mfc0 $k0 , $14
	addiu $k0 , $k0 ,4
	mtc0 $k0 , $14
	b int_end

test_int:
	la $a0, test_str
	print_string
	b int_end

trap_int:
	beq $a0, 1, new_task_int
	beq $a0, 2, sleep_l
	b done_int
	sleep_l:
		jal sleep_task_int
	done_int:
		mfc0 $t0, $14
		addi $t0, $t0, 4
		mtc0 $t0, $14
		b int_end
		
# a1 = starting instruction, a2 = task priority
new_task_int:	
	lb $t0, CREATED_TASK_COUNTER
	bge $t0, 10, done
	bne $t0, 1, non_empty_list
	empty_list:
		lw $t0, AVAILABLE
		sw $t0, READY # ready = available
		
		lw $t0, READY
		sw $t0, LAST_READY # LAST_READY = READY
		
		lw $t0, LAST_READY
		sw $zero, NEXT_PCB($t0) # LAST_READY -> next = null
		
		lw $t0, AVAILABLE
		addi $t0, $t0, PCB_SIZE
		sw $t0, AVAILABLE # AVAILABLE += PCB_SIZE
		
		b increment_counter
	non_empty_list:
		lw $t0, LAST_READY
		lw $t1, AVAILABLE
		sw $t1, NEXT_PCB($t0)
		
		lw $t0, LAST_READY
		lw $t1, NEXT_PCB($t0) # t1 = LAST_READY -> next
		sw $t1, LAST_READY # LAST_READY = LAST_READY -> next
		
		lw $t0, LAST_READY
		sw $zero, NEXT_PCB($t0) # LAST_READY -> next = null
		
		lw $t0, AVAILABLE
		addi $t0, $t0, PCB_SIZE
		sw $t0, AVAILABLE # AVAILABLE += PCB_SIZE
	increment_counter:
		lb $t0, CREATED_TASK_COUNTER
		addi $t0, $t0, 1
		sb $t0, CREATED_TASK_COUNTER # CREATED_TASK_COUNTER += 1
	store_pid_epc: # also store TICKS_TO_SWITCH, TICKS_TO_WAIT and PRIORITY
		lw $t0, LAST_READY
		lb $t1, CREATED_TASK_COUNTER
		#addi $t1, $t1, -1
		sb $t1, PROCESS_ID($t0) # stores the new process id on the correspondent PCB
		sw $a1, epc($t0) # new task's starting address(epc)
		li $t1, 3
		sw $t1, TICKS_TO_SWITCH($t0) # TICKS_TO_SWITCH = 3
		sw $zero, TICKS_TO_WAIT($t0) # TICKS_TO_WAIT = 0
		sw $a2, PRIORITY($t0) # priority = a2
	done:
		mfc0 $t0, $14
		addi $t0, $t0, 4
		mtc0 $t0, $14
		la $a0, new_task_str
		print_string
		b int_end

# t0 = current node, t1 = next node
sleep_task_int:
	lw $t0, WAITING
	go_to_wait:
		bnez $t0, not_empty_list
		lw
		empty_list:
			lw $t0, RUNNING
			sw $t0, WAITING
			sw $a1, TICKS_TO_WAIT($t0)
			sw $zero, NEXT_PCB($t0)
			b done_sleep
		not_empty_list:
			lw $t1, NEXT_PCB($t0)
			bnez $t1, not_last_element
			lw $t2, TICKS_TO_WAIT($t0)
			ble $a1, $t2, insert_first
			lw $t2, RUNNING
			sw $a1, TICKS_TO_WAIT($t2)
			sw $zero, NEXT_PCB($t2)
			sw $t2, NEXT_PCB($t0)
			b done_sleep
			insert_first:
				lw $t2, RUNNING
				sw $a1, TICKS_TO_WAIT($t2)
				sw $t0, NEXT_PCB($t2)
				sw $t2, WAITING
				b done_sleep
		not_last_element:
			lw $t2, TICKS_TO_WAIT($t0)
			bge $a1, $t2, bigger_than_current
			## insert at the beggining
			lw $t3, RUNNING
			sw $a1, TICKS_TO_WAIT($t3)
			sw $t0, NEXT_PCB($t3)
			sw $t3, WAITING
			b done_sleep
			##
			bigger_than_current:
				lw $t2, TICKS_TO_WAIT($t1) # next node's TICKS_TO_WAIT
				bgt $a1, $t2, next_iteration
				lw $t3, RUNNING
				sw $a1, TICKS_TO_WAIT($t3)
				sw $t1, NEXT_PCB($t3)
				sw $t3, NEXT_PCB($t0)
				b done_sleep
			next_iteration:
				move $t0, $t1
				b not_empty_list
			
	done_sleep:
		sw $zero, RUNNING	
		#b done_int
		jr $ra
		
select_next_task:
	lw $t0, READY_HIGH
	beqz $t0, no_tasks_in_high
	lw $t1, NEXT_PCB($t0)
	li $t3, 3
	sw $t3, TICKS_TO_SWITCH($t0)
	sw $zero, $t0
	sw $t0, RUNNING
	sw $t1, READY_HIGH
	b exit_selector	
	no_tasks_in_high:
		lw $t0, READY_LOW
		beqz $t0, no_tasks_in_low
		lw $t1, NEXT_PCB($t0)
		li $t3, 3
		sw $t3, TICKS_TO_SWITCH($t0)
		sw $zero, $t0
		sw $t0, RUNNING
		sw $t1, READY_LOW
		b exit_selector
	no_tasks_in_low:
		lw $t0, IDLE_TASK
		sw $t0, RUNNING
	exit_selector:
		jr $ra

decrement_ticks_to_wait:
	lw $t0, WAITING
	beqz $t0, no_tasks_waiting
	decrement_loop:
		lb $t1, TICKS_TO_WAIT($t0)
		addi $t1, $t1, -1
		sb $t1, TICKS_TO_WAIT($t0)
		sw $t0, NEXT_PCB($t0)
		#beqz $t0, no_tasks_waiting
		bnez $t0, decrement_loop
	no_tasks_waiting:
		jr $ra

done_waiting:
	jr $ra

timer_int:
	#jal print_PCB_sequence
	lw $t0, RUNNING
	lw $t1, TICKS_TO_SWITCH($t0)
	
	jal decrement_ticks_to_wait
	
	lw $t2, WAITING
	lb $t2, TICKS_TO_WAIT($t2)
	
	bnez $t2, not_done_waiting
	jal done_waiting
	
	not_done_waiting:
		beqz $t1, switch_task
		
		addi $t1, $t1, -1
		sw $t1, TICKS_TO_SWITCH($t0)
		b int_end
	
	switch_task:
		li $a1, 100
		jal sleep_task_int
		jal select_next_task
	
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
	
print_TICKS_TO_SWITCH:
	la $t0, PCB_BLOCKS
	
	li $a0, '\n'
	print_char
	
	lw $a0, TICKS_TO_SWITCH($t0) # main task
	print_int
	
	la $a0, next_str
	print_string
	
	addi $t0, $t0, PCB_SIZE
	lw $a0, TICKS_TO_SWITCH($t0) # task 1
	print_int
	
	la $a0, next_str
	print_string
	
	addi $t0, $t0, PCB_SIZE
	lw $a0, TICKS_TO_SWITCH($t0) # task 2
	print_int
	
	la $a0, next_str
	print_string
	
	addi $t0, $t0, PCB_SIZE
	lw $a0, TICKS_TO_SWITCH($t0) # task 3
	print_int
	
	jr $ra
