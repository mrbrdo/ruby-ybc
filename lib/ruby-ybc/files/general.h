#include <ruby.h>

#define RB_ENTER(stack_reserve, local_size) \
  VALUE sp[stack_reserve];\
  int rsp = 0;\
	stack_cache_top->size = local_size*8;
//#define PTR_CAST_DEREF(ptr, cast) *(cast *)((uintptr_t)(ptr))
//#define PTR_MCAST_DEREF(ptr, math, cast) *(cast *)((uintptr_t)(ptr)math)
//#define RB_STACK_DEREF(math) PTR_MCAST_DEREF(sp, +math, VALUE)
//#define GET_SP(var) asm("movq %%rsp, %0":"=m"(var))
//#define GET_BP(var) asm("movq %%rbp, %0":"=m"(var))
#define RB_LEAVE(stack_top) \
	return stack_top;

//#define RB_GET_SP(var, sp) asm("leaq -" #sp "(%%rbp), %0":"=r"(var))

typedef struct rb_stack_struct {
	uint8_t alive;
	uintptr_t bp;
	uintptr_t size;
} rb_stack_t;

extern rb_stack_t *stack_cache;
extern rb_stack_t *stack_cache_top;
extern rb_stack_t *current_stack;

void stack_created() __attribute__((naked));
void stack_destroying() __attribute__((naked));//((always_inline));


#pragma pack(push)
#pragma pack(1)
typedef struct fool_abi_struct {
	char a;
	short b;
	char c;
} fool_abi_t;
#pragma pack(pop)
typedef union nonabi_union {
	fool_abi_t nabi;
	VALUE d;
} nabi_t;

#define NONABI_PUSH(val) asm("pushq %0"::"r"((long long)val))
#define NONABI_CALL(func, n_params, result) \
	asm("call _" #func ";"\
			"addq $" #n_params "*8, %%rsp;"\
			"mov %%rax, %0":"=m"(result)::"rax","rsp")
#define NONABI_CALL_ODD(func, n_params) asm("subq $8, %rsp; call _" #func "; addq $" #n_params "*8+8, %rsp")


// ABI:
// arg1: rdi
// arg2: rsi
// arg3: rdx
// arg4: rcx
// arg5: r8d
// arg6: r9d
// arg7: [rsp]
// arg8: [rsp+8]
// arg9: [rsp+16]
// ...

extern VALUE rb_cNativeProc;
VALUE rb_new_native_proc(VALUE(*func)(ANYARGS), int argc, uintptr_t locals_ptr, int size);

VALUE yarv_opt_plus(VALUE a, VALUE b);
VALUE yarv_opt_minus(VALUE a, VALUE b);
