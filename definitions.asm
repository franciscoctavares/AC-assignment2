# a0 = adress of string to be printed
.macro print_string
	li $v0, 4
	syscall
.end_macro

# a0 = integer to be printed
.macro print_int
	li $v0, 1
	syscall
.end_macro

# a0 = char to be printed
.macro print_char
	li $v0, 11
	syscall
.end_macro

# offset of addresses for accessing the PCB's
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
.eqv TICKS_TO_SWITCH 144
.eqv TICKS_TO_WAIT 148
.eqv PRIORITY 152

.eqv PCB_SIZE 156
.eqv STACK_SIZE 100

.data

PCB_BLOCKS: .space 1560 # 144 bytes x 10 Tasks
PCB_STACKS: .space 1000 # (4 bytes x 25 variables) x 10 PCB's

RUNNING: .word 0x00000000      # running task
READY: .word 0x00000000        # ready tasks list
LAST_READY: .word 0x00000000   # last ready task

READY_HIGH: .word 0x00000000   # high priority ready tasks list
READY_LOW: .word 0x00000000    # low priority ready tasks list
WAITING: .word 0x00000000      # waiting tasks list
IDLE_TASK: .word 0x00000000    # idle task

IDLE_TASK_PCB: .space PCB_SIZE # idle task's PCB

CREATED_TASK_COUNTER: .word 0x00000000
AVAILABLE: .word 0x00000000
