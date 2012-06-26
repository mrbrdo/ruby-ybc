#include <ruby.h>
extern VALUE dispatch_table;
extern uintptr_t *func_ptr_cache;
extern int func_ptr_cache_size;

#define RYBC_DEFINE_METHOD(on_klass, name, map_to_func, argc) \
  append_method_to_dispatch_table(on_klass, #name, (uintptr_t)map_to_func);\
  rb_define_method(on_klass, #name, name, argc)

// TODO define method on SINGLETON class (in dispatch_table!)
#define RYBC_DEFINE_SINGLETON_METHOD(on_obj, name, map_to_func, argc) \
  rb_define_singleton_method(on_obj, #name, name, argc);\
  append_method_to_dispatch_table(CLASS_OF(CLASS_OF(on_obj)), #name, (uintptr_t)map_to_func)

inline uintptr_t method_dispatch_ptr(VALUE, const char *, int);
void append_method_to_dispatch_table(VALUE klass, const char *name, uintptr_t func);
void clear_func_cache();
void InitMethods();