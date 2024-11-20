.data

RUNNING_str: .asciiz "RUNNING"
READY_HIGH_str: .asciiz "READY_H"
LAST_READY_HIGH_str: .asciiz "LAST_READY_H"
READY_LOW_str: .asciiz "READY_L"
LAST_READY_LOW_str: .asciiz "LAST_READY_L"
IDLE_str: .asciiz "IDLE"
WAITING_str: .asciiz "WAITING"
next_str: .asciiz " -> "

new_task_str: .asciiz "New task!"
sleep_str: .asciiz "Going to sleep!"
test_str: .asciiz "Removing the task from the running list!"
sel_idle_str: .asciiz "Selected the idle task"

ALL_INT_MASK: .word 0x0000ff00
KBD_INT_MASK: .word 0x00010000
TIMER_INT_MASK: .word 0x00000400

RCR: .word 0xffff0000
COUNTER_INT_ENABLE: .word 0xFFFF0013

TIMER_str: .asciiz "TIMER: "
N_INT_str: .asciiz "N_INT: "

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
	
	li $t1, 1
	sb $t1, COUNTER_INT_ENABLE
	
	jr $ra

.kdata

save_v0 : .space 4
save_at: .word
save_a0: .word

.ktext 0x80000180

move $k0 , $at
sw $k0 , save_at
sw $v0 , save_v0
sw $a0, save_a0

mfc0 $k0 , $13 # 13 = cause register
srl $t1 , $k0 ,2
andi $t1 , $t1 ,0x1f # extract bits 2?6
#andi $t2, $k0, 0x00000400 # check for timer interrupt from digital lab sim
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

# for teqi style "syscalls"
trap_int:
	beq $a0, 2, went_to_sleep
	beq $a0, 1, new_task_int
	b done_trap_int
	went_to_sleep:
		li $a0, 's'
		print_char
		b sleep_task_int
	done_trap_int:
		mfc0 $t0, $14
		addi $t0, $t0, 4
		mtc0 $t0, $14
	anyway:
		li $a0, 'a'
		print_char
		b int_end
		
# for keyboard interrupts
timer_int:
	# prints the PROCESS ID's of all tasks in all lists
	jal print_PCB_sequence
	
	# increment int counter, and if counter reaches 4, count it as a tick and decrement TICKS_TO_SWITCH(RUNNING)
	# and TICKS_TO_WAIT(WAITING)
	jal handle_ticks

	lw $t2, RUNNING
	lw $t2, TICKS_TO_SWITCH($t2)
	lw $t3, RUNNING
	lw $t3, PROCESS_ID($t3)
	bnez $t3, no_check_idle
	# if running task is the idle task
	check_idle:
		lw $t3, READY_HIGH
		beqz $t3, no_high
		jal save_running_task_registers
		jal switch_running
		jal print_PCB_sequence
		b check_waiting_list
		no_high:
			lw $t3, READY_LOW
			beqz $t3, no_check_idle
			jal save_running_task_registers
			jal switch_running
			jal print_PCB_sequence
			b check_waiting_list
	# if running task is NOT the idle task
	no_check_idle:
		bnez $t2, check_waiting_list
		jal save_running_task_registers
		jal switch_running
		jal print_PCB_sequence
	# checks if task on WAITING list has reached 0 ticks(TICKS_TO_WAIT)
	check_waiting_list:
		lw $t2, WAITING
		beqz $t2, check_if_running_is_empty # if WAITING list is empty
		lw $t2, TICKS_TO_WAIT($t2)
		bnez $t2, check_if_running_is_empty # if first task in WAITING is still sleeping
		jal done_waiting
	# if previously running task was removed from the list, select a new task
	check_if_running_is_empty:
		lw $t2, RUNNING
		bnez $t2, timer_int_is_done
		jal select_next_task
		jal load_next_task_registers
		#jal print_PCB_sequence
	timer_int_is_done:
			b int_end


### Support code for trap interrupts(teqi interrupts)
# a1 = starting address, a2 = task priority
new_task_int:	
	lb $t0, CREATED_TASK_COUNTER
	# if PCB_BLOCKS is full
	bge $t0, 10, done
	bnez $a2, high_priority
	low_priority:
		lw $t0, READY_LOW
		beqz $t0, empty_low
		# if READY_LOW is NOT empty
		non_empty_low:
			lw $t0, LAST_READY_LOW
			lw $t1, AVAILABLE
			sw $t1, NEXT_PCB($t0) # last_ready_low -> next = available
		
			lw $t0, LAST_READY_LOW
			lw $t1, NEXT_PCB($t0)
			sw $t1, LAST_READY_LOW # LAST_READY_LOW = LAST_READY_LOW -> next
		
			lw $t0, LAST_READY_LOW
			sw $zero, NEXT_PCB($t0) # LAST_READY_LOW -> next = null
			b increment_counter
		# if READY_LOW is empty
		empty_low:
			lw $t0, AVAILABLE
			sw $t0, READY_LOW # ready_low = available
			lw $t0, READY_LOW
			sw $t0, LAST_READY_LOW
			lw $t0, LAST_READY_LOW
			sw $zero, NEXT_PCB($t0)
			b increment_counter
	high_priority:
		lw $t0, READY_HIGH
		beqz $t0, empty_high
		# if READY_HIGH is NOT empty
		non_empty_high:
			lw $t0, LAST_READY_HIGH
			lw $t1, AVAILABLE
			sw $t1, NEXT_PCB($t0) # last_ready_high->next = available
		
			lw $t0, LAST_READY_HIGH
			lw $t1, NEXT_PCB($t0)
			sw $t1, LAST_READY_HIGH
		
			lw $t0, LAST_READY_HIGH
			sw $zero, NEXT_PCB($t0) # LAST_READY_HIGH -> next = null
			b increment_counter
		# if READY_HIGH is empty
		empty_high:
			lw $t0, AVAILABLE
			sw $t0, READY_HIGH # ready_high = available
			lw $t0, READY_HIGH
			sw $t0, LAST_READY_HIGH
			lw $t0, LAST_READY_HIGH
			sw $zero, NEXT_PCB($t0)
			#b increment_counter
	# increments task counter and updates the AVAILABLE pointer
	increment_counter:
		lb $t0, CREATED_TASK_COUNTER
		addi $t0, $t0, 1
		sb $t0, CREATED_TASK_COUNTER # CREATED_TASK_COUNTER += 1
		
		lw $t0, AVAILABLE
		addi $t0, $t0, PCB_SIZE
		sw $t0, AVAILABLE # AVAILABLE += PCB_SIZE
	# stores the new task's PROCESS_ID and starting epc value, but also stores its TICKS_TO_SWITCH, TICKS_TO_WAIT
	# and PRIORITY values
	store_pid_epc:
		bnez $a2, store_high
		store_low:
			lw $t0, LAST_READY_LOW
			lb $t1, CREATED_TASK_COUNTER
			#addi $t1, $t1, -1
			sb $t1, PROCESS_ID($t0) # stores the new process id on the correspondent PCB
			sw $a1, epc($t0) # new task's starting address(epc)
			li $t1, 1
			sw $t1, TICKS_TO_SWITCH($t0) # TICKS_TO_SWITCH = 3
			sw $zero, TICKS_TO_WAIT($t0) # TICKS_TO_WAIT = 0
			sw $a2, PRIORITY($t0) # priority = a2
			b done
		store_high:
			lw $t0, LAST_READY_HIGH
			lb $t1, CREATED_TASK_COUNTER
			#addi $t1, $t1, -1
			sb $t1, PROCESS_ID($t0) # stores the new process id on the correspondent PCB
			sw $a1, epc($t0) # new task's starting address(epc)
			li $t1, 3
			sw $t1, TICKS_TO_SWITCH($t0) # TICKS_TO_SWITCH = 3
			sw $zero, TICKS_TO_WAIT($t0) # TICKS_TO_WAIT = 0
			sw $a2, PRIORITY($t0) # priority = a2
			
	# after creating the task and updating all necessary pointers and values, print a success message
	done:
		#mfc0 $t0, $14
		#addi $t0, $t0, 4
		#mtc0 $t0, $14
		la $a0, new_task_str
		print_string
		b done_trap_int

# t0 = current node, t1 = next node
sleep_task_int:
	jal print_PCB_sequence
	#mfc0 $t0, $14
	#addi $t0, $t0, 4
	#mtc0 $t0, $14
	# before making the task go to sleep, save its registers
	jal save_running_task_registers
	lw $t0, WAITING
	go_to_wait:
		bnez $t0, not_empty_list
		# empty waiting list, just insert the running task
		empty_waiting_list:
			li $a0, 'g'
			print_char
			lw $t0, RUNNING
			sw $t0, WAITING
			sw $a1, TICKS_TO_WAIT($t0)
			sw $zero, NEXT_PCB($t0)
			b done_sleep
		# if WAITING list is NOT empty
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
			# insert the task on index 0
			insert_first:
				lw $t2, RUNNING
				sw $a1, TICKS_TO_WAIT($t2)
				sw $t0, NEXT_PCB($t2)
				sw $t2, WAITING
				b done_sleep
		# if WAITING list has more than 1 element
		not_last_element:
			lw $t2, TICKS_TO_WAIT($t0)
			bge $a1, $t2, bigger_than_current
			## insert before current node
			lw $t3, RUNNING
			sw $a1, TICKS_TO_WAIT($t3)
			sw $t0, NEXT_PCB($t3)
			sw $t3, WAITING
			b done_sleep
			##
			# if TICKS_TO_WAIT is bigger than current node
			bigger_than_current:
				lw $t2, TICKS_TO_WAIT($t1) # next node's TICKS_TO_WAIT
				bgt $a1, $t2, next_iteration
				## insert between current node and next node
				lw $t3, RUNNING
				sw $a1, TICKS_TO_WAIT($t3)
				sw $t1, NEXT_PCB($t3)
				sw $t3, NEXT_PCB($t0)
				##
				b done_sleep
			# if TICKS_TO_WAIT is bigger than next_node
			next_iteration:
				move $t0, $t1
				b not_empty_list
	# after inserting th task in the WAITING list	
	done_sleep:
		sw $zero, RUNNING	
		jal print_PCB_sequence
		jal select_next_task
		jal load_next_task_registers
		b done_trap_int
### end of support code for trap interrupts

### Support code for timer interrupts
# increments interrupt counter, and decrements TICKS_TO_SWITCH and TICKS_TO_WAIT when counter reaches 4
handle_ticks:	
	lw $t3, INT_COUNTER
	lw $t4, N_INT
	#beq $t3, $t4, decrement_ticks
	bge $t3, $t4, decrement_ticks
	inc_counter:
		lw $t3, INT_COUNTER
		addi $t3, $t3, 1
		sw $t3, INT_COUNTER
		b done_handling_ticks
	decrement_ticks:
		sw $zero, INT_COUNTER
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal decrement_ticks_to_wait
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		lw $t2, RUNNING
		lw $t3, TICKS_TO_SWITCH($t2)
		addi $t3, $t3, -1
		sw $t3, TICKS_TO_SWITCH($t2)
	done_handling_ticks:
		jr $ra

# selects next ready task from the READY_HIGH, READY_LOW and IDLE lists, according to the rules defined by the professor
select_next_task:
	#addi $sp, $sp, -4
	#sw $ra, 0($sp)
	#jal print_PCB_sequence
	#lw $ra, 0($sp)
	#addi $sp, $sp, 4
	
	
	lw $t0, READY_HIGH
	beqz $t0, no_tasks_in_high
	## if there are tasks in high priority ready list...
	lw $t1, NEXT_PCB($t0)
	li $t3, 3
	sw $t3, TICKS_TO_SWITCH($t0)
	sw $zero, NEXT_PCB($t0)
	sw $t0, RUNNING
	sw $t1, READY_HIGH
	## 
	b exit_selector	
	no_tasks_in_high:
		lw $t0, READY_LOW
		beqz $t0, no_tasks_in_low
		## if there are tasks in low priority ready list...
		lw $t1, NEXT_PCB($t0)
		li $t3, 3
		sw $t3, TICKS_TO_SWITCH($t0)
		sw $zero, NEXT_PCB($t0)
		sw $t0, RUNNING
		sw $t1, READY_LOW
		## 
		b exit_selector
	no_tasks_in_low:
		la $a0, sel_idle_str
		print_string
		lw $t0, IDLE_TASK
		sw $t0, RUNNING
	exit_selector:
		jr $ra

# decrement TICKS_TO_WAIT from all tasks in the WAITING list
decrement_ticks_to_wait:
	lw $t0, WAITING
	beqz $t0, no_tasks_waiting
	decrement_loop:
		lb $t1, TICKS_TO_WAIT($t0)
		addi $t1, $t1, -1
		sb $t1, TICKS_TO_WAIT($t0)
		#sw $t0, NEXT_PCB($t0)
		lw $t0, NEXT_PCB($t0)
		bnez $t0, decrement_loop
	no_tasks_waiting:
		jr $ra
# remove all tasks from WAITING list whose TICKS_TO_WAIT field has reached 0
done_waiting:
	remove_loop:
		lw $t0, WAITING
		beqz $t0, is_not_zero
		lw $t1, TICKS_TO_WAIT($t0)
		bnez $t1, is_not_zero
	is_zero:
		lw $t2, PRIORITY($t0)
		beqz $t2, low_list
		high_list:
			#####
			lw $t1, READY_HIGH
			beqz $t1, high_empty
			#####
			lw $t1, LAST_READY_HIGH
			sw $t0, NEXT_PCB($t1) # LAST_READY_HIGH -> next = WAITING
			lw $t2, NEXT_PCB($t0) # t2 = WAITING -> next
			sw $t2, WAITING	      # WAITING = WAITING -> next
			sw $zero, NEXT_PCB($t0) # WAITING -> next = NULL
			b remove_loop
			#####
			high_empty:
				sw $t0, READY_HIGH
				lw $t0, READY_HIGH
				
				lw $t2, NEXT_PCB($t0) # t2 = WAITING -> next
				beqz $t2, waiting_empty
				waiting_not_empty:
					sw $t2, WAITING	      # WAITING = WAITING -> next
					#sw $zero, NEXT_PCB($t0) # WAITING -> next = NULL
					b after_that
				waiting_empty:
					sw $zero, WAITING
				after_that:
					lw $t0, READY_HIGH
					sw $t0, LAST_READY_HIGH # READY_HIGH = LAST_READY_HIGH
					b remove_loop
			#####
		low_list:
			lw $t1, LAST_READY_LOW
			sw $t0, NEXT_PCB($t1)
			lw $t2, NEXT_PCB($t0)
			sw $t2, WAITING
			sw $zero, NEXT_PCB($t0)
			b remove_loop
	is_not_zero:
		jr $ra

# remove task from RUNNING list and stores it in the respective priority READY list
switch_running:
		la $a0, test_str
		print_string
		
		lw $t2, RUNNING
		lw $t3, PROCESS_ID($t2)
		beqz $t3, switch_idle
		lw $t2, PRIORITY($t2)
		beqz $t2, to_low_list
		to_high_list:
			lw $t3, READY_HIGH
			beqz $t3, empty_high_list
			lw $t2, RUNNING
			lw $t3, LAST_READY_HIGH
			sw $t2, NEXT_PCB($t3) # LAST_READY_HIGH -> next = RUNNING
			#####
			sw $t2, LAST_READY_HIGH # LAST_READY_HIGH = RUNNING
			#####
			b done_switching
			empty_high_list:
				lw $t2, RUNNING
				sw $t2, READY_HIGH
				#sw $t2, LAST_READY_HIGH
				b done_switching
		to_low_list:
			lw $t3, READY_LOW
			beqz $t3, empty_low_list
			lw $t2, RUNNING
			lw $t3, LAST_READY_LOW
			sw $t2, NEXT_PCB($t3) # LAST_READY_LOW -> next = RUNNING
			#####
			sw $t2, LAST_READY_LOW # LAST_READY_LOW = RUNNING
			#####
			#b done_switching	
			empty_low_list:
				lw $t2, RUNNING
				sw $t2, READY_LOW
				b done_switching
		switch_idle:
			lw $t2, RUNNING
			sw $t2, IDLE_TASK
		done_switching:
			sw $zero, RUNNING
			jr $ra
### End of support code for timer interrupts

# end of interrupt service routine
int_end:
	lw $v0 , save_v0
	lw $k0 , save_at
	lw $a0, save_a0
	move $at , $k0
	mtc0 $zero , $13
	mfc0 $k0 , $12
	andi $k0 , 0xfffd
	ori $k0 , 0x0001
	mtc0 $k0 , $12
	eret
	
	
# saves the running task register
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
	#sw $ra, ra($t0)

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

# after loading the new task, loads its registers
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

# prints the PROCESS_ID's values from all the tasks in all the lists
print_PCB_sequence:
	#li $a0, '\n'
	#print_char
	print_new_line

	la $a0, RUNNING_str
	print_string
	
	#lw $a0, RUNNING
	#beqz $a0, skip_running
	
	la $a0, next_str
	print_string
	
	lw $a0, RUNNING
	beqz $a0, skip_running
	lw $a0, PROCESS_ID($a0)
	print_int
	
	skip_running:
	#li $a0, '\n'
	#print_char
	print_new_line
	
	la $a0, READY_HIGH_str
	print_string
	
	lw $t0, READY_HIGH
	ready_high:
		beqz $t0, no_tasks_high
		la $a0, next_str
		print_string
		lw $t1, PROCESS_ID($t0)
		move $a0, $t1
		print_int
		lw $t0, NEXT_PCB($t0)
		b ready_high
	no_tasks_high:
		#print_new_line
		#la $a0, LAST_READY_HIGH_str
		#print_string
		#la $a0, next_str
		#print_string
		#lw $t0, LAST_READY_HIGH
		#lw $t1, PROCESS_ID($t0)
		#move $a0, $t1
		#print_int
		#####
		#la $a0, next_str
		#print_string
		#lw $t0, NEXT_PCB($t0)
		#lw $t1, PROCESS_ID($t0)
		#move $a0, $t1
		#print_int
		#####
			
		print_new_line
		la $a0, READY_LOW_str
		print_string
		lw $t0, READY_LOW
	ready_low:
		beqz $t0, no_tasks_low
		la $a0, next_str
		print_string
		lw $t1, PROCESS_ID($t0)
		move $a0, $t1
		print_int
		lw $t0, NEXT_PCB($t0)
		b ready_low
	no_tasks_low:
		print_new_line
	print_idle_task:
		la $a0, IDLE_str
		print_string
		print_space
		print_space
		print_space
		la $a0, next_str
		print_string
		lw $t0, IDLE_TASK
		lw $a0, PROCESS_ID($t0)
		print_int
		
		print_new_line
		la $a0, WAITING_str
		print_string
		lw $t0, WAITING
	waiting:
		beqz $t0, no_more_waiting
		la $a0, next_str
		print_string
		
		lw $t1, PROCESS_ID($t0)
		move $a0, $t1
		print_int
		
		lw $t0, NEXT_PCB($t0)
	#	b waiting
	no_more_waiting:
		jr $ra
