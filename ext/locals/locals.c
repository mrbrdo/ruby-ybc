#include <ruby/ruby.h>
#include "general.h"
#include "instr.h"

VALUE rb_cNativeProc;

VALUE rb_new_native_proc(VALUE(*func)(ANYARGS), int argc, uintptr_t locals_ptr, int size) {
	VALUE result = rb_funcall(rb_cNativeProc, rb_intern("new"), 0);
	rb_define_singleton_method(result, "call", func, argc);
	rb_iv_set(result, "@locals_ptr", LL2NUM(locals_ptr));
	rb_iv_set(result, "@locals_size", INT2NUM(size));
	return result;
}

VALUE run_block1_impl(nabi_t self) __attribute__((noinline));
VALUE run_block1_impl(nabi_t self) {
  RB_ENTER(2, 1);
  // YARV trace: 1
  // YARV putself
  YARV_GETDYNAMIC(1, 1, 0);
  // YARV getdynamic: 3, 1
  YARV_GETDYNAMIC(3, 1, 1);
  // YARV send: :puts, 1, nil, 8, 0
  asm(""::); // refresh vars
  YARV_SEND(1, 0, "puts", 1, sp[1]);
  asm("":); // refresh vars
  // YARV pop
  // YARV trace: 1
  // YARV putself
  YARV_GETDYNAMIC(1, 1, 0);
  // YARV getdynamic: 2, 1
  YARV_GETDYNAMIC(2, 1, 1);
  // YARV send: :puts, 1, nil, 8, 1
  asm(""::); // refresh vars
  YARV_SEND(1, 0, "puts", 1, sp[1]);
  asm("":); // refresh vars
  // YARV leave
  RB_LEAVE(0);
}

VALUE run_block1(VALUE self)
{
  return run_block1_impl((nabi_t)self);
}

VALUE run_impl(nabi_t self, nabi_t v2, nabi_t v3) __attribute__((noinline));
VALUE run_impl(nabi_t self, nabi_t v2, nabi_t v3) {
  RB_ENTER(2, 3);
  // YARV trace: 8
  // YARV trace: 1
  // YARV putobject: 5
  YARV_PUTOBJECT(INT2NUM(5), 0);
  // YARV setlocal: 3
  YARV_SETLOCAL(v3, 0);
  // YARV trace: 1
  // YARV putobject: 6
  YARV_PUTOBJECT(INT2NUM(6), 0);
  // YARV setlocal: 2
  YARV_SETLOCAL(v2, 0);
  // YARV trace: 1
  // YARV putself
  YARV_PUTSELF(0);
  // YARV custom_newproc: 0, Array
  // Compiled method "run_block1".
  YARV_PUTOBJECT(rb_new_native_proc(run_block1, 0, (uintptr_t) &self, 3), 1);
  // YARV send: :met, 1, nil, 8, 2
  asm(""::"m"(v2),"m"(v3)); // refresh vars
  YARV_SEND(1, 0, "met", 1, sp[1]);
  asm("":"=m"(v2),"=m"(v3)); // refresh vars
  // YARV trace: 16
  // YARV leave
  RB_LEAVE(0);
}

VALUE run(VALUE self)
{
  return run_impl((nabi_t)self, (nabi_t)(VALUE)(0), (nabi_t)(VALUE)(0));
}

VALUE met_impl(nabi_t self, nabi_t v2) __attribute__((noinline));
VALUE met_impl(nabi_t self, nabi_t v2) {
  RB_ENTER(1, 2);
  // YARV trace: 8
  // YARV trace: 1
  // YARV getlocal: 2
  YARV_GETLOCAL(v2, 0);
  // YARV send: :call, 0, nil, 0, 0
  asm(""::"m"(v2)); // refresh vars
  YARV_SEND(0, 0, "call", 0);
  asm("":"=m"(v2)); // refresh vars
  // YARV trace: 16
  // YARV leave
  RB_LEAVE(0);
}

VALUE met(VALUE self, VALUE arg1)
{
  return met_impl((nabi_t)self, (nabi_t)(arg1));
}

VALUE ProcBasicC_impl(nabi_t self) __attribute__((noinline));
VALUE ProcBasicC_impl(nabi_t self) {
  RB_ENTER(4, 1);
  // YARV trace: 2
  // YARV trace: 1
  // YARV putspecialobject: 1
  // YARV putself
  YARV_PUTSELF(0);
  // YARV putobject: :met
  YARV_PUTOBJECT(ID2SYM(rb_intern("met")), 1);
  // YARV putiseq: Array
  // YARV send: :"core#define_singleton_method", 3, nil, 0, 0
  // Compiled method :met.
rb_define_singleton_method(self.d, "met", met, 1);
  // YARV pop
  // YARV trace: 1
  // YARV putspecialobject: 1
  // YARV putself
  YARV_PUTSELF(0);
  // YARV putobject: :run
  YARV_PUTOBJECT(ID2SYM(rb_intern("run")), 1);
  // YARV putiseq: Array
  // YARV send: :"core#define_singleton_method", 3, nil, 0, 1
  // Compiled method :run.
rb_define_singleton_method(self.d, "run", run, 0);
  // YARV trace: 4
  // YARV leave
  RB_LEAVE(0);
}

VALUE ProcBasicC(VALUE self)
{
  return ProcBasicC_impl((nabi_t)self);
}

VALUE toplevel_function_impl(nabi_t self) __attribute__((noinline));
VALUE toplevel_function_impl(nabi_t self) {
  RB_ENTER(2, 1);
  // YARV trace: 1
  // YARV putspecialobject: 3
  // YARV putnil
  YARV_PUTOBJECT(Qnil, 0);
  // YARV defineclass: :ProcBasicC, Array, 5
  // Compiled method :ProcBasicC.
  ProcBasicC(rb_define_class("ProcBasicC", rb_cObject));
  // YARV leave
  RB_LEAVE(0);
}

VALUE toplevel_function(VALUE self)
{
  return toplevel_function_impl((nabi_t)self);
}


void Init_locals()
{
  VALUE toplevel_object = rb_eval_cmd(rb_str_new2("self"), Qnil, 0);
  stack_cache = malloc(100 * sizeof(struct rb_stack_struct));
  stack_cache_top = stack_cache;

  rb_cNativeProc = rb_define_class("NativeProc", rb_cObject);
  
  toplevel_function(toplevel_object);
}