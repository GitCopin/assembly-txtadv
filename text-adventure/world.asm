world_array:	times 100 db 0
world_struct:	db 0
	
	;; ////////////////////////////////////////////////
	;;
	;; Define single-line macro for obj_struct_offset
	%define OSO(x) obj_struct_offset. %+ x
	;; object_array offset macro
	%define OAO obj_array.offset

	%macro BUILD_WORLD_PLAYER_POS 2
	mov [player_struct.pos_x],dword %1	;pos_x
	mov [player_struct.pos_y],dword %2	;pos_y
	%endmacro

	%macro BUILD_WORLD_OBJ_POS 3
	mov [%1+OSO(pos_x)],dword %2	;pos_x
	mov [%1+OSO(pos_y)],dword %3	;pos_y
	%endmacro

	;; SET_WORLD_OBJ_SIZE rdi,2,1,8,900
	%macro BUILD_WORLD_OBJ_SIZE 5
	mov [%1+OSO(width)],dword %2	;width
	mov [%1+OSO(depth)],dword %3	;depth
	mov [%1+OSO(height)],dword %4	;height
	mov [%1+OSO(weight)],dword %5	;weight
	%endmacro

	;; SET_WORLD_OBJ_TEXT rdi,obj_strings.boulder_short
	%macro BUILD_WORLD_OBJ_TEXT 2
	push rsi
	mov qword [%1+OSO(obj_string_ptr)],%2 		;obj_string_ptr
	xor rsi,rsi
	mov sil, byte %2_len 				;get value at memory pos
	mov [%1+OSO(obj_string_len)],byte sil		;obj_string_len
	pop rsi
	%endmacro

	%macro BUILD_WORLD_OBJ_PARENT 2
	mov [%1+OSO(parent)],dword %2	;parent
	%endmacro
	
	%macro INC_WORLD_OBJ_INDEX 1
	add %1,OSO(next)
	push rax
	xor rax,rax
	mov eax,dword [obj_array.offset]
	add eax,OSO(next)
	mov dword [obj_array.offset],eax
	pop rax
	%endmacro

	;; //////////////////////////////////
	;; BUILD_WORLD_INIT rdi
	;; set register to obj_array location
	%macro BUILD_WORLD_INIT 1
	xor %1,%1
	mov %1,obj_array
	%endmacro
	;; //////////////////////////////////
	;; BUILD_WORLD_OBJ rdi,pos_x,dword eax
	%macro BUILD_WORLD_OBJ 3
	mov [%1+OSO(%2)],%3
	%endmacro

	;; Setup offsets. Beginnig of each item from start.
obj_struct_offset:
	%assign offset 0		;start
	.type: equ offset	    
	%assign offset offset+_byte	;size of type
	.pos_x: equ offset		
	%assign offset offset+_dword	;size of pos_x
	.pos_y: equ offset		
	%assign offset offset+_dword	;size of pos_y
	.pos_z: equ offset	
	%assign offset offset+_dword	;size of pos_z
	;; position struct [dword x,dword y,dword z]
	.position.x: equ offset
	%assign offset offset+_dword	;size of position.x
	.position.y: equ offset
	%assign offset offset+_dword	;size of position.y
	.position.z: equ offset
	
	%assign offset offset+_dword	;size of position.z
	.width: equ offset		
	%assign offset offset+_dword	;size of width
	.depth: equ offset		
	%assign offset offset+_dword	;size of depth
	.height: equ offset		
	%assign offset offset+_dword	;size of height
	.obj_string_ptr: equ offset	
	%assign offset offset+_qword	;size of obj_string_ptr
	.obj_string_len: equ offset	
	%assign offset offset+_byte	;size of obj_string_len
	.weight: equ offset		
	%assign offset offset+_dword	;size of weight
	.distance: equ offset		
	%assign offset offset+_dword	;size of distance
	.parent: equ offset		
	%assign offset offset+_dword	;size of parent
	.visible_to_player: equ offset	
	%assign offset offset+_byte	;size of visible_to_player
	.pos_to_player: equ offset	
	%assign offset offset+_byte	;size of pos_to_player
	.x_rel_to_player: equ offset	
	%assign offset offset+_dword	;size of x_rel_to_player
	.y_rel_to_player: equ offset	
	%assign offset offset+_dword	;size of y_rel_to_player
	.state: equ offset
	%assign offset offset+_qword
	.state_trig_data: equ offset
	%assign offset offset+1000 	;size of state_trig_data
	.state_trig_data_offset: equ offset
	%assign offset offset+_dword
	.next: equ offset
	;; //////////////////////////////////////////////////////// 

	;; ////////////////////////////////////////////////
	;; when trigger is activated, modify state of current 
	;; or other object. open doors, activate devices, etc.
	%define SDS(x) state_trig_data_struct. %+ x
	
state_trig_data_struct:
	%assign offset 0
	.trigger_str: equ offset 		;input string that will trigger this state
	%assign offset offset+_qword

	;; mask to use to test if trigger is valid.
	;; is object in front of player 
	;; or is object in the hand of the player etc.
	.trigger_enable_mask: equ offset
	%assign offset offset+_qword

	.state_str: equ offset			;print string when state trigger is activated
	%assign offset offset+_qword

	.state_str_len: equ offset
	%assign offset offset+_dword

	.state_id: equ offset			;id of state
	%assign offset offset+_byte

	.state_enable: equ offset
	%assign offset offset+_qword

	.state_action: equ offset 		;what action to perform when state is triggered.
	%assign offset offset+_dword

	.next: equ offset
	;; //////////////////////////////////

	%macro SET_WORLD_OBJ_TRIG_QW 2
	push rdi
	xor rdi,rdi
	mov edi,dword [OAO]		;get offset in object_array.offset.
	mov qword [obj_array+edi+OSO(state_trig_data)+SDS(%1)],%2
	pop rdi
	%endmacro

	;; ////////////////////////////////////
	;; set obj trigger index by number
	%macro SET_WORLD_OBJ_TRIG_INDEX 1
	push rax				;preserve rax, rdx
	push rdx

	xor rax,rax
	xor rdx,rdx
	mov eax,state_trig_data_struct.next 	;move struct size to eax
	mov rdx,%1			 	;mov index num to rdx
	mul rdx

	;; mov result into obj_array.offset + obj_struct_offset.state_trig_data_offset
	mov dword [obj_array.offset+OSO(state_trig_data_offset)],eax 
	
	pop rdx
	pop rax
	%endmacro
	;; /////////////////////////////////////
	
	%macro GET_WORLD_OBJ_TRIG_QW 1
	push rdi
	xor rdi,rdi
	xor rax,rax
	movsx rdi,dword [obj_array.offset]
	mov rax,qword [obj_array+edi+OSO(state_trig_data)+SDS(%1)]
	pop rdi	
	%endmacro
	
	;; //////////////////////////////////////////////////////
	;; returns obj_array item from obj_array.offset into rax.
	%macro GET_WORLD_OBJ_PROP_B 1
	push rdi
	xor rdi,rdi
	xor rax,rax
	movsx rdi,dword [obj_array.offset]
	movsx rax,byte [obj_array+edi+OSO(%1)]
	pop rdi
	%endmacro

	%macro GET_WORLD_OBJ_PROP_DW 1
	push rdi
	xor rdi,rdi
	xor rax,rax
	movsxd rdi,dword [obj_array.offset]
	movsxd rax,dword [obj_array+edi+OSO(%1)]
	pop rdi
	%endmacro

	%macro GET_WORLD_OBJ_PROP_DW 2
	push rdi
	xor rdi,rdi
	xor rax,rax
	movsxd rdi,dword [obj_array.offset]
	movsxd rax,dword [obj_array+edi+OSO(%1)]
	pop rdi
	%endmacro

	%macro GET_WORLD_OBJ_PROP_QW 1
	push rdi
	xor rdi,rdi
	xor rax,rax
	movsxd rdi,dword [obj_array.offset]
	mov rax,[obj_array+edi+OSO(%1)]
	pop rdi
	%endmacro

	;; //////////////////////////////////////////////////////
	
	;; //////////////////////////////////////////////////////
	;; Set a parameter of an item in obj_array current index.
	;; set_world_obj pos_x,dword 8
	%macro SET_WORLD_OBJ_PROP 2
	push rdi
	xor rdi,rdi
	mov edi,dword [OAO]			;get offset in object_array.offset.
	mov [obj_array+edi+OSO(%1)],%2
	pop rdi
	%endmacro
	;; ////////////////////////////////
	
	%define SWO.nvis byte 0
	%define SWO.vis byte 1

	;; ////////////////////////////////////
	;; set obj_array_offset by index number
	%macro SET_WORLD_OBJ_INDEX 1
	push rax				;preserve rax, rdx
	push rdx

	xor rax,rax
	xor rdx,rdx
	mov eax,obj_struct_offset.next 		;move struct size to eax
	mov rdx,%1				;mov index num to rdx
	mul rdx

	mov dword [obj_array.offset],eax 	;mov result into obj_array.offset
	
	pop rdx
	pop rax
	%endmacro
	;; /////////////////////////////////////

	%macro PRINT_WORLD_OBJ_STR 1
	xor rsi,rsi
	xor rdx,rdx
	GET_WORLD_OBJ_PROP_QW %1_ptr
	mov rsi,rax
	GET_WORLD_OBJ_PROP_B %1_len
	mov rdx,rax
	
	prints rsi,rdx				;print object description
	%endmacro
	
obj_array:	times 22000 db 0
	.offset: dd 0
	
obj_trigger_strings:
	.open: db "open",0
	.open_len: equ $ - .open
	.cut: db "cut",0
	.cut_len: equ $ - .cut
	
obj_strings:
	.boulder_short: db "a large boulder"
	.boulder_short_len: equ $ - .boulder_short
	.boulder_long: db "a large boulder about 2 feet wide and a couple feet taller than you."
	.boulder_long_len: equ $ - .boulder_long
	.bush_short: db "a bush"
	.bush_short_len: equ $ - .bush_short
	.bush_long: db "a medium sized bush about 3 feet around, 5 feet tall and dense with leaves."
	.bush_long_len: equ $ - .bush_long

	;; /////////////////////////////
	;; player properties
	%assign PLAYER.look_range 7

	;; ////////////////////////////////////////
	;; Set player property
	;; ----------------------------------------
	;; 
	;; Usage:
	;; set_player_prop {name},{size},{value}
	;; 
	;; Example:
	;; set_player_prop look_dir,byte,dir.north
	;; 
	%macro SET_PLAYER_PROP 3
	mov [player_struct.%1],%2 %3
	%endmacro
	;; ////////////////////////////////////////

	;; ////////////////////////////////////////
	;; Get player property
	;; ----------------------------------------
	;; 
	;; Usage:
	;; get_player_prop {prop_name} {prop_size}
	;; 
	;; Example:
	;; get_player_prop pos_x dword
	;;
	;; Return:
	;; value in rax
	%macro GET_PLAYER_PROP 2
	xor rax,rax
	movsx rax,%2 [player_struct.%1] ;mov signed extension
	%endmacro
	;; ////////////////////////////////////////

	;; if_player_prop look_dir,byte,dir.north,.look_north
	%macro IF_PLAYER_PROP 4
	push rax
	GET_PLAYER_PROP %1,%2
	cmp rax,%2 %3
	pop rax
	je %4
	%endmacro

	%macro SET_OBJ_TO_PLAYER_L_HAND 0
	push rdi
	xor rdi,rdi
	mov edi,dword [OAO]		;get offset in object_array.offset.
	;add rdi,obj_array
	mov dword [player_struct.obj_in_left_hand],edi

	pop rdi
	%endmacro

	%macro SET_OBJ_TO_PLAYER_R_HAND 1
	mov dword [player_struct.obj_in_right_hand],%1
	%endmacro

	%macro GET_OBJ_FOR_PLAYER_INTERACTION 0
	push rax
	xor rax,rax
	mov eax,dword [player_struct.obj_to_interact]
	mov dword [obj_array.offset],eax
	pop rax
	%endmacro
	
	%macro SET_OBJ_FOR_PLAYER_INTERACTION 0
	push rdi
	xor rdi,rdi
	mov edi,dword [OAO]		;get offset in object_array.offset.
	;add rdi,obj_array
	mov dword [player_struct.obj_to_interact],edi

	pop rdi
	%endmacro
	
	%define PLAYER player_struct
	
player_struct:
	.pos_x: dd 0
	.pos_y: dd 0
	.look_dir: db dir.north
	.walk_dir: db dir.north
	.obj_in_left_hand: dq 0
	.obj_in_right_hand: dq 0
	.obj_in_backpack: dq 0
	.obj_to_interact: dq 0
	;; /////////////////////////////

	;; list of offsets for objects 
	;; that are within distance and in front of player
obj_sort_view:	times 50 db 0
	;; list of offsets for objects sorted left to right
	;; in regards to the view of the player.
obj_sort_order_lr:	times 50 db 0 ;

	;; ////////////////////////////////////////
	;; Calculate distance:
	;; - Calc distance between player and object.
	;; - Uses 32bit registers.
	;; ----------------------------------------
	;; In:          X offset in EAX, Y offset in EBX
	;; Returns:     Distance in EAX
	;; Modifies:    RAX
	;; Calls:       distance_i2ef
	;; Example:     calc_distance eax,ebx
	%macro CALC_DISTANCE 2
	push rdi
	push rsi
	
	xor rdi,rdi
	xor rsi,rsi
	;movsxd rdi,%1		;mov with sign-extension. preserve sign from dword to qword with sign
	;movsxd rsi,%2		;rax = distance
	movsxd rdi,%1
	movsxd rsi,%2
	
	call distance_i2ef

	pop rsi
	pop rdi
	%endmacro
	;; /////////////////////////////////////
