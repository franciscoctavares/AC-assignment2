.data

.eqv at 0
.eqv v0 4
.eqv v1 8
.eqv a0 12
.eqv a1 16
.eqv a2 20
.eqv a3 24
.eqv t0 28
.eqv t1 32
.eqv t2 36
.eqv t3 40
.eqv t4 44
.eqv t5 48
.eqv t6 52
.eqv t7 56
.eqv s0 60
.eqv s1 64
.eqv s2 68
.eqv s3 72
.eqv s4 76
.eqv s5 80
.eqv s6 84
.eqv s7 88
.eqv t8 92
.eqv t9 96
.eqv k0 100
.eqv k1 104
.eqv gp 108
.eqv sp 112
.eqv fp 116
.eqv ra 120
.eqv hi 124
.eqv lo 128
.eqv epc 132
.eqv PROCESS_ID 136
.eqv NEXT_PCB 140

STRING_done: .asciiz "Multitask started\n"
STRING_main0: .asciiz "Starting main task...\n"
STRING_main1: .asciiz "Main Task - "
test_string: .asciiz "Preparation done!\n"
empty_list_str: .asciiz "empty list!"
AVAILABLE_str: .asciiz "AVAILABLE: "
LAST_READY_str: .asciiz "LAST_READY: "

CREATED_TASK_COUNTER: .word 0x00000000
AVAILABLE: .word 0x00000000

.eqv PCB_SIZE 144
.eqv STACK_SIZE 100

.text

main:
# prepare the structures	
	jal prep_multi
	li $v0, 4
	la $a0, test_string
	syscall
		
	
# newtask (t0)
	la $a0, task0
	jal newtask
	#jal print_all_pointers
	
# newtask(t1)	
	la $a0, task1
	jal newtask
	#jal print_all_pointers

# newtask(t2)
	la $a0, task2
	jal newtask
	#jal print_all_pointers

# startmulti() and continue to 
# the infinit loop of the main function
	jal start_multi
	
	la $a0, STRING_done
	li $v0, 4
	syscall
	
infinit: 
	# Reapeatedly print a string
	li $t0, 0
	la $a0, STRING_main0
	li $v0, 4
	syscall
	loop:
		la $a0, STRING_main1
		li $v0, 4
		syscall
		
		move $a0, $t0
		li $v0, 1
		syscall
		
		li $v0, 11
		li $a0, '\n'
		syscall
		
		addi $t0, $t0, 1
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
	
	li $t0, 0
	lw $t1, RUNNING
	sw $t0, 136($t0) # stores main task's process id in the PCB
	
	jr $ra
	
newtask:	
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
		lw $t1, NEXT_PCB($t0) # LAST_READY -> next
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
	store_pid_epc:
		lw $t0, LAST_READY
		lb $t1, CREATED_TASK_COUNTER
		addi $t1, $t1, -1
		sb $t1, PROCESS_ID($t0) # stores the new process id on the correspondent PCB
		sw $a0, epc($t0) # new task's starting address(epc)
	done:
		jr $ra
    
start_multi:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal int_enable
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
.include "interrupt.asm"
.include "t0.asm"
.include "t1.asm"
.include "t2.asm"
