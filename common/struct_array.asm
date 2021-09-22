	;; global functions
	global store_struct, read_struct, insert_array
	;; global variables
	
	;; external functions
	
	section .data

struct:
	db 5
	.start:
	db 4
	.name_ptr: dd 0
	db 1
	.name_len: db 0
	db 1
	.age: db 0
	db 1
	.height: db 0
	db 1
	.weight: db 0
	;; memory for 10 struct's
	;; width of struct
	;; len of first elem in struct
	;; first elem data
	;; len of second element
	;; second element data
	;; etc...
struct_array:
	db 14			;len of each struct
	.start:
	times 120 db 0
struct_array_len:	db 4,1,1,1,1,0
	
	section .text
store_struct:

	mov rax,struct_array.start
	add rax,rdi		;initial offset
	mov byte [rax],5	;number of elements in struct
	inc rax

	mov byte [rax],4	;width of first element, etc...
	inc rax
	mov dword [rax],2121212121 ;element 1 data
	add rax,4

	mov byte [rax],1
	inc rax
	mov byte [rax],123
	add rax,1

	mov byte [rax],1
	inc rax
	mov byte [rax],122
	add rax,1

	mov byte [rax],1
	inc rax
	mov byte [rax],121
	add rax,1

	mov byte [rax],1
	add rax,1
	mov byte [rax],120
	add rax,1
	
	ret


read_struct:

	inc rsi			;make input rsi 0-based indexing
	
	xor r8,r8		;struct width counter
	xor r9,r9
	xor r10,r10		;width of next index
	xor rcx,rcx		;struct_array position
	xor rax,rax
	
	mov rcx,struct_array
	mov al, byte [rcx]     ;get width of structs in array
	;add rcx,13		;initial offset
	;mov r8b,byte [rcx]	;width of struct 4+1+1+1+1=8

	;mov rax,struct
	;mov al,byte [rax]
	mul rdi			;input: index in struct_array
	add rcx,rax
	;dec rcx			;decrement struct width for 0-based indexing

	inc rcx			;increment since first byte of struct array is struct width
	inc rcx			;increment to beginning of struct
	mov r8,rax
	
	.next_indx:
	xor rax,rax
	
	mov r10b,byte [rcx]	;len of following element

	cmp r10,1
	je .read_byte

	cmp r10,2
	je .read_word

	cmp r10,4
	je .read_dword

	jmp .cont

	.read_byte:
	add rcx,1
	mov al,byte [rcx]
	add rcx,1
	sub r8,1
	jmp .cont

	.read_word:
	add rcx,1
	mov ax,word [rcx]
	add rcx,2
	sub r8,2
	jmp .cont

	.read_dword:
	add rcx,1
	mov eax,dword [rcx]
	add rcx,4
	sub r8,4
	jmp .cont

	.cont:

	dec rsi
	cmp rsi,0
	je .done
	
	cmp r8,0
	jne .next_indx

	xor rax,rax		;return 0 if index(rsi) is out of range
	
	.done:
	ret
	
insert_array:

	;; calc offset from index
	xor rax,rax
	mov rax,8
	mul rdi

	add rax,struct_array
	mov rsi,struct_array_len
	
	.inc:

	cmp byte [rsi],1
	je .set_byte

	cmp byte [rsi],2
	je .set_word

	cmp byte [rsi],4
	je .set_dword

	cmp byte [rsi],8
	je .set_qword
	
	.continue:
	inc rsi
	cmp byte [rsi],0
	jne .inc
	jmp .done
	
	.set_byte:
	mov [rax],byte 123
	add rax,1
	jmp .continue

	.set_word:
	mov [rax],word 89
	add rax,2
	jmp .continue

	.set_dword:
	mov [rax],dword 4567
	add rax,4
	jmp .continue

	.set_qword:
	mov [rax],dword 987654321
	add rax,8
	jmp .continue
				;mov dword [struct_array + rax],12345 ;name_ptr
	;mov byte [struct_array + struct.name_len - struct + rax],67 ;name_len
	;mov byte [struct_array + struct.age - struct + rax],89	    ;age
	;mov byte [struct_array + struct.height - struct + rax],87   ;height
	;mov byte [struct_array + struct.weight - struct + rax],65   ;weight
	.done:
	
	ret

get_struct:
	;; calc offset from index
	xor rax,rax
	mov rax,12
	mul rdi
	
	ret

