
// Stack frame:
// 0xff8:		
// 0xff0: 
// 0xfe8: 
// 0xfe0: local 2
// 0xfd8: local 1
// 0xfd0: param 2...
// 0xfc8: param 1
// 0xfc0: self
// 0xfb8: return address of caller
// 0xfb0: rbp base pointer of caller <-- [rbp]
// 0xfa8: stack cache pointer
// 0xfa0: 


#define MACROMATH(i,add,mul) i*mul+add
#define STACK_CACHE_PTR "-8(%%rbp)"
#define STACK_SELF_PTR "-16(%%rbp)"
#define STACK_PARAMS "24(%%rbp)"
#define STACK_LOCALS(n_params) "(" #n_params "*8+24)(%%rbp)"

// Helpers

//#define RB_LOCAL_PTR(idx) "-8-" #idx "*8(%%rbp)"
//#define RB_LOCAL(idx, dest) asm("mov " RB_LOCAL_PTR(idx) ", " #dest :)
//#define RB_LOCAL_SET_FROM(idx, val) asm("mov " #val ", " RB_LOCAL_PTR(idx) :)
//#define RB_LOCAL_SET(idx, val) asm("mov %0, " RB_LOCAL_PTR(idx) ::"r"((long long)val))

//#define RB_SET_CALL_ARG(idx, val) asm("mov %0, -8-8-8*" #idx "(%%rsp)" ::"r"((long long)val))