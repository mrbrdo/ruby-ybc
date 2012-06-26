- func_prologue:
typedef VALUE (*::func_name_fptr)(nabi_t self::args);
VALUE ::func_name_impl(nabi_t self::args) __attribute__((noinline));
VALUE ::func_name_impl(nabi_t self::args) {
  RB_ENTER(::stack_max, ::local_size);

- func_epilogue:
  RB_LEAVE(::ret);
}

- method_stub:
VALUE ::name(VALUE selfv::args)
{
  nabi_t self = (nabi_t) selfv;
  return ::call_str(nabi_t)self::casted_args);
}

- defineclass(0):
rb_define_class_under(::cbase, "::name", ::zuper)

- defineclass(3):
rb_define_class("::name", ::zuper)

- defineclass(1):
rb_singleton_class(::cbase)

- defineclass(2):
rb_define_module_under(::cbase, "::name")

- defineclass(5):
rb_define_module("::name")

- defineclass_full:
{
  VALUE tmp = ::klass;
  append_method_to_dispatch_table(tmp, "::name", (uintptr_t)::name_impl);
  ::name(tmp);
  YARV_PUTOBJECT(tmp, ::stack);
  rsp++;
}

- opt_plus:
yarv_opt_plus(::left, ::right)

- opt_minus:
yarv_opt_minus(::left, ::right)

- opt_lt:
((SIGNED_VALUE)::a < (SIGNED_VALUE)::b) ? Qtrue : Qfalse

- branchunless:
if (!RTEST(::cond)) goto ::lab;

- jump:
goto ::lab;

- setlocal:
YARV_SETLOCAL(::local, ::stack);

- getdynamic:
YARV_GETDYNAMIC(::idx, ::scope, ::stack);

- empty_placeholder
// for easier regexp