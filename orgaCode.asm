.model small
.stack 100h
.data
max_employees equ 10

msg_id  db 0dh, 0ah, 'Enter Employee ID: $'
msg_pw  db 0dh, 0ah, 'Enter Employee Password (Decimal Value): $'
msg_not_found db 0dh, 0ah, 'Employee ID does not exist!$', 0dh, 0ah
msg_wrong_pw db 0dh, 0ah, 'Access Denied.$', 0dh, 0ah
msg_access_allowed db 0dh, 0ah, 'Access Allowed$', 0dh, 0ah

employee_ids  dw 65, 148, 526, 2036, 1504, 82, 112, 2840, 940, 1292
employee_passwords  db 125, 84, 29, 37, 187, 219, 62, 75, 141, 243 
encrypted_passwords db 10 dup(0)

user_id  dw 0
user_password db 0

.code

print_byte proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 0
    mov cx, 2           

convert_loop:
    rol al, 4          
    mov bl, al
    and bl, 0Fh         
    cmp bl, 9
    ja add_7            

    add bl, '0'        
    jmp print_next

add_7:
    add bl, 'A' - 10    

print_next:
    mov dl, bl
    mov ah, 02h         
    int 21h            

    dec cx
    jnz convert_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_byte endp

encrypt_password proc
    mov ah, al         
    shr al, 7           
    shl ah, 1           
    or al, ah           
    test al, 10000001b  
    jz rotate_right    
    ret

rotate_right:
    ror al, 2          
    ret
encrypt_password endp

encrypt_passwords proc
    mov cx, max_employees    
    mov si, 0                

encrypt_loop:
    mov al, [employee_passwords + si]   
    call encrypt_password              
    mov [encrypted_passwords + si], al 

    inc si                              
    loop encrypt_loop                   

    ret
encrypt_passwords endp

validatelogin proc
    mov bx, 0             
    xor si, si

search_id:
    cmp ax, [employee_ids + si]  
    je found_id
    add si, 2
    inc bx
    cmp bx, max_employees
    jb search_id
    
    lea dx, msg_not_found
    mov ah, 09h
    int 21h
    ret

found_id:
    lea dx, msg_pw
    mov ah, 09h
    int 21h
    call readnpw

    mov al, user_password
    cmp al, [employee_passwords + bx]
    jne wrong_password

   
    mov al, user_password
    call encrypt_password
    mov [encrypted_passwords + bx], al

    lea dx, msg_access_allowed
    mov ah, 09h
    int 21h
    ret

wrong_password:
    lea dx, msg_wrong_pw
    mov ah, 09h
    int 21h
    ret
validatelogin endp

main proc
    mov ax, @data
    mov ds, ax
    mov ah, 09h
    call encrypt_passwords

try_again:
    lea dx, msg_id
    mov ah, 09h
    int 21h
    call readn
    mov user_id, ax
    call validatelogin
    jmp try_again
    mov ah, 4ch
    int 21h
main endp

readn proc near
    push bx
    push cx
    mov cx, 10
    mov bx, 0

readn1:
    mov ah, 01h      
    int 21h          
    cmp al, '0'
    jb readn2
    cmp al, '9'
    ja readn2

    sub al, '0'     
    push ax
    mov ax, bx
    mul cx          
    mov bx, ax
    pop ax
    mov ah, 0
    add bx, ax      
    jmp readn1      

readn2:
    mov ax, bx      
    pop cx
    pop bx
    ret
readn endp

readnpw proc near
    push bx
    push cx
    mov cx, 10
    mov bx, 0

readnpw1:
    mov ah, 08h      
    int 21h          
    cmp al, '0'
    jb readnpw2
    cmp al, '9'
    ja readnpw2

    sub al, '0'      
    push ax
    mov ax, bx
    mul cx          
    mov bx, ax
    pop ax
    mov ah, 0
    add bx, ax      
    jmp readnpw1      

readnpw2:
    mov user_password, bl
    pop cx
    pop bx
    ret
readnpw endp

end main