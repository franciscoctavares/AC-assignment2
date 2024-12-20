#.include "definitions.asm"

.data

prep_multi_str: .asciiz "Preparation done!\n"
start_multi_str: .asciiz "Multitask started\n"

STRING_main0: .asciiz "Starting main task...\n"
STRING_main1: .asciiz "Main Task - "

.text

.globl _main

_main:
# prepare the structures
	#jal prep_multi
	#la $a0, prep_multi_str
	#print_string
	
# create the 3 tasks, with a0 = starting adress of the task's code and a1 = task's priority
	#la $a0, task0
	#li $a1, 1
	#jal newtask
	
	#la $a0, task1
	#li $a1, 0
	#jal newtask

	#la $a0, task2
	#li $a1, 0
	#jal newtask
	
# startmulti() and continue to 
# the infinit loop of the main function
	jal start_multi
	
	la $a0, start_multi_str
	print_string
	
	infinit:
		li $s0, 0
		la $a0, STRING_main0
		print_string
		loop:
			la $a0, STRING_main1
			print_string
		
			move $a0, $s0
			print_int
			
			li $a0, ' '
			print_char
			
			li $a0, '\n'
			print_char
		
			addi $s0, $s0, 1
			#####
			li $a0, 1
			jal sleep
			#####
			b loop
# the support functions	
prep_multi:
	la $t0, PCB_BLOCKS
	
	sw $t0, RUNNING # running process now points to the main task's PCB
	lw $t0, RUNNING
	sw $zero, NEXT_PCB($t0) # RUNNING -> next = null
	
	la $t0, PCB_BLOCKS
	addi $t0, $t0, PCB_SIZE
	sw $t0, AVAILABLE # available = available -> next
	
	li $t1, 1
	sw $t1, CREATED_TASK_COUNTER # created tasks = 1
	
	li $t0, 1
	lw $t1, RUNNING
	sw $t0, PROCESS_ID($t1) # stores main task's process id in the PCB
	
	la $t0, PCB_BLOCKS
	li $t1, 3
	sw $t1, TICKS_TO_SWITCH($t0) # sets the TICKS_TO_SWITCH field to 3
	
	li $t1, 1
	sw $t1, PRIORITY($t0)
	
	sw $zero, READY_HIGH
	sw $zero, READY_LOW
	sw $zero, LAST_READY_HIGH
	sw $zero, LAST_READY_LOW
	sw $zero, WAITING
	
	la $t0, IDLE_TASK_PCB
	sw $t0, IDLE_TASK
	la $t1, idle_task
	sw $t1, epc($t0)
	
	#lw $t0, INT_COUNTER
	#sw $zero, 0($t0)
	
	jr $ra
	
newtask:
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	
	move $a2, $a1 # a2 = a1
	move $a1, $a0 # a1 = a0
	li $a0, 1 # "syscall" service code
	teqi $zero, 0
	
	lw $a2, 0($sp)
	addi $sp, $sp, 4
	jr $ra
    
# a0 = sleep time(ticks)
sleep:
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $a1, 4($sp)
	
	move $a1, $a0
	li $a0, 2 # "syscall" service code
	teqi $zero , 0
	
	lw $a1, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
start_multi:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal int_enable
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
#.include "interrupt.asm"
.include "t0.asm"
.include "t1.asm"
.include "t2.asm"
.include "idle_task.asm"

#.include "main1.asm"
